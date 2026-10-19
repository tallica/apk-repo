# tallica APK repository

A signed Alpine package repository, published from GitHub Pages.

Current packages:

| Package | Description |
| --- | --- |
| `lazyincus` | Terminal UI for Incus containers, VMs and images |
| `incus-compose` | Run Compose files on Incus containers and VMs |
| `sms2mqtt` | Bridge between a Huawei USB modem and Home Assistant via MQTT |

The packages repackage official upstream release binaries, the same approach as
the Homebrew tap.

## Install

Run as root, or prefix each command with `doas`/`sudo`.

Install the signing key once:

```sh
apk add ca-certificates
wget -O /etc/apk/keys/tallica.rsa.pub \
  https://tallica.github.io/apk-repo/keys/tallica.rsa.pub
```

Then choose one repository form. Keep only one `tallica` line in
`/etc/apk/repositories` (check with `grep tallica /etc/apk/repositories`).

### Untagged (recommended)

```sh
echo "https://tallica.github.io/apk-repo/edge" >> /etc/apk/repositories
apk update
apk add lazyincus incus-compose sms2mqtt
```

### Tagged (`@tallica`)

Use this if the packages may also come from Alpine's official repositories.
A tagged repository is masked from plain installs, so request it explicitly:

```sh
echo "@tallica https://tallica.github.io/apk-repo/edge" >> /etc/apk/repositories
apk update
apk add lazyincus@tallica incus-compose@tallica sms2mqtt@tallica
```

The tag is recorded in `/etc/apk/world`, so `apk upgrade` keeps using it.

Verify:

```sh
lazyincus --version
incus-compose version
```

The current packages provide `x86_64` and `aarch64` binaries. The same `edge`
tree serves both; `apk` selects the architecture automatically.

If `apk` reports `v2 package integrity error`, the local index is older than
the published packages. Run `apk update` and retry.

### sms2mqtt service

`sms2mqtt` includes an OpenRC service. Edit `/etc/conf.d/sms2mqtt`, then:

```sh
rc-update add sms2mqtt default
rc-service sms2mqtt start
```

## Layout

```text
apkbuilds/                  # one APKBUILD per package
keys/tallica.rsa.pub        # public signing key (committed)
scripts/keygen.sh           # one-time signing-key generation
scripts/build.sh            # build, checksum, and sign
Makefile                    # command interface (make help)
.claude/skills/             # package update procedure
.github/workflows/build.yml # x86_64 + aarch64 build and Pages deploy
site/                       # generated, not committed
```

Add a package by creating `apkbuilds/<pkgname>/APKBUILD`; `scripts/build.sh`
builds every directory under `apkbuilds/`.

## Maintainer setup

```sh
make key
git add keys/tallica.rsa.pub
git commit -m "chore: add apk signing public key"

gh repo create tallica/apk-repo --public --source=. --remote=origin
base64 -i ~/.abuild/tallica.rsa | tr -d '\n' \
  | gh secret set APK_SIGNING_KEY_B64 --repo tallica/apk-repo
git push -u origin master
```

Use `base64 -w0` instead of `base64 -i` on Linux. Back up the private key;
never commit it. In GitHub, set **Pages → Build and deployment → Source** to
**GitHub Actions**. The workflow builds `x86_64` on `ubuntu-latest` and
`aarch64` on `ubuntu-24.04-arm`; if the arm runner is unavailable, point its
matrix entry at `ubuntu-latest` to build under emulation. If the first run
reaches deploy before Pages is enabled, rerun the workflow.

If the repository name changes, update the URLs in this README.

## Build and test

`abuild` only runs on Alpine, so the scripts use an `alpine:edge` container.
No Go toolchain is needed: the APKBUILDs download the upstream release
archives and select the one matching the target architecture. Run `make help`
for all commands.

```sh
make build                  # native architecture
make build-x86_64
make build-aarch64
make serve                  # serve site/ on http://localhost:8000
```

Output is written to `site/`, which is gitignored. Test the repository in a
clean container:

```sh
docker run --rm -it -v "$PWD/site:/repo:ro" alpine:edge sh
# inside:
cp /repo/keys/tallica.rsa.pub /etc/apk/keys/
echo /repo/edge >> /etc/apk/repositories
apk update && apk add lazyincus incus-compose sms2mqtt
```

## Updating a package

Run the `update-apk-package` Claude Code skill (or `/update-apk-package`). It
bumps the APKBUILD, refreshes checksums, builds both architectures, updates
`CHANGELOG.md`, and commits. CI republishes after the push.

## Documentation

Maintenance conventions, packaging details, and key handling are in
[CLAUDE.md](CLAUDE.md). Change history is in [CHANGELOG.md](CHANGELOG.md).
