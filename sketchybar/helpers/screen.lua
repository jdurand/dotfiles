local Screen = {}

-- Cache for screen properties (screen resolution doesn't change often)
local screen_cache = {
  width = nil,
  is_retina = nil,
  last_check = 0,
  cache_duration = 300  -- 5 minutes cache
}

-- Detect screen properties and cache results
function Screen.get_properties()
  local current_time = os.time()

  -- Return cached properties if still valid
  if screen_cache.width and screen_cache.is_retina and
     (current_time - screen_cache.last_check) < screen_cache.cache_duration then
    Logger:debug('Using cached screen properties: ' .. screen_cache.width .. 'px, retina: ' .. tostring(screen_cache.is_retina))
    return {
      width = screen_cache.width,
      is_retina = screen_cache.is_retina
    }
  end

  Logger:debug('Detecting screen resolution...')

  -- Get screen resolution to determine monitor size
  local handle = io.popen("system_profiler SPDisplaysDataType | grep Resolution | head -1")
  local resolution = handle:read("*a")
  handle:close()

  -- Extract width from resolution string (e.g., "Resolution: 2560 x 1440" or "Resolution: 3024 x 1964 Retina")
  local width = resolution:match("Resolution: (%d+)")
  local is_retina = resolution:match("Retina") ~= nil
  local screen_width = 1440  -- Default fallback

  if width then
    screen_width = tonumber(width)

    -- If it's a Retina display, divide by 2 to get logical resolution
    if is_retina then
      screen_width = screen_width / 2
      Logger:debug('Retina detected, logical width: ' .. screen_width)
    end
  end

  -- Cache the results
  screen_cache.width = screen_width
  screen_cache.is_retina = is_retina
  screen_cache.last_check = current_time

  Logger:info('Screen properties detected and cached: ' .. screen_width .. 'px, retina: ' .. tostring(is_retina))

  return {
    width = screen_width,
    is_retina = is_retina
  }
end

-- Get optimal position for widgets based on screen size
function Screen.get_widget_position()
  local props = Screen.get_properties()

  -- 27" monitors typically have logical width >= 2560 (QHD) or >= 1920 (4K scaled)
  -- Laptops are usually 1440 (MacBook Pro) or lower
  if props.width >= 1920 then
    Logger:info('Large monitor detected, Spotify using center position')
    return 'center'
  else
    Logger:info('Small screen detected, Spotify using right position (left of system widgets)')
    return 'right'
  end
end

return Screen