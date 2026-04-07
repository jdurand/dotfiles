import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import { createState, For } from "ags"
import PopupWindow from "./PopupWindow"
import {
  ENV_FILE,
  COMPANY_MANAGED,
  FIELD_STORY_POINTS,
  FIELD_SPRINT,
  STATUS_TO_COLUMN,
  TRANSITION_ORDER,
  HIDDEN_TRANSITIONS,
  STATUS_STYLES,
  AUTO_ASSIGN_STATUS,
  ISSUES_JQL,
  MAX_ISSUES,
  MAX_SUBTASKS,
  POLL_INTERVAL_MS,
  POPUP_MARGIN_RIGHT,
  CARD_MAX_WIDTH_CHARS,
  SUBTASK_MAX_WIDTH_CHARS,
} from "../lib/jira-config"

// Required env vars in ~/.dotfiles/environment/jira.env:
//   JIRA_BASE_URL   - e.g. https://yourorg.atlassian.net
//   JIRA_CLOUD_ID   - Atlassian cloud instance UUID
//   JIRA_ACCOUNT_ID - your Jira account ID (for auto-assign)
//   JIRA_PROJECT    - default project key (e.g. LIB)
//   JIRA_BOARD_ID   - board ID for sprint URLs
//   JIRA_EMAIL      - login email
//   JIRA_API_TOKEN  - API token (read/write scope)

const VERTICAL = Gtk.Orientation.VERTICAL
const HORIZONTAL = Gtk.Orientation.HORIZONTAL
const ENV_PREFIX = `source "${ENV_FILE}" 2>/dev/null`

let jiraBaseUrl = ""
let jiraProject = ""
let jiraBoardId = ""
execAsync(["bash", "-c", `${ENV_PREFIX}; echo "$JIRA_BASE_URL"; echo "$JIRA_PROJECT"; echo "$JIRA_BOARD_ID"`])
  .then((out) => {
    const lines = out.trim().split("\n")
    jiraBaseUrl = lines[0] || ""
    jiraProject = lines[1] || ""
    jiraBoardId = lines[2] || ""
  })
  .catch(() => {})

// --- Types ---

interface Subtask {
  key: string
  summary: string
  status: string
}

interface JiraIssue {
  key: string
  summary: string
  status: string
  fixVersion: string
  storyPoints: number | null
  subtasks: Subtask[]
}

interface Transition {
  id: string
  name: string
  toName: string
}

interface SprintInfo {
  name: string
  goal: string
  boardId: number
  id: number
  startDate: string
  endDate: string
}

type Column = string

// --- Column assignment ---

function columnFor(status: string): Column | null {
  return STATUS_TO_COLUMN[status.toLowerCase()] ?? null
}

// --- Status styling ---

function statusClass(status: string): string {
  return STATUS_STYLES[status.toLowerCase()] ?? "st-todo"
}

// --- API helpers ---

const CURL_AUTH = `-u "$JIRA_EMAIL:$JIRA_API_TOKEN" -H "Content-Type: application/json"`
const API_BASE_SH = `https://api.atlassian.com/ex/jira/$JIRA_CLOUD_ID/rest/api/3`

function jiraSearch(jql: string, fields: string[], maxResults: number): string[] {
  const fieldList = fields.map((f) => `"${f}"`).join(",")
  return [
    "bash", "-c",
    `${ENV_PREFIX}; curl -sf ${CURL_AUTH} \
       "${API_BASE_SH}/search/jql" \
       -X POST -d '{"jql":"${jql}","maxResults":${maxResults},"fields":[${fieldList}]}' \
       2>/dev/null || echo '{"issues":[]}'`,
  ]
}

function fetchIssuesCmd(): string[] {
  return jiraSearch(
    ISSUES_JQL,
    ["summary", "status", "fixVersions", FIELD_STORY_POINTS, FIELD_SPRINT],
    MAX_ISSUES,
  )
}

function fetchSubtasksCmd(parentKeys: string[]): string[] {
  return jiraSearch(
    `parent in (${parentKeys.join(",")}) ORDER BY rank ASC`,
    ["summary", "status", "parent"],
    MAX_SUBTASKS,
  )
}

function fetchTransitionsCmd(key: string): string[] {
  return [
    "bash", "-c",
    `${ENV_PREFIX}; curl -sf ${CURL_AUTH} \
       "${API_BASE_SH}/issue/${key}/transitions" \
       2>/dev/null || echo '{"transitions":[]}'`,
  ]
}

function doTransitionCmd(key: string, transitionId: string, assignToMe = false): string[] {
  const assignCmd = assignToMe
    ? `; curl -sf ${CURL_AUTH} "${API_BASE_SH}/issue/${key}/assignee" -X PUT -d "{\\"accountId\\":\\"$JIRA_ACCOUNT_ID\\"}" 2>/dev/null`
    : ""
  return [
    "bash", "-c",
    `${ENV_PREFIX}; curl -sf ${CURL_AUTH} \
       "${API_BASE_SH}/issue/${key}/transitions" \
       -X POST -d '{"transition":{"id":"${transitionId}"}}' \
       2>/dev/null${assignCmd}`,
  ]
}

// --- Parsing ---

function parseIssues(output: string): { issues: JiraIssue[]; sprint: SprintInfo | null } {
  try {
    const data = JSON.parse(output.trim())
    const issues = (data.issues || []).map((i: any) => ({
      key: i.key || "",
      summary: i.fields?.summary || "",
      status: i.fields?.status?.name || "",
      fixVersion: i.fields?.fixVersions?.[0]?.name || "",
      storyPoints: i.fields?.[FIELD_STORY_POINTS] ?? null,
      subtasks: [],
    }))

    let sprint: SprintInfo | null = null
    const sprints = data.issues?.[0]?.fields?.[FIELD_SPRINT]
    if (Array.isArray(sprints)) {
      const active = sprints.find((s: any) => s.state === "active") || sprints[0]
      if (active) {
        sprint = {
          name: active.name || "",
          goal: active.goal || "",
          boardId: active.boardId || 0,
          id: active.id || 0,
          startDate: active.startDate || "",
          endDate: active.endDate || "",
        }
      }
    }

    return { issues, sprint }
  } catch { return { issues: [], sprint: null } }
}

function parseSubtasks(output: string): Map<string, Subtask[]> {
  const map = new Map<string, Subtask[]>()
  try {
    const data = JSON.parse(output.trim())
    for (const i of data.issues || []) {
      const parentKey = i.fields?.parent?.key
      if (!parentKey) continue
      const list = map.get(parentKey) || []
      list.push({
        key: i.key || "",
        summary: i.fields?.summary || "",
        status: i.fields?.status?.name || "",
      })
      map.set(parentKey, list)
    }
  } catch {}
  return map
}

function transitionOrder(name: string): number {
  return TRANSITION_ORDER[name.toLowerCase()] ?? 50
}

function parseTransitions(output: string): Transition[] {
  try {
    const data = JSON.parse(output.trim())
    const hiddenSet = new Set(HIDDEN_TRANSITIONS)

    const raw = (data.transitions || [])
      .filter((t: any) => !hiddenSet.has((t.to?.name || "").toLowerCase()))
      .map((t: any) => ({
        id: t.id,
        name: t.name,
        toName: t.to?.name || t.name,
      }))

    const seen = new Set<string>()
    const unique: Transition[] = []
    for (const t of raw) {
      const key = t.toName.toLowerCase()
      if (seen.has(key)) continue
      seen.add(key)
      unique.push(t)
    }

    unique.sort((a: Transition, b: Transition) =>
      transitionOrder(a.toName) - transitionOrder(b.toName)
    )
    return unique
  } catch { return [] }
}

// --- Components ---

function StatusDropdown({
  issueKey,
  currentStatus,
  onChanged,
}: {
  issueKey: string
  currentStatus: string
  onChanged: () => void
}) {
  const [transitions, setTransitions] = createState<Transition[]>([])
  const [loading, setLoading] = createState(false)

  function loadTransitions() {
    setLoading(true)
    execAsync(fetchTransitionsCmd(issueKey))
      .then((out) => {
        const all = parseTransitions(out)
        const filtered = all.filter(
          (t) => t.toName.toLowerCase() !== currentStatus.toLowerCase()
        )
        setTransitions(filtered)
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }

  function doTransition(t: Transition) {
    const assignToMe = t.toName.toLowerCase() === AUTO_ASSIGN_STATUS
    execAsync(doTransitionCmd(issueKey, t.id, assignToMe))
      .then(() => onChanged())
      .catch(() => {})
  }

  const popoverWidget = (
    <popover>
      <box orientation={VERTICAL} class="transition-list">
        <label
          class="transition-loading"
          label="Loading..."
          visible={loading}
        />
        <For each={transitions}>
          {(t: Transition) => (
            <button
              class="transition-option"
              onClicked={() => doTransition(t)}
            >
              <label label={t.toName} xalign={0} />
            </button>
          )}
        </For>
      </box>
    </popover>
  ) as Gtk.Popover

  return (
    <menubutton
      class={`status-badge ${statusClass(currentStatus)}`}
      hasFrame={false}
      popover={popoverWidget}
      $={(self: Gtk.MenuButton) => {
        self.connect("notify::active", () => {
          if (self.active) loadTransitions()
        })
      }}
    >
      <label class="status-badge-label" label={currentStatus} />
    </menubutton>
  )
}

function SubtaskRow({
  subtask,
  onChanged,
}: {
  subtask: Subtask
  onChanged: () => void
}) {
  return (
    <box class="subtask-row">
      <label
        class="subtask-summary"
        label={subtask.summary}
        xalign={0}
        hexpand
        ellipsize={Pango.EllipsizeMode.END}
        maxWidthChars={SUBTASK_MAX_WIDTH_CHARS}
      />
      <StatusDropdown
        issueKey={subtask.key}
        currentStatus={subtask.status}
        onChanged={onChanged}
      />
    </box>
  )
}

function IssueCard({
  issue,
  onChanged,
}: {
  issue: JiraIssue
  onChanged: () => void
}) {
  const hasSubtasks = issue.subtasks.length > 0
  const doneCount = issue.subtasks.filter((s) => s.status.toLowerCase() === "done").length
  const subtaskLabel = hasSubtasks ? `${doneCount}/${issue.subtasks.length}` : ""

  let expandedBox: Gtk.Widget | null = null
  let caretLabel: Gtk.Label | null = null
  let expanded = false

  function toggleExpand() {
    expanded = !expanded
    if (expandedBox) expandedBox.visible = expanded
    if (caretLabel) caretLabel.label = expanded ? "\u25BE" : "\u25B8"
  }

  return (
    <box class="kanban-card" orientation={VERTICAL}>
      {hasSubtasks ? (
        <button class="card-top-row" onClicked={toggleExpand}>
          <box>
            <label
              class="card-caret"
              label={"\u25B8"}
              valign={Gtk.Align.START}
              $={(self: Gtk.Label) => { caretLabel = self }}
            />
            <label
              class="card-summary"
              label={issue.summary}
              xalign={0}
              hexpand
              wrap
              maxWidthChars={CARD_MAX_WIDTH_CHARS}
            />
          </box>
        </button>
      ) : (
        <box class="card-title-static">
          <label
            class="card-summary"
            label={issue.summary}
            xalign={0}
            hexpand
            wrap
            maxWidthChars={CARD_MAX_WIDTH_CHARS}
          />
        </box>
      )}
      <box class="card-meta">
        <button
          class="card-key-link"
          onClicked={() => execAsync(["xdg-open", `${jiraBaseUrl}/browse/${issue.key}`])}
        >
          <box>
            <label class="card-key" label={issue.key} />
            <label class="card-link-icon" label={"\u2197"} />
          </box>
        </button>
        {issue.storyPoints !== null && (
          <label class="card-sp" label={`${issue.storyPoints}pt`} />
        )}
        {issue.fixVersion !== "" && (
          <label class="card-version" label={`v${issue.fixVersion}`} />
        )}
        {hasSubtasks && (
          <label class="subtask-count" label={`\u2630 ${subtaskLabel}`} />
        )}
        <box hexpand />
        <StatusDropdown
          issueKey={issue.key}
          currentStatus={issue.status}
          onChanged={onChanged}
        />
      </box>
      <box
        class="card-expanded"
        orientation={VERTICAL}
        visible={false}
        $={(self: Gtk.Widget) => { expandedBox = self }}
      >
        {hasSubtasks && (
          <box class="subtask-list" orientation={VERTICAL}>
            {issue.subtasks.map((st) => (
              <SubtaskRow subtask={st} onChanged={onChanged} />
            ))}
          </box>
        )}
      </box>
    </box>
  )
}

function KanbanColumnHeader({
  title,
  items,
}: {
  title: string
  items: ReturnType<typeof createState<JiraIssue[]>>[0]
}) {
  return (
    <label
      class="kanban-column-header"
      label={items((list: JiraIssue[]) => `${title.toUpperCase()}  ${list.length}`)}
      xalign={0}
    />
  )
}

// --- Main popup ---

function sprintBoardUrl(sprint: SprintInfo): string {
  const prefix = COMPANY_MANAGED ? "/jira/software/c/projects" : "/jira/software/projects"
  const board = jiraBoardId || sprint.boardId
  return `${jiraBaseUrl}${prefix}/${jiraProject}/boards/${board}?sprint=${sprint.id}`
}

export default function JiraPopup() {
  const [todoItems, setTodoItems] = createState<JiraIssue[]>([])
  const [progressItems, setProgressItems] = createState<JiraIssue[]>([])
  const [reviewItems, setReviewItems] = createState<JiraIssue[]>([])
  const [sprintName, setSprintName] = createState("")
  const [sprintDates, setSprintDates] = createState("")
  const [sprintGoal, setSprintGoal] = createState("")

  let sprintUrl = ""

  function formatDate(iso: string): string {
    if (!iso) return ""
    const d = new Date(iso)
    return d.toLocaleDateString("en-US", { month: "short", day: "numeric" })
  }

  function fetchData() {
    execAsync(fetchIssuesCmd())
      .then((out) => {
        const { issues, sprint } = parseIssues(out)

        if (sprint) {
          setSprintName(sprint.name)
          setSprintDates(`${formatDate(sprint.startDate)} \u2013 ${formatDate(sprint.endDate)}`)
          setSprintGoal(sprint.goal ? sprint.goal.split("\n")[0] : "")
          sprintUrl = sprintBoardUrl(sprint)
        }

        const parentKeys = issues.map((i) => i.key)

        const subtaskPromise = parentKeys.length > 0
          ? execAsync(fetchSubtasksCmd(parentKeys)).then(parseSubtasks)
          : Promise.resolve(new Map<string, Subtask[]>())

        return subtaskPromise.then((subtaskMap) => {
          for (const issue of issues) {
            issue.subtasks = subtaskMap.get(issue.key) || []
          }

          const todo: JiraIssue[] = []
          const progress: JiraIssue[] = []
          const review: JiraIssue[] = []

          for (const issue of issues) {
            const col = columnFor(issue.status)
            if (col === "todo") todo.push(issue)
            else if (col === "inprogress") progress.push(issue)
            else if (col === "inreview") review.push(issue)
          }

          setTodoItems(todo)
          setProgressItems(progress)
          setReviewItems(review)
        })
      })
      .catch(() => {
        setTodoItems([])
        setProgressItems([])
        setReviewItems([])
      })
  }

  fetchData()
  interval(POLL_INTERVAL_MS, fetchData)

  return PopupWindow({
    name: "jira-popup",
    marginRight: POPUP_MARGIN_RIGHT,
    onVisibilityChanged: (v: boolean) => {
      if (v) fetchData()
    },
    child: (
      <box orientation={VERTICAL} class="popup-content">
        <button
          class="popup-header-link"
          onClicked={() => { if (sprintUrl) execAsync(["xdg-open", sprintUrl]) }}
        >
          <box orientation={VERTICAL}>
            <box>
              <label class="sprint-label" label="Current Sprint:" />
              <label class="sprint-name" label={sprintName} xalign={0} />
              <label class="card-link-icon" label={"\u2197"} />
              <box hexpand />
              <label class="sprint-dates" label={sprintDates} xalign={1} />
            </box>
            <label
              class="sprint-goal"
              label={sprintGoal}
              xalign={0}
              visible={sprintGoal((g: string) => g !== "")}
            />
          </box>
        </button>
        <box orientation={HORIZONTAL} class="kanban-board">
          <box class="kanban-column" orientation={VERTICAL}>
            <KanbanColumnHeader title="To Do" items={todoItems} />
            <box orientation={VERTICAL} class="kanban-card-list">
              <For each={todoItems} id={(i: JiraIssue) => i.key}>
                {(issue: JiraIssue) => <IssueCard issue={issue} onChanged={fetchData} />}
              </For>
            </box>
          </box>
          <box class="kanban-column" orientation={VERTICAL}>
            <KanbanColumnHeader title="In Progress" items={progressItems} />
            <box orientation={VERTICAL} class="kanban-card-list">
              <For each={progressItems} id={(i: JiraIssue) => i.key}>
                {(issue: JiraIssue) => <IssueCard issue={issue} onChanged={fetchData} />}
              </For>
            </box>
          </box>
          <box class="kanban-column" orientation={VERTICAL}>
            <KanbanColumnHeader title="In Review" items={reviewItems} />
            <box orientation={VERTICAL} class="kanban-card-list">
              <For each={reviewItems} id={(i: JiraIssue) => i.key}>
                {(issue: JiraIssue) => <IssueCard issue={issue} onChanged={fetchData} />}
              </For>
            </box>
          </box>
        </box>
      </box>
    ),
  })
}
