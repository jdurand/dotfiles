local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spacer = SketchyBar.add("item", "front_app_spacer", {
  display = "active",
  icon = { string = icons.chevron },
  label = { drawing = false },
  padding_left = 10,
  padding_right = 5
})

local front_app = SketchyBar.add("item", "front_app", {
  display = "active",
  icon = {
    color = colors.magenta,
    drawing = false,
    font = "sketchybar-app-font:Regular:18.0",
  },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  local app_name = env.INFO
  local app_icon = app_icons[app_name]

  front_app:set({ label = { string = app_name } })

  if app_icon then
    front_app:set({ icon = { string = app_icon, drawing = true }})
  else
    front_app:set({ icon = { drawing = false }})
  end
end)

front_app:subscribe("mouse.clicked", function()
  SketchyBar.trigger("toggle_menu", { visible = true })
end)

spacer:subscribe("toggle_menu", function(env)
  spacer:set({ icon = { drawing = env.visible == 'on' and 'off' or 'on' } })
end)
