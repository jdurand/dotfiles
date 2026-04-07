// Jira Kanban board configuration
// Edit this file to adapt the widget to a different project/workflow.

// --- Environment ---

// Path to env file sourced by all bash commands
export const ENV_FILE = "$HOME/.dotfiles/environment/jira.env"

// URL pattern for company-managed projects (has /c/ in path)
// Set to false for team-managed projects
export const COMPANY_MANAGED = true

// --- Custom Fields ---
// These IDs are instance-specific. Find yours via:
//   GET /rest/api/3/field | jq '.[] | select(.name | test("point|sprint"; "i"))'

export const FIELD_STORY_POINTS = "customfield_10024"
export const FIELD_SPRINT = "customfield_10020"

// --- Workflow ---

// Columns displayed on the kanban board (left to right)
export const COLUMNS = [
  { id: "todo", title: "To Do" },
  { id: "inprogress", title: "In Progress" },
  { id: "inreview", title: "In Review" },
] as const

// Map Jira status names → column IDs
// Statuses not listed here are hidden (e.g. Done, Released)
export const STATUS_TO_COLUMN: Record<string, string> = {
  "to do": "todo",
  "in progress": "inprogress",
  // Everything below maps to "inreview"
  "code review": "inreview",
  "test strategy": "inreview",
  "qa": "inreview",
  "pending version": "inreview",
  "to merge": "inreview",
  "pending release": "inreview",
}

// Workflow order for sorting transitions in the dropdown
// Lower number = earlier in the workflow
export const TRANSITION_ORDER: Record<string, number> = {
  "to do": 0,
  "in progress": 1,
  "code review": 2,
  "test strategy": 3,
  "qa": 4,
  "pending version": 5,
  "to merge": 6,
  "pending release": 7,
  "done": 8,
}

// Statuses hidden from the transition dropdown
export const HIDDEN_TRANSITIONS = ["released", "rejected"]

// Status → CSS class for badge coloring
export const STATUS_STYLES: Record<string, string> = {
  "to do": "st-todo",
  "in progress": "st-progress",
  "code review": "st-review",
  "test strategy": "st-review",
  "qa": "st-review",
  "to merge": "st-review",
  "pending version": "st-pending",
  "pending release": "st-pending",
  "done": "st-done",
}

// Status that triggers auto-assign to current user
export const AUTO_ASSIGN_STATUS = "in progress"

// --- JQL ---

// Base JQL for fetching parent issues
// Must exclude all statuses not mapped in STATUS_TO_COLUMN
export const ISSUES_JQL =
  "assignee = currentUser()" +
  " AND sprint in openSprints()" +
  " AND issuetype not in subtaskIssueTypes()" +
  " AND status NOT IN (Done, Released, Rejected)" +
  " ORDER BY rank ASC"

// --- Limits ---

export const MAX_ISSUES = 30
export const MAX_SUBTASKS = 100
export const POLL_INTERVAL_MS = 900_000 // 15 minutes

// --- Layout ---

export const POPUP_MARGIN_RIGHT = 290
export const CARD_MAX_WIDTH_CHARS = 36
export const SUBTASK_MAX_WIDTH_CHARS = 26
