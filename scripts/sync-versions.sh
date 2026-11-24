#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source versions.env

mode=${1:---check}
case "$mode" in
    --check|--write) ;;
    *) echo "Usage: bash scripts/sync-versions.sh [--check|--write]" >&2; exit 2 ;;
esac
temp=$(mktemp)
trap 'rm -f "$temp"' EXIT
status=0
while IFS= read -r -d '' recipe; do
    awk -v mode=defaults -f scripts/version-args.awk "$recipe" > "$temp"
    if ! cmp -s "$temp" "$recipe"; then
        if [[ $mode == --write ]]; then
            cat "$temp" > "$recipe"
        else
            printf '%s needs sync\n' "$recipe" >&2
            status=1
        fi
    fi
done < <(find Middleware -type f -name 'Dockerfile*' -print0)
exit "$status"
