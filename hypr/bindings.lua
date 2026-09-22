-- Restore legacy overrides that intentionally replace Omarchy defaults.
for _, keys in ipairs({
  "SUPER + G", "SUPER + O", "SUPER + P", "SUPER + J", "SUPER + K",
  "SUPER + BACKSPACE", "SUPER + comma", "SUPER + TAB", "SUPER + W",
  "SUPER + SPACE", "SUPER + SHIFT + comma", "SUPER + code:20",
  "SUPER + code:21", "SUPER + L", "SUPER + CTRL + L", "SUPER + F",
  "SUPER + SLASH", "SUPER + SHIFT + B", "SUPER + SHIFT + E",
  "SUPER + SHIFT + G", "SUPER + SHIFT + SLASH", "SUPER + SHIFT + CTRL + G",
}) do
  hl.unbind(keys)
end
hl.unbind("F9")

o.bind("SUPER + SUPER_L", "Launch apps", "omarchy-menu toggle apps", { release = true })
o.bind("SUPER + O", "Omarchy menu", "omarchy-menu toggle root")
o.bind("SUPER + GRAVE", "Ghostty terminal", { launch = "ghostty", focus = "com.mitchellh.ghostty" })
o.bind("SUPER + BACKSPACE", "Close window", hl.dsp.window.close())
o.bind("SUPER + F", "Cycle fullscreen (maximize/full/normal)", "hypr-fullscreen-cycle")
o.bind("SUPER + comma", "Toggle floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + PERIOD", "Toggle layout (dwindle/scrolling)", "hypr-layout-toggle")
o.bind("SUPER + SLASH", "Pseudo tile", hl.dsp.window.pseudo())
o.bind("SUPER + SHIFT + SLASH", "Show keybindings", "omarchy-menu-keybindings")

o.bind("SUPER + H", "Move focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Move focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Move focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Move focus right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + CTRL + H", "Previous workspace", "hypr-workspace-cycle prev")
o.bind("SUPER + CTRL + L", "Next workspace", "hypr-workspace-cycle next")
o.bind("SUPER + CTRL + K", "Focus monitor above", hl.dsp.focus({ monitor = "u" }))
o.bind("SUPER + CTRL + J", "Focus monitor below", hl.dsp.focus({ monitor = "d" }))
o.bind("SUPER + CTRL + SHIFT + H", "Move window to previous workspace", "hypr-workspace-cycle prev move")
o.bind("SUPER + CTRL + SHIFT + L", "Move window to next workspace", "hypr-workspace-cycle next move")
o.bind("SUPER + CTRL + SHIFT + K", "Move window to monitor above", hl.dsp.window.move({ monitor = "u" }))
o.bind("SUPER + CTRL + SHIFT + J", "Move window to monitor below", hl.dsp.window.move({ monitor = "d" }))
o.bind("SUPER + CTRL + ALT + K", "Move workspace to monitor above", hl.dsp.workspace.move({ monitor = "u" }))
o.bind("SUPER + CTRL + ALT + J", "Move workspace to monitor below", hl.dsp.workspace.move({ monitor = "d" }))

o.bind("SUPER + ALT + H", "Resize window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + ALT + J", "Resize window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
o.bind("SUPER + ALT + K", "Resize window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + ALT + L", "Resize window right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

o.bind("SUPER + A", "Select all", hl.dsp.send_shortcut({ mods = "CTRL", key = "A" }))
o.bind("SUPER + W", "Close tab", hl.dsp.send_shortcut({ mods = "CTRL", key = "W" }))
o.bind("SUPER + Z", "Undo", hl.dsp.send_shortcut({ mods = "CTRL", key = "Z" }))
o.bind("SUPER + TAB", "Previous workspace", hl.dsp.focus({ workspace = "previous" }))

o.bind("SUPER + E", "Switch to workspace 3", hl.dsp.focus({ workspace = "3" }))
o.bind("SUPER + Y", "Switch to workspace 4", hl.dsp.focus({ workspace = "4" }))
o.bind("SUPER + G", "Switch to workspace 5", hl.dsp.focus({ workspace = "5" }))
o.bind("SUPER + B", "Switch to workspace 6", hl.dsp.focus({ workspace = "6" }))
o.bind("SUPER + M", "Switch to workspace 7", hl.dsp.focus({ workspace = "7" }))
o.bind("SUPER + SHIFT + E", "Move window to workspace 3", hl.dsp.window.move({ workspace = "3" }))
o.bind("SUPER + SHIFT + Y", "Move window to workspace 4", hl.dsp.window.move({ workspace = "4" }))
o.bind("SUPER + SHIFT + G", "Move window to workspace 5", hl.dsp.window.move({ workspace = "5" }))
o.bind("SUPER + SHIFT + B", "Move window to workspace 6", hl.dsp.window.move({ workspace = "6" }))

o.bind("SUPER + SHIFT + CTRL + G", "Google Chat", { webapp = "https://chat.google.com/", focus = true })
local globe_held = false
o.bind("ISO_Next_Group", "Dictation", function() end)
o.bind("ISO_Next_Group", "Start dictation (push-to-talk)", function()
  globe_held = true
  hl.dispatch(hl.dsp.exec_cmd("voxtype record start"))
end, { long_press = true })
o.bind("ISO_Next_Group", "Stop or toggle dictation", function()
  if globe_held then
    globe_held = false
    hl.dispatch(hl.dsp.exec_cmd("voxtype record stop"))
  else
    hl.dispatch(hl.dsp.exec_cmd("voxtype record toggle"))
  end
end, { release = true })
o.bind("F9", "Dictation", function() end)
o.bind("F9", "Start dictation (push-to-talk)", function()
  globe_held = true
  hl.dispatch(hl.dsp.exec_cmd("voxtype record start"))
end, { long_press = true })
o.bind("F9", "Stop or toggle dictation", function()
  if globe_held then
    globe_held = false
    hl.dispatch(hl.dsp.exec_cmd("voxtype record stop"))
  else
    hl.dispatch(hl.dsp.exec_cmd("voxtype record toggle"))
  end
end, { release = true })
o.bind("SUPER + EQUAL", "Zoom in", "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.1}')")
o.bind("SUPER + MINUS", "Zoom out", "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.9}')")
o.bind("SUPER + KP_ADD", "Zoom in (numpad)", "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.1}')")
o.bind("SUPER + KP_SUBTRACT", "Zoom out (numpad)", "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.9}')")
o.bind("SUPER + SHIFT + MINUS", "Reset zoom", "hyprctl -q keyword cursor:zoom_factor 1")
o.bind("SUPER + KP_0", "Reset zoom (numpad)", "hyprctl -q keyword cursor:zoom_factor 1")
