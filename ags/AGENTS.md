# AGS Widget Development Guide

## Overview

This is an AGS v3 (Aylur's GTK Shell) project that provides
popup widgets for the Hyprland desktop. Widgets are triggered
from Waybar custom modules via IPC (`ags request toggle <name>
-i widgets`).

## Architecture

- **Waybar** shows icons + counts in the bar
  (`waybar/scripts/*.sh` → JSON output)
- **AGS** runs as a daemon, provides popup windows
  (`ags/widget/*.tsx`)
- **Waybar on-click** calls `ags request toggle <name> -i
  widgets`
- **Hyprland layerrules** give popups blur
  (`hypr/hyprland.conf`)

## Widgets

### Jira Kanban Board (`widget/JiraPopup.tsx`)

3-column kanban: To Do | In Progress | In Review. Cards show
title, issue key (link to Jira), story points, fix version,
subtask count. Status dropdown transitions issues via Jira
REST API. Cards expand to show subtasks with their own status
controls. Sprint name + dates shown in header as a link.

**Env**: `~/.dotfiles/environment/jira.env`

### PR Reviews (`widget/PrReviewsPopup.tsx`)

Lists GitHub PRs awaiting review. Clicking opens PR in
browser.

**Env**: `~/.dotfiles/environment/github.env`

### Calendar (`widget/CalendarPopup.tsx`)

Shows today's events from Google Calendar via `gws` CLI.
Events with Google Meet links open Meet on click. Waybar icon
shows upcoming count, flashes green when a Meet call is
imminent.

**Env**: `~/.dotfiles/environment/calendar.env`

## Key Technical Decisions

### GTK4 Gotchas (things we debugged)

- **No `vertical` prop on `<box>`**: use
  `orientation={Gtk.Orientation.VERTICAL}`
- **No `truncate` prop on `<label>`**: use
  `ellipsize={Pango.EllipsizeMode.END}` + `maxWidthChars`
- **No `max-width` in GTK4 CSS**: constrain via
  `maxWidthChars` on labels or `min-width` on containers
- **`<scrolledwindow>` crashes with JSX props**: avoid for now,
  use plain `<box>` containers
- **`<For>` is required for reactive lists**: the
  `accessor((list) => list.map(...))` pattern renders as raw
  `Accessor { ... }` text. Always use `<For each={state}>`.
- **Popover double background**: GTK4 popovers have default
  `contents` and `arrow` styling. Must reset with `all: unset`
  on `popover`, `popover > contents`, and `popover > arrow`
  before applying custom styles.
- **MenuButton internal padding**: GTK4 menubuttons have
  internal `> button` with default min-height/padding. Strip
  with `.kanban-card menubutton > button { all: unset;
  min-height: 0; }`
- **Nerd font icons in bash scripts**: characters get lost in
  file writes. Use `printf '\U000FXXXX'` for nerd font
  codepoints, or `"\uXXXX"` in TypeScript.

### Reactive State Pattern

```tsx
const [items, setItems] = createState<T[]>([])

// In JSX — use <For> for lists:
<For each={items} id={(i) => i.key}>
  {(item) => <Row item={item} />}
</For>

// For reactive label text — accessor transform works:
<label label={items((list) => `COUNT: ${list.length}`)} />

// For visibility toggle:
<label visible={items((list) => list.length === 0)} />
```

### Data Fetching

All API calls use `execAsync(["bash", "-c", "..."])` with
`curl`. Environment variables are sourced inside the bash
command. JSON is built manually (avoid `JSON.stringify` inside
single-quoted bash strings).

```tsx
const CMD = [
  "bash", "-c",
  `source "$HOME/.dotfiles/environment/foo.env" 2>/dev/null;
   curl -sf -u "$EMAIL:$TOKEN" "https://..." \
     -X POST -d '{"key":"value"}' \
     2>/dev/null || echo '{"fallback":[]}'`,
]
```

### PopupWindow Pattern

All popups use `widget/PopupWindow.tsx`:
- Fullscreen overlay (click outside to dismiss)
- `<overlay>` separates backdrop from content (so content
  clicks aren't intercepted)
- `onVisibilityChanged` callback fires on show/hide
- Positioned via CSS margins on the content box

### Styling

- `style.scss` uses neutral cool-gray palette (no warm tints)
- Cards are opaque (`#2a2a2a`) against semi-transparent
  container
- All interactive elements strip GTK defaults with
  `all: unset` then add minimal custom styles
- `%meta-tag` SCSS placeholder for consistent tag pills (issue
  key, version, story points, subtask count)
- Status badges use colored backgrounds with white text

## Environment Files

Each widget sources its own env file. **These files contain
secrets and must not be committed.**

### `environment/jira.env`

```
JIRA_BASE_URL     - Atlassian instance URL
JIRA_CLOUD_ID     - Cloud instance UUID
JIRA_ACCOUNT_ID   - Your account ID (for auto-assign)
JIRA_PROJECT      - Default project key
JIRA_EMAIL        - Login email
JIRA_API_TOKEN    - API token (read/write scope)
```

### `environment/github.env`

```
GITHUB_ORG        - GitHub organization to search PRs in
```

### `environment/calendar.env`

```
GOOGLE_CALENDAR_ID - Google Calendar ID (usually your email)
```

## Polling Intervals

- Jira: 15min background, refresh on popup open
- PRs: 15min background
- Calendar: 5min background

## Future Work

- Drag-and-drop cards between columns
- Log time on Jira issues from the card
- Add comments from the expanded card view
- Scrollable columns (needs GTK4 ScrolledWindow fix)
- Empty column placeholder text
