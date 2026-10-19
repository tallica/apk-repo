# tallica/apk-repo

A signed Alpine package repository published from GitHub Pages. It publishes
binary packages that repackage official upstream release binaries; it does not
build from source. Alpine's official aports repository rejects prebuilt
packages, so an aports submission is a separate, source-build task to be
created only if needed.

See `README.md` for the current package list and install instructions.

## Public repository

This repository is public: all committed files and commit history are visible.
Do not commit private keys, tokens, credentials, or local session notes. The
signing public key (`keys/tallica.rsa.pub`) is intentionally public; the
private key stays in `~/.abuild/tallica.rsa` and the `APK_SIGNING_KEY_B64`
secret. Commit author metadata is public as well. The workflow runs only on
pushes to `master` and `workflow_dispatch`, so fork PRs cannot access secrets;
keep it that way or use a separate unprivileged PR workflow.

## Layout

- `apkbuilds/<pkg>/APKBUILD` — packages built and signed by this repository.
- `scripts/keygen.sh` — one-time APK signing key generation.
- `scripts/build.sh` — build, checksum, and sign; called by the Makefile and CI.
- `Makefile` — the command interface; run `make help`.
- `.claude/skills/update-apk-package/SKILL.md` — the package update procedure.
- `.github/workflows/build.yml` — builds `x86_64` and `aarch64`, deploys Pages.
- `keys/tallica.rsa.pub` — committed public key, served at `/keys/`.
- `CHANGELOG.md` — Keep a Changelog 1.1.0 format.

## Commands

`abuild` only runs on Alpine, so all commands use an `alpine:edge` container.
The Makefile is the single command interface; run `make help`. Output is
written to `site/`, which is gitignored.

## Conventions

### Commit messages

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```text
<type>[optional scope]: <description>
```

Common types: `feat`, `fix`, `docs`, `chore`, `ci`, `build`, `test`,
`refactor`, `perf`, `style`, `revert`. Use a scope when it helps, for example:

```text
feat(lazyincus): bump to 0.17.0
fix(incus-compose): select the correct release asset
docs: add changelog
ci: build the arm64 repository on a native runner
```

Mark breaking changes with `!` after the type/scope or a `BREAKING CHANGE:`
footer. Keep the subject imperative and concise; proper nouns may be
capitalized.

### Changelog

Follow [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/):

- Add user-visible changes under `## [Unreleased]`.
- Use the categories `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and
  `Security`.
- On release, move the entries to a new `## [x.y.z] - YYYY-MM-DD` section and
  update the comparison links at the bottom.
- A typical mapping from commits: `feat` → `Added`, `fix` → `Fixed`,
  breaking changes → `Changed` or `Removed`, security fixes → `Security`.
  `docs`, `chore`, `ci`, and `test` usually do not need an entry unless the
  change is user-visible.

## Adding a package

Create `apkbuilds/<pkgname>/APKBUILD`; `scripts/build.sh` builds every
directory under `apkbuilds/`. Set `arch=` to the architectures supported by the
upstream release, and add a matrix entry to the workflow if it needs anything
beyond `x86_64`/`aarch64`.

## Updating a package

Use the `update-apk-package` skill in `.claude/skills/`; it is the single
source for the update procedure. It bumps the APKBUILD, runs `make checksum`,
builds both architectures, updates `CHANGELOG.md`, and commits.

## Important packaging details

- Each APKBUILD declares the architectures for which upstream publishes
  binaries. The current packages use `arch="x86_64 aarch64"`. Do not add
  architectures without an upstream asset.
- Both architecture archives are listed in `source`; `package()` selects the
  one matching `$CARCH`. `abuild` unpacks both, so the selected archive is
  extracted again into `$srcdir/$CARCH` to avoid one binary overwriting the
  other.
- `builddir="$srcdir"` is required because the release archives contain files
  at the top level rather than a `$pkgname-$pkgver/` directory.
- `options="!check !strip"` is intentional: the binaries are pre-tested and
  already stripped upstream, and the package should contain them unchanged.
- `jochumdev/incus-compose` is a fork; the canonical upstream is
  `lxc/incus-compose`. `incus-compose` is a third-party package: its APKBUILD
  lists only `# Maintainer`, not `# Contributor`, because the package
  maintainer is not the upstream author. `lazyincus` lists both.

## Security

The private signing key is the trust anchor for the repository:

- Local path: `~/.abuild/tallica.rsa`.
- CI: the `APK_SIGNING_KEY_B64` repository secret.

Never commit a `*.rsa` file, `site/`, or built `.apk`/`APKINDEX` artifacts. If a
private key is exposed, generate a new one, replace the secret and
`keys/tallica.rsa.pub`, and tell users to update their `/etc/apk/keys/` copy.
