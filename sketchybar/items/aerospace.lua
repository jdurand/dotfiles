local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local Workspaces = {}

-- Map monitor IDs between AeroSpace and SketchyBar
local function sketchyBarMonitorId(monitor_id, total_monitors)
  return (total_monitors > 1 and monitor_id == 1) and 2 or (monitor_id == 2 and 1 or monitor_id)
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
        icon = { highlight = true },
        label = { highlight = true },
        background = { border_width = 2 },
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
      background = { drawing = has_apps },
      padding_right = has_apps and 1 or 0,
      padding_left = has_apps and 1 or 0,
    })

    logDebug("Workspace Windows Refreshed", workspace_name)
  end)
end

-- Initialize workspaces and setup SketchyBar placeholders
local function initializeWorkspaces()
  local workspace_names = {}
  local handle = io.popen("aerospace list-workspaces --all")

  if handle then
    for line in handle:lines() do
      table.insert(workspace_names, line)
    end
    handle:close()
  end

  for _, workspace_name in ipairs(workspace_names) do
    if not Workspaces[workspace_name] then
      local workspace_item = SketchyBar.add("item", "workspace."..workspace_name, {
        icon = {
          color = colors.white,
          highlight_color = colors.red,
          drawing = false,
          font = { family = settings.font.numbers },
          string = workspace_name,
          padding_left = 10,
          padding_right = 5,
        },
        label = {
          color = colors.grey,
          highlight_color = colors.white,
          font = "sketchybar-app-font:Regular:16.0",
          y_offset = -1,
          padding_right = 12,
        },
        background = {
          color = colors.bg1,
          border_width = 1,
          height = 28,
          border_color = colors.bg2,
        },
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
          icon = { highlight = is_focused },
          label = { highlight = is_focused },
          background = { border_width = is_focused and 2 or 0 },
        })
        refreshWorkspaceWindows(workspace_name)
        reassignWorkspaces()
      end)

      -- Initial refresh
      refreshWorkspaceWindows(workspace_name)
    end
  end
end


-------------------------
-- Workspace/Menu Change
-------------------------

MenuVisible = false

local function initializeMenuToggle()
  local spaces_indicator = SketchyBar.add("item", {
    padding_left = 5,
    padding_right = 0,
    icon = {
      padding_left = 8,
      padding_right = 9,
      color = colors.grey,
      string = icons.switch.off,
    },
    label = {
      width = 0,
      padding_left = 0,
      padding_right = 8,
      string = "Menu",
      color = colors.bg1,
    },
    background = {
      color = colors.with_alpha(colors.grey, 0.0),
      border_color = colors.with_alpha(colors.bg1, 0.0),
    }
  })

  spaces_indicator:subscribe("toggle_menu", function(env)
    spaces_indicator:set({
      icon = env.visible == 'on' and icons.switch.on or icons.switch.off
    })
  end)

  spaces_indicator:subscribe("mouse.entered", function()
    SketchyBar.animate("tanh", 30, function()
      spaces_indicator:set({
        background = {
          color = { alpha = 1.0 },
          border_color = { alpha = 1.0 },
        },
        icon = { color = colors.bg1 },
        label = { width = "dynamic" }
      })
    end)
  end)

  spaces_indicator:subscribe("mouse.exited", function()
    SketchyBar.animate("tanh", 30, function()
      spaces_indicator:set({
        background = {
          color = { alpha = 0.0 },
          border_color = { alpha = 0.0 },
        },
        icon = { color = colors.grey },
        label = { width = 0, }
      })
    end)
  end)

  spaces_indicator:subscribe("mouse.clicked", function()
    MenuVisible = not MenuVisible
    SketchyBar.trigger("toggle_menu", { visible = MenuVisible })
  end)
end

-----------------------
-- Main Initialization
-----------------------
initializeWorkspaces()
initializeMenuToggle()
reassignWorkspaces()
highlightFocusedWorkspace()

