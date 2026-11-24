#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
source ../../scripts/build-images.sh

build_images "${1:---publish}" arm64 "${APOLLO_VERSION}-arm64" Dockerfile-arm64 \
    apollo-configservice apollo-configservice \
    apollo-adminservice apollo-adminservice \
    apollo-portal apollo-portal
