local colors = require("colors")
local settings = require("settings")
local Terminal = require("helpers.terminal")

-- Configuration constants
local CONFIG = {
  REFRESH_INTERVAL = 1500, -- 15 minutes in seconds
  JIRA_SCRIPT = os.getenv("HOME") .. "/.dotfiles/scripts/jira-issues",
  JIRA_COLUMNS = 'key,summary,status,updated',
  TUI_WIDTH = "130c",
  TUI_HEIGHT = "30c",
}

-- Jira Issues Widget
local jira_issues = SketchyBar.add("item", "widgets.jira_issues", {
  position = "right",
  icon = {
    string = "􀈭", -- list.bullet - represents tasks/issues
    color = colors.blue,
  },
  label = {
    string = "0 issues",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.white,
  },
  background = {
    height = 22,
    color = { alpha = 0 },
    border_color = { alpha = 0 },
  },
  padding_right = settings.paddings,
  drawing = false, -- Initially hidden
})

-- Add padding item to separate from other widgets
SketchyBar.add("item", "widgets.jira_issues.padding", {
  position = "right",
  width = 2
})

-- Jira CLI command to fetch issues
local function fetch_jira_issues(callback)
  SketchyBar.exec(CONFIG.JIRA_SCRIPT .. " --count", callback)
end

-- Function to update Jira issues count
local function update_jira_issues()
  fetch_jira_issues(function(result)
    local result_clean = result and result:gsub("%s+", "") or "0"
    local count = tonumber(result_clean) or 0

    jira_issues:set({
      label = count .. (count == 1 and " issue" or " issues"),
      drawing = count > 0,
    })
  end)
end

-- Use the Terminal helper to show up the Jira issues list in a TUI
local click_script = Terminal.get_floating_tui_click_script(CONFIG.JIRA_SCRIPT, {
  width_cols = CONFIG.TUI_WIDTH,
  height_rows = CONFIG.TUI_HEIGHT,
  args = "--interactive --columns '" .. CONFIG.JIRA_COLUMNS .. "'"
})

-- Expand $TMPDIR if needed
if click_script and click_script:match("^%$TMPDIR") then
  click_script = click_script:gsub("^%$TMPDIR", os.getenv("TMPDIR"))
end

jira_issues:set({
  click_script = click_script
})

-- Set up periodic updates
SketchyBar.add("event", "jira_issues_update")
SketchyBar.exec(string.format("while true; do sleep %d; /opt/homebrew/bin/sketchybar --trigger jira_issues_update; done &", CONFIG.REFRESH_INTERVAL))

jira_issues:subscribe("jira_issues_update", update_jira_issues)

-- Initial update
update_jira_issues()
