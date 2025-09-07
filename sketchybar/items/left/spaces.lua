local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}

for i = 1, 10, 1 do
  local space = SketchyBar.add("space", "space." .. i, {
    space = i,
    icon = {
      font = { family = settings.font.numbers },
      string = i,
      padding_left = 8,
      padding_right = 4,
      color = colors.with_alpha(colors.white, 0.6),
      highlight_color = colors.magenta,
    },
    label = {
      padding_right = 8,
      color = colors.with_alpha(colors.grey, 0.8),
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:14.0",
      y_offset = -1,
    },
    padding_right = 2,
    padding_left = 2,
    background = {
      drawing = false,
      height = 2,
      y_offset = -12,
      color = colors.transparent,
    },
    popup = { background = { border_width = 0, border_color = colors.transparent } }
  })

  spaces[i] = space

  SketchyBar.add("space", "space.padding." .. i, {
    space = i,
    script = "",
    width = 2,
  })

  local space_popup = SketchyBar.add("item", {
    position = "popup." .. space.name,
    padding_left= 5,
    padding_right= 0,
    background = {
      drawing = true,
      image = {
        corner_radius = 9,
        scale = 0.2
      }
    }
  })

  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    space:set({
      icon = {
        highlight = selected,
        color = selected and colors.magenta or colors.with_alpha(colors.white, 0.6)
      },
      label = {
        highlight = selected,
        color = selected and colors.white or colors.with_alpha(colors.grey, 0.8)
      },
      background = {
        drawing = selected,
        color = selected and colors.magenta or colors.transparent
      }
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "other" then
      space_popup:set({ background = { image = "space." .. env.SID } })
      space:set({ popup = { drawing = "toggle" } })
    else
      local op = (env.BUTTON == "right") and "--destroy" or "--focus"
      SketchyBar.exec("yabai -m space " .. op .. " " .. env.SID)
    end
  end)

  space:subscribe("mouse.exited", function(_)
    space:set({ popup = { drawing = false } })
  end)
end

local space_window_observer = SketchyBar.add("item", {
  drawing = false,
  updates = true,
})

local spaces_indicator = SketchyBar.add("item", {
  padding_left = 0,
  padding_right = 0,
  icon = {
    padding_left = 6,
    padding_right = 6,
    color = colors.with_alpha(colors.grey, 0.8),
    string = icons.switch.on,
    font = { size = 12.0 },
  },
  label = {
    width = 0,
    padding_left = 0,
    padding_right = 6,
    string = "Spaces",
    color = colors.with_alpha(colors.grey, 0.8),
    font = { size = 11.0 },
  },
  background = { drawing = false }
})

space_window_observer:subscribe("space_windows_change", function(env)
  local icon_line = ""
  local no_app = true
  for app, count in pairs(env.INFO.apps) do
    no_app = false
    local lookup = app_icons[app]
    local icon = ((lookup == nil) and app_icons["Default"] or lookup)
    icon_line = icon_line .. icon
  end

  if (no_app) then
    icon_line = " —"
  end
  SketchyBar.animate("tanh", 10, function()
    spaces[env.INFO.space]:set({ label = icon_line })
  end)
end)

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set({
    icon = currently_on and icons.switch.off or icons.switch.on
  })
end)

spaces_indicator:subscribe("mouse.entered", function(env)
  SketchyBar.animate("tanh", 30, function()
    spaces_indicator:set({
      icon = { color = colors.white },
      label = {
        width = "dynamic",
        color = colors.white
      }
    })
  end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
  SketchyBar.animate("tanh", 30, function()
    spaces_indicator:set({
      icon = { color = colors.with_alpha(colors.grey, 0.8) },
      label = {
        width = 0,
        color = colors.with_alpha(colors.grey, 0.8)
      }
    })
  end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  SketchyBar.trigger("swap_menus_and_spaces")
end)
