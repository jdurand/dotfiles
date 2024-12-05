local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

SketchyBar.add("item", "chevron", {
  display = "active",
  icon = { string = icons.chevron },
  label = { drawing = false }
})

local front_app = SketchyBar.add("item", "front_app", {
  display = "active",
  icon = { drawing = false },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
end)

front_app:subscribe("mouse.clicked", function(env)
  SketchyBar.trigger("swap_menus_and_spaces")
end)
