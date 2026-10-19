KEY ?= $(HOME)/.abuild/tallica.rsa
ARCH ?= $(if $(filter aarch64 arm64,$(shell uname -m)),aarch64,x86_64)

.DEFAULT_GOAL := help

.PHONY: help key build build-x86_64 build-aarch64 checksum serve clean

help:
	@printf '%s\n' \
		'key            generate the signing key' \
		'build          build the native architecture' \
		'build-x86_64   build x86_64' \
		'build-aarch64  build aarch64' \
		'checksum       refresh APKBUILD checksums' \
		'serve          serve site/ on http://localhost:8000' \
		'clean          remove site/'

key:
	./scripts/keygen.sh

build: build-$(ARCH)

build-x86_64:
	ABUILD_PRIVKEY="$(KEY)" ./scripts/build.sh x86_64

build-aarch64:
	ABUILD_PRIVKEY="$(KEY)" ./scripts/build.sh aarch64

checksum:
	./scripts/build.sh checksum

serve:
	python3 -m http.server -d site 8000

clean:
	rm -rf site
