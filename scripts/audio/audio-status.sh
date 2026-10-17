#!/usr/bin/env bash
set -euo pipefail

default_sink=$(pactl get-default-sink)
sinks=$(pactl --format=json list sinks)
inputs=$(pactl --format=json list sink-inputs)
default_source=$(pactl get-default-source || true)
sources=$(pactl --format=json list sources)
jq --arg default "$default_sink" --argjson inputs "$inputs" \
    --arg defaultSource "$default_source" --argjson sources "$sources" \
    '{default: $default, sinks: ., inputs: $inputs, defaultSource: $defaultSource, sources: $sources}' <<< "$sinks"
