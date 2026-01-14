local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local Workspaces = {}

-- Helper to execute commands with callbacks
local function execute_command(command, callback)
  SketchyBar.exec(command, callback)
end


-- Update workspace windows and their icons
local function refresh_workspace_windows(workspace_name, is_focused)
  local command = string.format("aerospace list-windows --workspace %s --format '%%{app-name}' --json", workspace_name)
  execute_command(command, function(open_windows)
    local window_icons = {}
    for _, window in ipairs(open_windows or {}) do
      table.insert(window_icons, app_icons[window["app-name"]] or app_icons["Default"])
    end

    local has_apps = #open_windows > 0
    local should_show = has_apps or is_focused

    Workspaces[workspace_name]:set({
      icon = { drawing = should_show },
      label = {
        drawing = should_show,
        string = has_apps and table.concat(window_icons, " ") or "·"
      },
      padding_right = should_show and 2 or 0,
      padding_left = should_show and 2 or 0,
    })
  end)
end

-- Refresh all workspaces
local function refresh_all_workspaces(focused_workspace)
  for workspace_name, _ in pairs(Workspaces) do
    local is_focused = (focused_workspace == workspace_name)
    refresh_workspace_windows(workspace_name, is_focused)
  end
end

-- Retrieve AeroSpace spaces in a specific sequence
local function get_ordered_workspace_names(specified_order)
  specified_order = specified_order or {}

  -- Use timeout to prevent hang if aerospace is unresponsive
  local handle = io.popen("timeout 3 aerospace list-workspaces --all 2>/dev/null")
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
      workspace_item:subscribe("aerospace_focus_change", function(env)
        refresh_workspace_windows(workspace_name, workspace_name == env.FOCUSED_WORKSPACE)
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

        -- Refresh all workspaces to update visibility when windows move
        refresh_all_workspaces(env.FOCUSED_WORKSPACE)
      end)

      -- Initial refresh (will be updated after we know focused workspace)
      refresh_workspace_windows(workspace_name, false)
    end
  end
end


-----------------------
-- Main Initialization
-----------------------
initialize_workspaces({ "T" })

-- Set all workspace items to show on all displays
-- Use bash command to set display masks directly
for workspace_name, _ in pairs(Workspaces) do
  -- Set display bitmask to show on displays 1 and 2 (mask = 3 = 0b11)
  os.execute(string.format("sketchybar --set workspace.%s associated_display=1 associated_display=2", workspace_name))
end

-- Initial refresh with focused workspace
execute_command("aerospace list-workspaces --focused", function(focused_workspace)
  local focused_name = tostring(focused_workspace):gsub("%s+", "")
  refresh_all_workspaces(focused_name)
end)
