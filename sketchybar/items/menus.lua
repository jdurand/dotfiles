local colors = require("colors")
local settings = require("settings")

MenuVisible = false

-------------------------
-- Menu
-------------------------

local function initializeMenu()
  local menu_watcher = SketchyBar.add("item", {
    drawing = false,
    updates = false,
  })
  local menu_placeholder = SketchyBar.add("item", {
    drawing = false,
    updates = true,
  })

  SketchyBar.add("event", "toggle_menu")

  local max_items = 15
  local menu_items = {}
  for i = 1, max_items, 1 do
    local menu = SketchyBar.add("item", "menu." .. i, {
      padding_left = settings.paddings,
      padding_right = settings.paddings,
      drawing = false,
      icon = { drawing = false },
      label = {
        font = {
          style = settings.font.style_map["Semibold"]
        },
        padding_left = 6,
        padding_right = 6,
      },
      click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i + 1,
    })

    menu_items[i] = menu
  end

  SketchyBar.add("bracket", { '/menu\\..*/' }, {
    background = { color = colors.bg1, corner_radius = 9 }
  })

  local menu_padding = SketchyBar.add("item", "menu.padding", {
    drawing = false,
    width = 5
  })

  local function update_menus(env)
    SketchyBar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
      SketchyBar.set('/menu\\..*/', { drawing = false })
      menu_padding:set({ drawing = true })
      id = 1
      local skip_first = true
      for menu in string.gmatch(menus, '[^\r\n]+') do
        if skip_first then
          skip_first = false
        elseif id < max_items then
          menu_items[id]:set( { label = menu, drawing = true } )
          id = id + 1
        else break end
      end
    end)
  end

  menu_watcher:subscribe("front_app_switched", update_menus)

  menu_placeholder:subscribe("toggle_menu", function(env)
    MenuVisible = not MenuVisible

    menu_watcher:set( { updates = MenuVisible })
    SketchyBar.set("/menu\\..*/", { drawing = MenuVisible })
    SketchyBar.set("/space\\..*/", { drawing = not MenuVisible })
    SketchyBar.set("/workspace\\..*/", { drawing = not MenuVisible })

    if MenuVisible then update_menus() end
  end)
end


-----------------------
-- Main Initialization
-----------------------
initializeMenu()

