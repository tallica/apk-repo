# Changelog

All notable changes to this repository will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
Entries are grouped by date rather than release version, since this repository
is not versioned software.

## [2026-10-19]

### Added

- Signed Alpine APK repository for `lazyincus` and `incus-compose`, published
  from GitHub Pages.
- Binary APKBUILDs for `lazyincus` 0.16.1 and `incus-compose` 1.3.5, covering
  `x86_64` and `aarch64`.
- Build, signing, and checksum scripts, plus a `Makefile`.
- GitHub Actions workflow that builds both architectures, signs the repository
  indexes, and deploys the result to GitHub Pages.

### Changed

- Clarified the install guide for tagged and untagged repositories.

### Fixed

- Updated GitHub Actions to Node.js 24-compatible versions.
