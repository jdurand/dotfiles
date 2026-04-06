import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import { createState, For } from "ags"
import PopupWindow from "./PopupWindow"

// Required env: ~/.dotfiles/environment/calendar.env
//   GOOGLE_CALENDAR_ID - Google Calendar ID (usually your email)

const VERTICAL = Gtk.Orientation.VERTICAL

interface CalendarEvent {
  summary: string
  start: string
  isAllDay: boolean
  location: string
  hangoutLink: string | null
  htmlLink: string | null
}

const CALENDAR_CMD = [
  "bash", "-c",
  `source "$HOME/.dotfiles/environment/calendar.env" 2>/dev/null;
   GWS="$HOME/.local/share/mise/installs/node/20.20.0/bin/gws";
   [ -x "$GWS" ] || GWS="$(command -v gws 2>/dev/null)";
   TODAY_START=$(date -d "today 00:00" -u +%Y-%m-%dT%H:%M:%S.000Z);
   TODAY_END=$(date -d "today 23:59" -u +%Y-%m-%dT%H:%M:%S.000Z);
   timeout 10 "$GWS" calendar events list \
     --params "{\\"calendarId\\":\\"$GOOGLE_CALENDAR_ID\\",\\"timeMin\\":\\"$TODAY_START\\",\\"timeMax\\":\\"$TODAY_END\\",\\"singleEvents\\":true,\\"orderBy\\":\\"startTime\\"}" \
     2>/dev/null || echo '{"items":[]}'`,
]

function parseEvents(output: string): CalendarEvent[] {
  try {
    const data = JSON.parse(output.trim())
    const items = data.items || []
    return items.map((e: any) => ({
      summary: e.summary || "No title",
      start: e.start?.dateTime || e.start?.date || "",
      isAllDay: !e.start?.dateTime,
      location: e.location || "",
      hangoutLink: e.hangoutLink || null,
      htmlLink: e.htmlLink || null,
    }))
  } catch {
    return []
  }
}

function formatTime(start: string): string {
  if (!start || !start.includes("T")) return ""
  try {
    const d = new Date(start)
    const h = d.getHours().toString().padStart(2, "0")
    const m = d.getMinutes().toString().padStart(2, "0")
    return `${h}:${m}`
  } catch {
    return ""
  }
}

function minutesUntil(start: string): number {
  const eventTime = new Date(start).getTime()
  return Math.floor((eventTime - Date.now()) / 60_000)
}

function eventUrgency(event: CalendarEvent): string {
  if (event.isAllDay || !event.hangoutLink) return ""
  const mins = minutesUntil(event.start)
  if (mins <= 5 && mins >= -3) return "meeting-urgent"
  if (mins <= 15 && mins > 5) return "meeting-soon"
  return ""
}

function EventRow({ event }: { event: CalendarEvent }) {
  const time = formatTime(event.start)
  const urgency = eventUrgency(event)
  const hasMeet = !!event.hangoutLink
  const url = event.hangoutLink || event.htmlLink

  // Top line: time + badge
  const timeLabel = event.isAllDay ? "All day" : time
  const badge = hasMeet ? "Meet" : (event.location ? "Room" : "")

  return (
    <button
      class={`popup-row ${urgency}`}
      onClicked={() => {
        if (url) execAsync(["xdg-open", url])
      }}
    >
      <box orientation={VERTICAL}>
        <box class="row-top">
          <label class="meeting-time" label={timeLabel} xalign={0} />
          {badge !== "" && (
            <label
              class={hasMeet ? "badge badge-meet" : "badge badge-room"}
              label={badge}
            />
          )}
        </box>
        <label
          class="meeting-summary"
          label={event.summary}
          xalign={0}
          ellipsize={Pango.EllipsizeMode.END}
          maxWidthChars={48}
        />
      </box>
    </button>
  )
}

export default function CalendarPopup() {
  const [events, setEvents] = createState<CalendarEvent[]>([])

  function fetchData() {
    execAsync(CALENDAR_CMD)
      .then((out) => setEvents(parseEvents(out)))
      .catch(() => setEvents([]))
  }

  fetchData()
  interval(300_000, fetchData)

  return PopupWindow({
    name: "calendar-popup",
    marginRight: 500,
    child: (
      <box orientation={VERTICAL} class="popup-content">
        <label class="popup-header" label="TODAY'S SCHEDULE" xalign={0} />
        <box orientation={VERTICAL} class="popup-list">
          <label
            class="popup-empty"
            label="No events today"
            visible={events((l: CalendarEvent[]) => l.length === 0)}
          />
          <For each={events}>
            {(event: CalendarEvent) => <EventRow event={event} />}
          </For>
        </box>
      </box>
    ),
  })
}
