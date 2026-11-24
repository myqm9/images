#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
source ../../scripts/build-images.sh

build_images "${1:---publish}" amd64 "${MINIO_VERSION}" Dockerfile minio .
