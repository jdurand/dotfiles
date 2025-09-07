local icons = require("icons")

-- Padding item required because of bracket
SketchyBar.add("item", { width = 5 })

SketchyBar.add("item", {
  icon = {
    font = { size = 16.0 },
    string = icons.apple,
    padding_right = 0,
    padding_left = 8,
  },
  label = { drawing = false },
  padding_left = 1,
  padding_right = 1,
  click_script = "sketchybar --trigger toggle_menu"
})

-- Padding item required because of bracket
SketchyBar.add("item", { width = 7 })
