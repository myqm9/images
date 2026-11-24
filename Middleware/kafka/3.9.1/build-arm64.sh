#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
source ../../../scripts/build-images.sh

build_images "${1:---publish}" arm64 "${KAFKA_391_VERSION}-arm64" Dockerfile-arm64 kafka-kraft .
