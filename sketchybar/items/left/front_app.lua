local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local MAX_LENGTH = 9
local LABEL_WIDTH = 75

local function clean_app_name(name)
  local prefixes = {
    "Google ",
    "Microsoft ",
    "Adobe ",
    "Apple ",
  }

  local special_cases = {
    -- ["Google Chrome"] = "Chrome",
  }

  if special_cases[name] then
    return special_cases[name]
  end

  for _, prefix in ipairs(prefixes) do
    if name:sub(1, #prefix) == prefix then
      local words = {}
      for word in name:gmatch("%S+") do
        table.insert(words, word)
      end

      if #words > 1 then
        table.remove(words, 1)
        return table.concat(words, " ")
      end
    end
  end

  return name
end

local function truncate_name(name, max_length)
  local cleaned = clean_app_name(name)

  if #cleaned > max_length then
    return cleaned:sub(1, max_length - 1) .. "…"
  end

  return cleaned .. string.rep(" ", max_length - #cleaned)
end

local front_app = SketchyBar.add("item", "front_app", {
  position = "left",
  icon = {
    color = colors.magenta,
    drawing = true,
    font = "sketchybar-app-font:Regular:15.0",
    string = "·",
    width = 20,
  },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
    width = LABEL_WIDTH,
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  local app_name = env.INFO
  local app_icon = app_icons[app_name] or "·"
  local display_name = truncate_name(app_name, MAX_LENGTH)

  front_app:set({
    label = { string = display_name },
    icon = { string = app_icon, drawing = true }
  })
end)

front_app:subscribe("mouse.clicked", function()
  SketchyBar.trigger("toggle_menu")
end)
