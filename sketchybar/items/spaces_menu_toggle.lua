local colors = require("colors")
local icons = require("icons")

MenuVisible = false

-------------------------
-- Workspace/Menu Change
-------------------------

local function initializeMenuToggle()
  local spaces_indicator = SketchyBar.add("item", {
    padding_left = 0,
    padding_right = 5,
    icon = {
      padding_left = 8,
      padding_right = 9,
      color = colors.grey,
      string = icons.switch.off,
    },
    label = {
      width = 0,
      padding_left = 0,
      padding_right = 12,
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
initializeMenuToggle()

