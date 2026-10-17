#!/usr/bin/env bash
set -euo pipefail

address="${1:-}"
[[ "$address" =~ ^0x[0-9a-fA-F]+$ ]] || exit 1

# A window may have closed or moved since the bar last refreshed.
hyprctl clients -j | jq -e --arg address "$address" \
    'any(.[]; .address == $address)' >/dev/null || exit 0

# Focusing by address also switches to the window's current workspace.
hyprctl dispatch "hl.dsp.focus({ window = 'address:$address' })" >/dev/null

# Read fresh geometry, and never warp onto a different window if focus failed.
center=$(hyprctl activewindow -j | jq -er --arg address "$address" '
    select(.address == $address)
    | select((.at | length) == 2 and (.size | length) == 2)
    | "\((.at[0] + .size[0] / 2) | floor) \((.at[1] + .size[1] / 2) | floor)"
') || exit 0
read -r cursor_x cursor_y <<< "$center"
hyprctl dispatch "hl.dsp.cursor.move({ x = $cursor_x, y = $cursor_y })" >/dev/null
