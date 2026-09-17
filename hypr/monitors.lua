-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

hl.env("GDK_SCALE", "2")

-- BenQ PD3225U above the Acer PM161QT portable touchscreen.
hl.monitor({ output = "DP-3", mode = "3840x2160@60", position = "0x0", scale = 1.75 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "auto-center-down", scale = 1.25 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

for workspace = 1, 5 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = "DP-3",
    default = workspace == 1,
  })
end

for workspace = 6, 10 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = "HDMI-A-1",
    default = workspace == 6,
  })
end
