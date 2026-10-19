#!/bin/sh
# Build every APKBUILD for one architecture, then create and sign the
# repository index. Output lands in site/.
#
# Usage:
#   ABUILD_PRIVKEY=/path/to/tallica.rsa ./scripts/build.sh <x86_64|aarch64>
#   ./scripts/build.sh checksum
set -eu

ARCH="${1:-}"
case "$ARCH" in
	checksum)
		command -v docker >/dev/null 2>&1 || {
			echo "docker is required (abuild only runs on Alpine Linux)" >&2
			exit 1
		}
		exec docker run --rm -v "$PWD:/work" -w /work alpine:edge sh -euc '
			apk add --no-cache alpine-sdk
			mkdir -p /build/apkbuilds
			for d in /work/apkbuilds/*/; do
				pkg=$(basename "$d")
				mkdir -p "/build/apkbuilds/$pkg"
				for f in "$d"*; do
					case "$f" in
					*/src|*/pkg) continue ;;
					esac
					cp "$f" "/build/apkbuilds/$pkg/"
				done
			done
			for d in /build/apkbuilds/*/; do
				(cd "$d" && abuild -F checksum)
			done
			for d in /build/apkbuilds/*/; do
				pkg=$(basename "$d")
				cp "$d/APKBUILD" "/work/apkbuilds/$pkg/APKBUILD"
			done
		'
		;;
	x86_64) PLATFORM="linux/amd64" ;;
	aarch64) PLATFORM="linux/arm64" ;;
	*)
		echo "usage: $0 <x86_64|aarch64|checksum>" >&2
		exit 2
		;;
esac

KEY="${ABUILD_PRIVKEY:-$HOME/.abuild/tallica.rsa}"
PACKAGER="${PACKAGER:-Michał Lipski <michal@tallica.pl>}"
# Fixed timestamp so rebuilding an unchanged package version produces
# byte-identical APKs instead of overwriting them with different bytes.
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1767225600}"

[ -f "$KEY" ] || {
	echo "signing key not found: $KEY" >&2
	echo "run 'make key' first, or set ABUILD_PRIVKEY" >&2
	exit 1
}
[ -f "$KEY.pub" ] || {
	echo "public key not found: $KEY.pub" >&2
	exit 1
}

command -v docker >/dev/null 2>&1 || {
	echo "docker is required (abuild only runs on Alpine Linux)" >&2
	exit 1
}

mkdir -p site/keys
cp "$KEY.pub" site/keys/tallica.rsa.pub

docker run --rm --platform "$PLATFORM" \
	-v "$PWD:/src:ro" \
	-v "$KEY:/keys/tallica.rsa:ro" \
	-v "$KEY.pub:/keys/tallica.rsa.pub:ro" \
	-v "$PWD/site:/site" \
	-e PACKAGER="$PACKAGER" \
	-e SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
	alpine:edge sh -euc '
	apk add --no-cache alpine-sdk

	adduser -D builder
	addgroup builder abuild

	# Build from a copy so the bind-mounted source can stay read-only and
	# the non-root builder owns everything it writes.
	cp -a /src /build
	chown -R builder:builder /build

	mkdir -p /home/builder/.abuild /home/builder/packages
	cp /keys/tallica.rsa /keys/tallica.rsa.pub /home/builder/.abuild/
	chmod 600 /home/builder/.abuild/tallica.rsa
	# apk index verifies package signatures, so the public key must be
	# trusted in the container as well.
	mkdir -p /etc/apk/keys
	cp /keys/tallica.rsa.pub /etc/apk/keys/
	printf "PACKAGER=\"%s\"\nPACKAGER_PRIVKEY=\"%s\"\nREPODEST=\"%s\"\n" \
		"$PACKAGER" "/home/builder/.abuild/tallica.rsa" \
		"/home/builder/packages" \
		> /home/builder/.abuild/abuild.conf
	chown -R builder:builder /home/builder/.abuild /home/builder/packages

	su builder -c "
		set -e
		export SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
		for d in /build/apkbuilds/*/; do
			cd \"\$d\"
			pkgver=\$(sed -n 's/^pkgver=//p' APKBUILD)
			export ABUILD_LAST_COMMIT=\"v\$pkgver\"
			abuild -r
		done
	"

	arch=$(su builder -c "cd /build/apkbuilds/lazyincus && abuild -A")
	echo "Built packages for $arch"

	rm -rf "/site/edge/$arch"
	mkdir -p "/site/edge/$arch"
	find /home/builder/packages -name "*.apk" \
		-exec cp -v {} "/site/edge/$arch/" \;

	cd "/site/edge/$arch"
	apk index --no-warnings --quiet --rewrite-arch "$arch" \
		-o APKINDEX.tar.gz \
		--description "tallica edge $arch" ./*.apk
	abuild-sign -k /home/builder/.abuild/tallica.rsa APKINDEX.tar.gz
'

echo
echo "Repository ready: site/edge/$ARCH"
