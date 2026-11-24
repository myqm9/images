#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
source ../../scripts/build-images.sh

build_images "${1:---publish}" arm64 "${CLICKHOUSE_ARM_VERSION}-arm64" 23.3.9.55-arm64/Dockerfile clickhouse .
