local settings = require("settings")
local colors = require("colors")

local cal = SketchyBar.add("item", "calendar", {
  icon = {
    color = colors.white,
    padding_left = 8,
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 8,
    width = 49,
    align = "right",
    font = { family = settings.font.numbers },
  },
  position = "right",
  update_freq = 30,
  padding_left = 1,
  padding_right = 5,
})

-- Update function
local function update_calendar()
  cal:set({ icon = os.date("%a %d %b"), label = os.date("%H:%M") })
end

-- Initial update
update_calendar()

-- Subscribe to events
cal:subscribe({ "forced", "routine", "system_woke" }, update_calendar)
