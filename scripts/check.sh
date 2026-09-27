#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
formatter="${QMLFORMAT:-/usr/lib/qt6/bin/qmlformat}"
if ! command -v "$formatter" >/dev/null 2>&1; then
    printf 'Qt 6 qmlformat not found. Set QMLFORMAT to its path.\n' >&2
    exit 1
fi

count=0
while IFS= read -r -d '' file; do
    "$formatter" "$file" >/dev/null
    count=$((count + 1))
done < <(find . -type f -name '*.qml' -not -path './.git/*' -print0)

printf 'QML syntax check passed (%s files).\n' "$count"
