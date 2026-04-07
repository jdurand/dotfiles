#!/bin/bash
# Waybar custom module: Google Calendar upcoming meeting count + warning state
# Uses raw gws API to get hangoutLink (Meet) data
# Outputs JSON: {"text": "...", "tooltip": "...", "class": "..."}

GWS="$HOME/.local/share/mise/installs/node/20.20.0/bin/gws"
[ -x "$GWS" ] || GWS="$(command -v gws 2>/dev/null || echo gws)"

[ -f "$HOME/.dotfiles/environment/calendar.env" ] && source "$HOME/.dotfiles/environment/calendar.env"
CALENDAR_ID="$GOOGLE_CALENDAR_ID"

TODAY_START=$(date -d "today 00:00" -u +%Y-%m-%dT%H:%M:%S.000Z)
TODAY_END=$(date -d "today 23:59" -u +%Y-%m-%dT%H:%M:%S.000Z)
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NOW_EPOCH=$(date +%s)

DATA=$(timeout 10 "$GWS" calendar events list \
  --params "{\"calendarId\":\"$CALENDAR_ID\",\"timeMin\":\"$TODAY_START\",\"timeMax\":\"$TODAY_END\",\"singleEvents\":true,\"orderBy\":\"startTime\"}" \
  2>/dev/null)

# All timed events today (not all-day)
TIMED=$(echo "$DATA" | jq '[.items // [] | .[] | select(.start.dateTime != null)]' 2>/dev/null)
TOTAL_COUNT=$(echo "$TIMED" | jq 'length' 2>/dev/null)
TOTAL_COUNT="${TOTAL_COUNT:-0}"

# Count upcoming: convert each start time with date and compare epochs
UPCOMING_COUNT=0
NEXT_MEET_TITLE=""
NEXT_MEET_EPOCH=""
NEXT_HAS_MEET=""

while IFS=$'\t' read -r start_dt hangout_link summary; do
  [ -z "$start_dt" ] && continue
  evt_epoch=$(date -d "$start_dt" +%s 2>/dev/null) || continue
  # 3 min grace period for ongoing meetings
  if [ "$evt_epoch" -gt $((NOW_EPOCH - 180)) ]; then
    UPCOMING_COUNT=$((UPCOMING_COUNT + 1))
    # Track next meeting with a Meet link
    if [ -n "$hangout_link" ] && [ -z "$NEXT_MEET_EPOCH" ]; then
      NEXT_MEET_EPOCH="$evt_epoch"
      NEXT_MEET_TITLE="$summary"
      NEXT_HAS_MEET="1"
    fi
  fi
done < <(echo "$TIMED" | jq -r '.[] | [.start.dateTime, (.hangoutLink // ""), .summary] | @tsv' 2>/dev/null)

ICON="󰃭"

if [ "$TOTAL_COUNT" -eq 0 ] 2>/dev/null; then
  echo "{\"text\": \"${ICON}\", \"tooltip\": \"No events today\", \"class\": \"empty\"}"
  exit 0
fi

if [ "$UPCOMING_COUNT" -eq 0 ] 2>/dev/null; then
  ICON="󰃯"
  echo "{\"text\": \"${ICON}\", \"tooltip\": \"All ${TOTAL_COUNT} events done\", \"class\": \"empty\"}"
  exit 0
fi

CLASS="normal"
TOOLTIP="${UPCOMING_COUNT} upcoming events"

# Warning for next meeting with Meet link
if [ -n "$NEXT_MEET_EPOCH" ]; then
  MINS_UNTIL=$(( (NEXT_MEET_EPOCH - NOW_EPOCH) / 60 ))
  if [ "$MINS_UNTIL" -le 5 ] && [ "$MINS_UNTIL" -ge -3 ]; then
    SHORT_TITLE="${NEXT_MEET_TITLE:0:25}"
    [ "${#NEXT_MEET_TITLE}" -gt 25 ] && SHORT_TITLE="${SHORT_TITLE}…"
    echo "{\"text\": \"󰍫 ${SHORT_TITLE}\", \"tooltip\": \"Join: ${NEXT_MEET_TITLE}\", \"class\": \"urgent\"}"
    exit 0
  elif [ "$MINS_UNTIL" -le 15 ] && [ "$MINS_UNTIL" -gt 5 ]; then
    CLASS="warning"
    TOOLTIP="Next meeting in ${MINS_UNTIL}min: ${NEXT_MEET_TITLE}"
  fi
fi

echo "{\"text\": \"${ICON} ${UPCOMING_COUNT}\", \"tooltip\": \"${TOOLTIP}\", \"class\": \"${CLASS}\"}"
