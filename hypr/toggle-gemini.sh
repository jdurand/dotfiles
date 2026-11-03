#!/usr/bin/env bash
set -euo pipefail

client=$(hyprctl clients -j | jq -r '[.[] | select(.class | test("^chrome-gemini\\.google\\.com__app-")) | "\(.address)\t\(.workspace.name)"][0] // empty')

if [[ -n $client ]]; then
  IFS=$'\t' read -r address workspace <<< "$client"
  if [[ $workspace == "special:gemini" ]]; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("gemini")'
  else
    hyprctl dispatch "hl.dsp.window.move({ window = \"address:$address\", workspace = \"special:gemini\", follow = false })"
  fi
elif hyprctl workspaces -j | jq -e '.[] | select(.name == "special:gemini" and .windows > 0)' >/dev/null; then
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("gemini")'
else
  omarchy-launch-webapp https://gemini.google.com/app
fi
