#!/usr/bin/env bash
set -euo pipefail

# The device name is passed as an argument, never evaluated as shell code.
sink=${1:?An output device is required}
pactl set-default-sink "$sink"
inputs=$(pactl --format=json list sink-inputs)
ids=$(jq -r '.[].index' <<< "$inputs")
result=0
while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    # A stream can disappear while switching; continue moving the remaining ones.
    pactl move-sink-input "$id" "$sink" || result=1
done <<< "$ids"
exit "$result"
