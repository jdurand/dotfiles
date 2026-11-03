#!/usr/bin/env bash
set -euo pipefail

client=$(hyprctl clients -j | jq -r '[.[] | select(.class == "com.mitchellh.ghostty.quick") | "\(.address)\t\(.workspace.name)"][0] // empty')

if [[ -n $client ]]; then
  IFS=$'\t' read -r address workspace <<< "$client"
  if [[ $workspace == "special:quick-terminal" ]]; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("quick-terminal")'
  else
    hyprctl dispatch "hl.dsp.window.move({ window = \"address:$address\", workspace = \"special:quick-terminal\", follow = false })"
  fi
elif hyprctl workspaces -j | jq -e '.[] | select(.name == "special:quick-terminal" and .windows > 0)' >/dev/null; then
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("quick-terminal")'
else
  setsid env GHOSTTY_QUICK_TERMINAL=1 uwsm-app -- ghostty --gtk-single-instance=false --class=com.mitchellh.ghostty.quick --title='Quick Terminal' >/dev/null 2>&1 &

  for _ in {1..30}; do
    client=$(hyprctl clients -j | jq -r '[.[] | select(.class == "com.mitchellh.ghostty.quick") | "\(.address)\t\(.monitor)"][0] // empty')
    [[ -n $client ]] && break
    sleep 0.1
  done

  if [[ -n ${client:-} ]]; then
    IFS=$'\t' read -r address monitor <<< "$client"
    read -r width height < <(hyprctl monitors -j | jq -r --argjson monitor "$monitor" '.[] | select(.id == $monitor) | "\((.width / .scale * 0.9) | round) \((.height / .scale * 0.9) | round)"')
    hyprctl dispatch "hl.dsp.window.resize({ window = \"address:$address\", x = $width, y = $height })"
    hyprctl dispatch "hl.dsp.window.center({ window = \"address:$address\" })"
  fi
fi
