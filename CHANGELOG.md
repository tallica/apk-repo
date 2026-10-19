# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
and [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

## [0.1.0] - 2026-10-19

### Added

- Signed Alpine APK repository for `lazyincus` and `incus-compose`, published
  from GitHub Pages.
- Binary APKBUILDs for `lazyincus` 0.16.1 and `incus-compose` 1.3.5, covering
  `x86_64` and `aarch64`.
- Build, signing, and checksum scripts, plus a `Makefile`.
- GitHub Actions workflow that builds both architectures, signs the repository
  indexes, and deploys the result to GitHub Pages.
