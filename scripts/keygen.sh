#!/bin/sh
# Generate the APK signing key used for this repository.
#
# The private key is written to ~/.abuild/tallica.rsa and must never be
# committed. The public key is copied to keys/tallica.rsa.pub, which is
# committed and served at /keys/tallica.rsa.pub.
set -eu

KEY_DIR="${ABUILD_KEY_DIR:-$HOME/.abuild}"
KEY="$KEY_DIR/tallica.rsa"

command -v docker >/dev/null 2>&1 || {
	echo "docker is required (abuild only runs on Alpine Linux)" >&2
	exit 1
}

mkdir -p "$KEY_DIR" keys

if [ -e "$KEY" ] || [ -e "keys/tallica.rsa.pub" ]; then
	echo "refusing to overwrite an existing key:" >&2
	ls -l "$KEY" keys/tallica.rsa.pub 2>/dev/null >&2 || true
	exit 1
fi

docker run --rm -v "$KEY_DIR:/keys" alpine:edge sh -euc '
	apk add --no-cache openssl
	cd /keys
	openssl genrsa -out tallica.rsa 4096
	openssl rsa -in tallica.rsa -pubout -out tallica.rsa.pub
	chmod 600 tallica.rsa
	chmod 644 tallica.rsa.pub
'

cp "$KEY.pub" keys/tallica.rsa.pub

cat <<EOF

Generated:
  private key: $KEY      (back this up; never commit it)
  public key:  keys/tallica.rsa.pub

Next:
  1. Commit keys/tallica.rsa.pub.
  2. Add the private key to GitHub as the APK_SIGNING_KEY_B64 secret:
       base64 -i "$KEY" | tr -d '\\n' | pbcopy      # macOS
       base64 -w0 "$KEY"                            # Linux
EOF
