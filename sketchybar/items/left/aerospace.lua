local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local Workspaces = {}

-- Map monitor IDs between AeroSpace and SketchyBar
local function sketchyBarMonitorId(monitor_id, total_monitors)
  return monitor_id
end

-- Helper to execute commands with callbacks
local function executeCommand(command, callback)
  SketchyBar.exec(command, callback)
end

-- Log debug messages with consistent formatting
local function logDebug(message, value)
  print(string.format("%s: %s", message, tostring(value or "nil")))
end

-- Highlight the focused workspace on startup
local function highlightFocusedWorkspace()
  executeCommand("aerospace list-workspaces --focused", function(focused_workspace)
    local focused_name = tostring(focused_workspace):gsub("%s+", "")

    if focused_name and Workspaces[focused_name] then
      Workspaces[focused_name]:set({
        icon = {
          highlight = true,
          color = colors.magenta
        },
        label = {
          highlight = true,
          color = colors.white
        },
        background = {
          drawing = true,
          color = colors.magenta
        }
      })

      logDebug("Focused Workspace Highlighted", focused_name)
    end
  end)
end

-- Reassign workspaces to monitors
local function reassignWorkspaces()
  local query = "aerospace list-workspaces --all --format '%{workspace}%{monitor-id}%{monitor-name}' --json"
  executeCommand(query, function(workspaces_data)
    local monitor_count = {} -- Count monitor occurrences
    for _, data in ipairs(workspaces_data or {}) do
      local monitor_id = tonumber(data["monitor-id"]) or 1
      monitor_count[monitor_id] = (monitor_count[monitor_id] or 0) + 1
    end

    local total_monitors = #monitor_count

    for _, data in ipairs(workspaces_data or {}) do
      local workspace_name = tostring(data["workspace"])
      local monitor_id = tonumber(data["monitor-id"])
      local monitor_name = data["monitor-name"]
      local mapped_monitor_id = sketchyBarMonitorId(monitor_id, total_monitors)

      -- Assign workspace to the appropriate monitor
      Workspaces[workspace_name]:set({ display = mapped_monitor_id })
      logDebug("Workspace Assigned", string.format("%s -> %s", workspace_name, monitor_name))
    end
  end)
end

-- Update workspace windows and their icons
local function refreshWorkspaceWindows(workspace_name)
  local command = string.format("aerospace list-windows --workspace %s --format '%%{app-name}' --json", workspace_name)
  executeCommand(command, function(open_windows)
    local window_icons = {}
    for _, window in ipairs(open_windows or {}) do
      table.insert(window_icons, app_icons[window["app-name"]] or app_icons["Default"])
    end

    local has_apps = #open_windows > 0
    Workspaces[workspace_name]:set({
      icon = { drawing = has_apps },
      label = { drawing = has_apps, string = table.concat(window_icons, " ") },
      padding_right = has_apps and 2 or 0,
      padding_left = has_apps and 2 or 0,
    })

    logDebug("Workspace Windows Refreshed", workspace_name)
  end)
end

-- Retrieve AeroSpace spaces in a specific sequence
local function getOrderedWorkspaceNames(specified_order)
  specified_order = specified_order or {}

  local handle = io.popen("aerospace list-workspaces --all")
  local workspace_names = {}
  if handle then
    for line in handle:lines() do
      table.insert(workspace_names, line)
    end
    handle:close()
  end

  local specified_set = {}
  for _, name in ipairs(specified_order) do
    specified_set[name] = true
  end

  local specified_names, other_names = {}, {}
  for _, workspace_name in ipairs(workspace_names) do
    table.insert(specified_set[workspace_name] and specified_names or other_names, workspace_name)
  end

  table.sort(other_names)

  local ordered_workspaces = {}
  for _, name in ipairs(specified_order) do
    if specified_set[name] then
      table.insert(ordered_workspaces, name)
    end
  end

  for _, name in ipairs(other_names) do
    table.insert(ordered_workspaces, name)
  end

  return ordered_workspaces
end

-- Initialize workspaces and setup SketchyBar placeholders
local function initializeWorkspaces(specified_order)
  for _, workspace_name in ipairs(getOrderedWorkspaceNames(specified_order)) do
    if not Workspaces[workspace_name] then
      local workspace_item = SketchyBar.add("item", "workspace." .. workspace_name, {
        icon = {
          color = colors.with_alpha(colors.white, 0.6),
          highlight_color = colors.magenta,
          drawing = false,
          font = { family = settings.font.numbers, size = 12.0 },
          string = workspace_name,
          padding_left = 6,
          padding_right = 3,
        },
        label = {
          color = colors.with_alpha(colors.grey, 0.8),
          highlight_color = colors.white,
          font = "sketchybar-app-font:Regular:14.0",
          y_offset = -1,
          padding_right = 6,
        },
        background = {
          drawing = false,
          height = 2,
          y_offset = -12,
          color = colors.transparent,
        },
        padding_right = 1,
        padding_left = 1,
        click_script = "aerospace workspace " .. workspace_name,
      })

      Workspaces[workspace_name] = workspace_item

      -- Subscribe to AeroSpace events
      workspace_item:subscribe("display_change", function()
        refreshWorkspaceWindows(workspace_name)
        reassignWorkspaces()
      end)

      workspace_item:subscribe("aerospace_focus_change", function()
        refreshWorkspaceWindows(workspace_name)
      end)

      workspace_item:subscribe("aerospace_workspace_change", function(env)
        local is_focused = env.FOCUSED_WORKSPACE == workspace_name

        workspace_item:set({
          icon = {
            highlight = is_focused,
            color = is_focused and colors.magenta or colors.with_alpha(colors.white, 0.6)
          },
          label = {
            highlight = is_focused,
            color = is_focused and colors.white or colors.with_alpha(colors.grey, 0.8)
          },
          background = {
            drawing = is_focused,
            color = is_focused and colors.magenta or colors.transparent
          }
        })
        refreshWorkspaceWindows(workspace_name)
        reassignWorkspaces()
      end)

      -- Initial refresh
      refreshWorkspaceWindows(workspace_name)
    end
  end
end


-----------------------
-- Main Initialization
-----------------------
initializeWorkspaces({ "T" })
reassignWorkspaces()
highlightFocusedWorkspace()
