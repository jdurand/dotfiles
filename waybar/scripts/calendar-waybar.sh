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
NOW_EPOCH=$(date +%s)

DATA=$(timeout 10 "$GWS" calendar events list \
  --params "{\"calendarId\":\"$CALENDAR_ID\",\"timeMin\":\"$TODAY_START\",\"timeMax\":\"$TODAY_END\",\"singleEvents\":true,\"orderBy\":\"startTime\"}" \
  2>/dev/null)

# All timed events today (not all-day)
TIMED=$(echo "$DATA" | jq '[.items // [] | .[] | select(.start.dateTime != null)]' 2>/dev/null)
TOTAL_COUNT=$(echo "$TIMED" | jq 'length' 2>/dev/null)
TOTAL_COUNT="${TOTAL_COUNT:-0}"

# Only upcoming events (start time in the future, with 3min grace for ongoing)
UPCOMING=$(echo "$TIMED" | jq "[.[] | select((.start.dateTime | fromdateiso8601) > ($NOW_EPOCH - 180))]" 2>/dev/null)
UPCOMING_COUNT=$(echo "$UPCOMING" | jq 'length' 2>/dev/null)
UPCOMING_COUNT="${UPCOMING_COUNT:-0}"

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

# Find next meeting with a Meet link
NEXT_MEET=$(echo "$UPCOMING" | jq -r '[.[] | select(.hangoutLink != null)] | sort_by(.start.dateTime) | .[0]' 2>/dev/null)

if [ "$NEXT_MEET" != "null" ] && [ -n "$NEXT_MEET" ]; then
  NEXT_START=$(echo "$NEXT_MEET" | jq -r '.start.dateTime' 2>/dev/null)
  NEXT_EPOCH=$(date -d "$NEXT_START" +%s 2>/dev/null)
  NEXT_TITLE=$(echo "$NEXT_MEET" | jq -r '.summary // "Meeting"' 2>/dev/null)

  if [ -n "$NEXT_EPOCH" ]; then
    MINS_UNTIL=$(( (NEXT_EPOCH - NOW_EPOCH) / 60 ))
    if [ "$MINS_UNTIL" -le 5 ] && [ "$MINS_UNTIL" -ge -3 ]; then
      # Urgent: show meeting name, green flashing
      # Truncate title for bar display
      SHORT_TITLE="${NEXT_TITLE:0:25}"
      [ "${#NEXT_TITLE}" -gt 25 ] && SHORT_TITLE="${SHORT_TITLE}…"
      echo "{\"text\": \"󰍫 ${SHORT_TITLE}\", \"tooltip\": \"Join: ${NEXT_TITLE}\", \"class\": \"urgent\"}"
      exit 0
    elif [ "$MINS_UNTIL" -le 15 ] && [ "$MINS_UNTIL" -gt 5 ]; then
      CLASS="warning"
      TOOLTIP="Next meeting in ${MINS_UNTIL}min: ${NEXT_TITLE}"
    fi
  fi
fi

echo "{\"text\": \"${ICON} ${UPCOMING_COUNT}\", \"tooltip\": \"${TOOLTIP}\", \"class\": \"${CLASS}\"}"
