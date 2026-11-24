#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
source ../../scripts/build-images.sh

build_images "${1:---publish}" amd64 "${OPENJDK_TAG_AMD64}" Dockerfile tsingyun-openjdk .
