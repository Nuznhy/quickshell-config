#!/usr/bin/env bash
set -euo pipefail

source_name=${1:?A microphone device is required}
pactl set-default-source "$source_name"
outputs=$(pactl --format=json list source-outputs)
ids=$(jq -r '.[].index' <<< "$outputs")
result=0
while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    # Continue if a recording stream closes while the device is being switched.
    pactl move-source-output "$id" "$source_name" || result=1
done <<< "$ids"
exit "$result"
