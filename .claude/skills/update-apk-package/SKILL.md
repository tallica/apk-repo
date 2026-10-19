---
name: update-apk-package
description: Bump lazyincus or incus-compose to a new upstream release, refresh checksums, build both architectures, update the changelog, and commit. Use when asked to update an APK package version.
---

# Update an APK package

Use this when the user asks to update `lazyincus`, `incus-compose`, or another
package under `apkbuilds/` to a new upstream release.

## Preconditions

- Work from the repository root.
- `git status --short` must be clean. If not, stop and ask the user.
- Docker must be available.
- `~/.abuild/tallica.rsa` must exist for local builds.

## Steps

1. Identify `apkbuilds/<pkgname>/APKBUILD` and the target version. If the
   version is missing, ask for it.
2. Read `url=` from the APKBUILD and verify the release and both Linux assets
   exist:

   ```sh
   gh release view "v<version>" -R <owner>/<repo> --json assets \
     --jq '.assets[].name'
   ```

   The APKBUILD expects `<pkgname>_<version>_linux_amd64.tar.gz` and
   `<pkgname>_<version>_linux_arm64.tar.gz`. Stop if either is missing; do not
   change the asset naming without updating the APKBUILD.

3. Set `pkgver=<version>` and `pkgrel=0` in the APKBUILD.
4. Run `make checksum`. Confirm that `git diff` changes only `pkgver`, `pkgrel`,
   and the two `sha512sums` entries.
5. Build both architectures:

   ```sh
   make build-x86_64
   make build-aarch64
   ```

   Stop and report if either build fails; do not commit a broken package.

6. Add an entry under `## [Unreleased]` in `CHANGELOG.md`, using
   `### Changed` (create the section if needed):

   ```markdown
   - Updated `<pkgname>` to `<version>`.
   ```

7. Commit with:

   ```text
   feat(<pkgname>): bump to <version>
   ```

   Include the repository's standard attribution footer. Do not push unless
   the user asks.

8. Report the commit and note that CI will rebuild and publish the repository
   when `master` is pushed.
