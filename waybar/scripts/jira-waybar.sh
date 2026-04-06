#!/bin/bash
# Waybar custom module: Jira issue count via Atlassian Cloud API
# Only bright if actionable items (To Do / In Progress) exist
# Outputs JSON: {"text": "...", "tooltip": "...", "class": "..."}

CONFIG_FILE="$HOME/.dotfiles/environment/jira.env"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

JQL="assignee = currentUser() AND sprint in openSprints() AND issuetype not in subtaskIssueTypes() AND status != Done"

DATA=$(timeout 10 curl -sf -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://api.atlassian.com/ex/jira/$JIRA_CLOUD_ID/rest/api/3/search/jql" \
  -X POST -H "Content-Type: application/json" \
  -d "{\"jql\":\"$JQL\",\"maxResults\":50,\"fields\":[\"summary\",\"status\"]}" \
  2>/dev/null)

COUNT=$(echo "$DATA" | jq '.issues | length' 2>/dev/null)
COUNT="${COUNT:-0}"

# Count actionable items (To Do or In Progress)
ACTIONABLE=$(echo "$DATA" | jq '[.issues[] | select(.fields.status.statusCategory.key == "new" or .fields.status.statusCategory.key == "indeterminate")] | length' 2>/dev/null)
ACTIONABLE="${ACTIONABLE:-0}"

if [ "$COUNT" -eq 0 ] 2>/dev/null; then
  echo "{\"text\": \"󰌃\", \"tooltip\": \"No Jira issues\", \"class\": \"empty\"}"
elif [ "$ACTIONABLE" -gt 0 ] 2>/dev/null; then
  echo "{\"text\": \"󰌃 ${COUNT}\", \"tooltip\": \"${ACTIONABLE} actionable / ${COUNT} total in sprint\", \"class\": \"active\"}"
else
  echo "{\"text\": \"󰌃 ${COUNT}\", \"tooltip\": \"${COUNT} issues (none actionable)\", \"class\": \"empty\"}"
fi
