local colors = require("colors")
local settings = require("settings")

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
        style = settings.font.style_map[i == 1 and "Heavy" or "Semibold"]
      },
      padding_left = 6,
      padding_right = 6,
    },
    click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
  })

  menu_items[i] = menu
end

SketchyBar.add("bracket", { '/menu\\..*/' }, {
  background = { color = colors.bg1 }
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
    for menu in string.gmatch(menus, '[^\r\n]+') do
      if id < max_items then
        menu_items[id]:set( { label = menu, drawing = true } )
      else break end
      id = id + 1
    end
  end)
end

menu_watcher:subscribe("front_app_switched", update_menus)

menu_placeholder:subscribe("toggle_menu", function(env)
  local menu_visible = env.visible == 'on'

  menu_watcher:set( { updates = menu_visible })
  SketchyBar.set("/menu\\..*/", { drawing = menu_visible })
  SketchyBar.set("/space\\..*/", { drawing = not menu_visible })
  SketchyBar.set("front_app", { drawing = not menu_visible })

  if menu_visible then update_menus() end
end)

return menu_watcher
