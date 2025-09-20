local colors = require("colors")
local settings = require("settings")
local Timer = require("helpers.timer")
local Terminal = require("helpers.terminal")

-- Configuration constants
local CONFIG = {
  REFRESH_INTERVAL = 30, -- 30 seconds
  DOCKER_SCRIPT = os.getenv("HOME") .. "/.dotfiles/scripts/docker-containers",
  TUI_WIDTH = "175c",
  TUI_HEIGHT = "50c",
  YELLOW_THRESHOLD = 4,  -- Show yellow when more than 4 containers
  ORANGE_THRESHOLD = 8,  -- Show orange when more than 8 containers
}

-- Docker Containers Widget
local docker_containers = SketchyBar.add("item", "widgets.docker_containers", {
  position = "right",
  icon = {
    string = "󰡨",
    color = colors.blue,
  },
  label = {
    string = "0 up",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = colors.white,
  },
  background = {
    height = 22,
    color = { alpha = 0 },
    border_color = { alpha = 0 },
  },
  padding_right = settings.paddings,
  drawing = false, -- Initially hidden
})

-- Add padding item to separate from other widgets
SketchyBar.add("item", "widgets.docker_containers.padding", {
  position = "right",
  width = 2
})

-- Docker command to fetch container count
local function fetch_docker_containers(callback)
  SketchyBar.exec(CONFIG.DOCKER_SCRIPT .. " --count", callback)
end

-- Function to update Docker containers count
local function update_docker_containers()
  fetch_docker_containers(function(result)
    local result_clean = result and result:gsub("%s+", "") or "0"
    local count = tonumber(result_clean) or 0

    -- Update color based on container count
    local icon_color = colors.blue
    if count > CONFIG.YELLOW_THRESHOLD then
      icon_color = colors.yellow
    elseif count > CONFIG.ORANGE_THRESHOLD then
      icon_color = colors.orange
    end

    docker_containers:set({
      icon = { color = icon_color },
      label = count .. " up",
      drawing = count > 0,
    })
  end)
end

-- Use the Terminal helper to show Docker containers in a TUI
local click_script = Terminal.get_floating_tui_click_script("lazydocker", {
  width_cols = CONFIG.TUI_WIDTH,
  height_rows = CONFIG.TUI_HEIGHT,
})

-- Fallback to docker-containers script if lazydocker is not available
if not click_script or click_script == "" then
  click_script = Terminal.get_floating_tui_click_script(CONFIG.DOCKER_SCRIPT, {
    width_cols = CONFIG.TUI_WIDTH,
    height_rows = CONFIG.TUI_HEIGHT,
    args = "--interactive"
  })
end

-- Expand $TMPDIR if needed
if click_script and click_script:match("^%$TMPDIR") then
  click_script = click_script:gsub("^%$TMPDIR", os.getenv("TMPDIR"))
end

docker_containers:set({
  click_script = click_script
})

-- Set up managed timer with automatic sleep/wake handling
Timer.create({
  item = docker_containers,
  name = "docker_containers_update",
  interval = CONFIG.REFRESH_INTERVAL,
  on_wake = function()
    -- Trigger immediate update after wake
    update_docker_containers()
  end
})

-- Subscribe to timer event
docker_containers:subscribe("docker_containers_update", update_docker_containers)

-- Initial update
update_docker_containers()
