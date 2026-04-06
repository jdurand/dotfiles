#!/bin/bash
# Waybar custom module: GitHub PR review count
# Outputs JSON: {"text": "...", "tooltip": "...", "class": "..."}

[ -f "$HOME/.dotfiles/environment/github.env" ] && source "$HOME/.dotfiles/environment/github.env"

DATA=$(timeout 10 gh search prs \
  --review-requested @me \
  --owner "$GITHUB_ORG" \
  --state open \
  --json title 2>/dev/null)

COUNT=$(echo "$DATA" | jq 'length' 2>/dev/null)
COUNT="${COUNT:-0}"

ICON=$(printf '\U000F062C') # nerd font: git-pull-request

if [ "$COUNT" -gt 0 ] 2>/dev/null; then
  echo "{\"text\": \"${ICON} ${COUNT}\", \"tooltip\": \"${COUNT} PRs awaiting review\", \"class\": \"active\"}"
else
  echo "{\"text\": \"${ICON}\", \"tooltip\": \"No PRs to review\", \"class\": \"empty\"}"
fi
