// Required env: ~/.dotfiles/environment/calendar.env
//   GOOGLE_CALENDAR_ID - Google Calendar ID (usually your email)

import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import { createState, For } from "ags"
import PopupWindow from "./PopupWindow"

const VERTICAL = Gtk.Orientation.VERTICAL

interface CalendarEvent {
  summary: string
  start: string
  isAllDay: boolean
  location: string
  hangoutLink: string | null
  htmlLink: string | null
}

// Rendered list item: event or "now" separator
interface ListItem {
  id: string
  type: "event" | "now-separator"
  event?: CalendarEvent
  isPast?: boolean
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

function buildListItems(events: CalendarEvent[]): ListItem[] {
  const now = Date.now()
  const items: ListItem[] = []
  let insertedSeparator = false

  for (const event of events) {
    const eventTime = event.isAllDay ? 0 : new Date(event.start).getTime()
    // 3min grace: event is "past" if it started more than 3min ago
    const isPast = !event.isAllDay && eventTime < (now - 180_000)

    // Insert "now" separator before the first upcoming event
    if (!insertedSeparator && !event.isAllDay && !isPast) {
      insertedSeparator = true
      // Only add separator if there were past events before
      if (items.some((i) => i.isPast))  {
        items.push({ id: "now-sep", type: "now-separator" })
      }
    }

    items.push({
      id: `evt-${event.start}-${event.summary}`,
      type: "event",
      event,
      isPast,
    })
  }

  return items
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

function NowSeparator() {
  return (
    <box class="now-separator">
      <label class="now-label" label="now" />
      <box class="now-line" hexpand />
    </box>
  )
}

function EventRow({ event, isPast }: { event: CalendarEvent; isPast: boolean }) {
  const time = formatTime(event.start)
  const urgency = isPast ? "" : eventUrgency(event)
  const hasMeet = !!event.hangoutLink
  const url = event.hangoutLink || event.htmlLink
  const rowClass = isPast ? "popup-row event-past" : `popup-row ${urgency}`

  const timeLabel = event.isAllDay ? "All day" : time
  const badge = hasMeet ? "Meet" : (event.location ? "Room" : "")

  return (
    <button
      class={rowClass}
      onClicked={() => {
        if (url) execAsync(["xdg-open", url])
      }}
    >
      <box orientation={VERTICAL}>
        <box class="row-top">
          <label class={isPast ? "meeting-time event-past-text" : "meeting-time"} label={timeLabel} xalign={0} />
          {badge !== "" && (
            <label
              class={hasMeet ? "badge badge-meet" : "badge badge-room"}
              label={badge}
            />
          )}
        </box>
        <label
          class={isPast ? "meeting-summary event-past-text" : "meeting-summary"}
          label={event.summary}
          xalign={0}
          ellipsize={Pango.EllipsizeMode.END}
          maxWidthChars={48}
        />
      </box>
    </button>
  )
}

function ListRow({ item }: { item: ListItem }) {
  if (item.type === "now-separator") return <NowSeparator />
  return <EventRow event={item.event!} isPast={item.isPast!} />
}

export default function CalendarPopup() {
  const [listItems, setListItems] = createState<ListItem[]>([])

  function fetchData() {
    execAsync(CALENDAR_CMD)
      .then((out) => setListItems(buildListItems(parseEvents(out))))
      .catch(() => setListItems([]))
  }

  fetchData()
  interval(300_000, fetchData)

  return PopupWindow({
    name: "calendar-popup",
    marginRight: 500,
    onVisibilityChanged: (v: boolean) => {
      if (v) fetchData()
    },
    child: (
      <box orientation={VERTICAL} class="popup-content">
        <label class="popup-header" label="TODAY'S SCHEDULE" xalign={0} />
        <box orientation={VERTICAL} class="popup-list">
          <label
            class="popup-empty"
            label="No events today"
            visible={listItems((l: ListItem[]) => l.length === 0)}
          />
          <For each={listItems} id={(i: ListItem) => i.id}>
            {(item: ListItem) => <ListRow item={item} />}
          </For>
        </box>
      </box>
    ),
  })
}
