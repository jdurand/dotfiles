local settings = require("settings")
local colors = require("colors")

SketchyBar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Medium"],
      size = 13.0
    },
    color = colors.white,
    padding_left = 4,
    padding_right = 4,
    background = {
      drawing = false,
    },
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Medium"],
      size = 13.0
    },
    color = colors.white,
    padding_left = 4,
    padding_right = 4,
  },
  background = {
    drawing = false,
  },
  popup = {
    background = {
      border_width = 0,
      corner_radius = 8,
      border_color = colors.transparent,
      color = colors.with_alpha(colors.bar.bg, 0.9),
      shadow = { drawing = true },
    },
    blur_radius = 50,
  },
  padding_left = 6,
  padding_right = 6,
  scroll_texts = true,
})
