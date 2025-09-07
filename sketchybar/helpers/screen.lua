local Screen = {}

-- Cache for screen properties (screen resolution doesn't change often)
local screen_cache = {
  width = nil,
  is_retina = nil,
  last_check = 0,
  cache_duration = 300  -- 5 minutes cache
}

-- Function to clear cache (useful for debugging)
function Screen.clear_cache()
  screen_cache.width = nil
  screen_cache.is_retina = nil
  screen_cache.last_check = 0
end

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

  -- Get all screen resolutions to find the largest (likely external monitor)
  local handle = io.popen("system_profiler SPDisplaysDataType | grep Resolution")
  local resolution_output = handle:read("*a")
  handle:close()

  local largest_width = 1440  -- Default fallback
  local is_retina = false

  -- Parse all resolution lines
  for line in resolution_output:gmatch("[^\r\n]+") do
    local width = line:match("Resolution: (%d+)")
    local line_is_retina = line:match("Retina") ~= nil
    
    if width then
      local screen_width = tonumber(width)
      
      -- If it's a Retina display, divide by 2 to get logical resolution
      if line_is_retina then
        screen_width = screen_width / 2
        Logger:debug('Retina detected for width ' .. width .. ', logical width: ' .. screen_width)
      end
      
      -- Use the largest screen (likely external monitor for better positioning)
      if screen_width > largest_width then
        largest_width = screen_width
        is_retina = line_is_retina
        Logger:debug('Found larger display: ' .. screen_width .. 'px' .. (line_is_retina and ' (Retina)' or ''))
      end
    end
  end

  local screen_width = largest_width

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

return Screen
