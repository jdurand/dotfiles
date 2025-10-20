local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local Workspaces = {}

-- Auto-detect if we need to swap monitor IDs based on monitor configuration
local function should_swap_monitor_ids()
  -- Get all monitors with their AppKit screen IDs and names from aerospace
  -- AppKit screen ID represents macOS's internal display ordering
  -- Related issue: https://github.com/nikitabobko/AeroSpace/issues/1656
  local handle = io.popen("aerospace list-monitors --format '%{monitor-id}:%{monitor-appkit-nsscreen-screens-id}:%{monitor-name}' 2>/dev/null")
  if not handle then return false end

  local monitors = {}
  for line in handle:lines() do
    local aerospace_id, appkit_id, name = line:match("^(%d+):(%d+):(.+)$")
    if aerospace_id and appkit_id then
      monitors[tonumber(aerospace_id)] = {
        appkit_id = tonumber(appkit_id),
        name = name
      }
    end
  end
  handle:close()

  -- If we only have one monitor, no swapping needed
  local monitor_count = 0
  for _ in pairs(monitors) do monitor_count = monitor_count + 1 end
  if monitor_count <= 1 then return false end

  -- Check if AeroSpace and SketchyBar have mismatched monitor ordering
  -- SketchyBar typically follows macOS AppKit ordering where the main display has a lower ID
  -- If AeroSpace monitor 1 has a higher AppKit ID than monitor 2, we need to swap
  if monitors[1] and monitors[2] then
    return monitors[1].appkit_id > monitors[2].appkit_id
  end

  -- Default to no swapping if we can't detect
  return false
end

-- Map monitor IDs between AeroSpace and SketchyBar
local function sketchybar_monitor_id(monitor_id, total_monitors)
  if not should_swap_monitor_ids() then
    return monitor_id
  end
  return (total_monitors > 1 and monitor_id == 1) and 2 or (monitor_id == 2 and 1 or monitor_id)
end

-- Helper to execute commands with callbacks
local function execute_command(command, callback)
  SketchyBar.exec(command, callback)
end

-- Log debug messages with consistent formatting
local function log_debug(message, value)
  print(string.format("%s: %s", message, tostring(value or "nil")))
end

-- Highlight the focused workspace on startup
local function highlight_focused_workspace()
  execute_command("aerospace list-workspaces --focused", function(focused_workspace)
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

      log_debug("Focused Workspace Highlighted", focused_name)
    end
  end)
end

-- Reassign workspaces to monitors
local function reassign_workspaces()
  local query = "aerospace list-workspaces --all --format '%{workspace}%{monitor-id}%{monitor-name}' --json"
  execute_command(query, function(workspaces_data)
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
      local mapped_monitor_id = sketchybar_monitor_id(monitor_id, total_monitors)

      -- Assign workspace to the appropriate monitor
      Workspaces[workspace_name]:set({ display = mapped_monitor_id })
      log_debug("Workspace Assigned", string.format("%s -> %s", workspace_name, monitor_name))
    end
  end)
end

-- Update workspace windows and their icons
local function refresh_workspace_windows(workspace_name)
  local command = string.format("aerospace list-windows --workspace %s --format '%%{app-name}' --json", workspace_name)
  execute_command(command, function(open_windows)
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

    log_debug("Workspace Windows Refreshed", workspace_name)
  end)
end

-- Retrieve AeroSpace spaces in a specific sequence
local function get_ordered_workspace_names(specified_order)
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
local function initialize_workspaces(specified_order)
  for _, workspace_name in ipairs(get_ordered_workspace_names(specified_order)) do
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
      workspace_item:subscribe("aerospace_focus_change", function()
        refresh_workspace_windows(workspace_name)
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
      end)

      -- Initial refresh
      refresh_workspace_windows(workspace_name)
    end
  end
end


-----------------------
-- Main Initialization
-----------------------
initialize_workspaces({ "T" })
reassign_workspaces()
highlight_focused_workspace()
