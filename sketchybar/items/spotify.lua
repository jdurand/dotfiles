local icons = require("icons")
local colors = require("colors")

-- Subscribe to event changes from Spotify
SketchyBar.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")

-- Constants
local IDLE_DELAY = 300 -- 5 minutes (300 seconds)

-- Debug configuration - set to false to disable all debug logging
local DEBUG_ENABLED = true
local DEBUG_FILE = "/tmp/spotify_debug.log"

local function debug_log(message)
  if DEBUG_ENABLED then
    os.execute("echo '" .. message .. "' >> " .. DEBUG_FILE)
  end
end

local function debug_log_table(title, tbl)
  if DEBUG_ENABLED then
    local debug_file = io.open(DEBUG_FILE, "a")
    if debug_file then
      debug_file:write("=== " .. title .. " ===\n")
      debug_file:write("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
      for k, v in pairs(tbl) do
        debug_file:write(tostring(k) .. " = " .. tostring(v) .. "\n")
      end
      debug_file:write("========================\n\n")
      debug_file:close()
    end
  end
end

-- State tracking for delayed hide
local last_pause_time = nil
local hide_timer_running = false

local widget_position = function()
  -- TODO: center on 27" monitors, right-align on laptops
  return 'right'
end

-- Setup bar widget
local media_title = SketchyBar.add("item", "spotify.title", {
  icon = { drawing = false },
  label = {
    color = colors.white,
    font = { size = 12 },
    max_chars = 20,
  },
  position = widget_position(),
})

local media_artist = SketchyBar.add("item", "spotify.artist", {
  icon = { drawing = false },
  label = {
    string = "",
    color = colors.with_alpha(colors.white, 0.6),
    font = { size = 10 },
    max_chars = 18,
  },
  position = widget_position(),
  drawing = false,
  padding_left = 5,
})

local media_cover = SketchyBar.add("item", "spotify.cover", {
  background = {
    image = {
      string = "media.artwork",
      scale = 0.9,
    },
    color = colors.with_alpha(colors.grey, 0.3),  -- Fallback background
    corner_radius = 6,
  },
  label = { drawing = false },
  icon = { drawing = false },
  position = widget_position(),
  drawing = false,
  width = 32,
  height = 32,
  popup = {
    align = "center",
    horizontal = true,
  }
})

local function hide_widgets()
  media_title:set({ label = { string = "" } })
  media_artist:set({ label = { string = "" } })
  media_cover:set({ drawing = false })
  debug_log('Widgets hidden after idle time')
end

local function schedule_delayed_hide()
  if hide_timer_running then
    return -- Timer already running
  end

  hide_timer_running = true
  last_pause_time = os.time()

  debug_log('Scheduled hide timer for idle time')

  -- Use SketchyBar's delay function to schedule hide after hide delay has passed
  SketchyBar.delay(IDLE_DELAY, function()
    hide_timer_running = false
    -- Only hide if we're still paused and haven't received a new event
    if last_pause_time and (os.time() - last_pause_time) >= IDLE_DELAY then
      hide_widgets()
    end
  end)
end

local function update_media(env)
  -- Wrap entire function in pcall to prevent crashes
  local success, err = pcall(function()
    -- Debug: Always log that function was called - use >> to append, not overwrite
    debug_log('Function called at ' .. os.date('%H:%M:%S'))

    -- Debug: Log all event data
    debug_log_table("Spotify Event Received", env)
    if env.INFO then
      debug_log_table("INFO Contents", env.INFO)
    else
      debug_log("INFO is nil or empty")
    end

  if env.INFO then
    -- Access Lua table fields directly with error handling
    local player_state = env.INFO["Player State"] or ""
    local track_name = env.INFO["Name"] or "Unknown Title"
    local artist_name = env.INFO["Artist"] or "Unknown Artist"
    local has_artwork = env.INFO["Has Artwork"] or false

    -- Debug: Log the parsed state and decision
    local spotify_artwork = env.INFO["Artwork URL"] or env.INFO["artwork"] or env.INFO["Artwork"] or "not found"
    debug_log("Player State: '" .. tostring(player_state) .. "'")
    debug_log("Track: " .. tostring(track_name))
    debug_log("Artist: " .. tostring(artist_name))
    debug_log("Has Artwork: " .. tostring(has_artwork))
    debug_log("Spotify Event Artwork: " .. tostring(spotify_artwork))

    local is_playing = (player_state == "Playing")

    if is_playing then
      -- Cancel any pending hide timer
      last_pause_time = nil
      hide_timer_running = false

      -- Wrap in pcall to catch any errors
      local success, err = pcall(function()
        debug_log('SHOWING widgets - state is: ' .. tostring(player_state))
        media_title:set({
          drawing = true,
          label = {
            string = track_name,
            color = colors.white,  -- Full brightness when playing
          }
        })

        media_artist:set({
          drawing = true,
          label = {
            string = artist_name,
            color = colors.with_alpha(colors.white, 0.6),  -- Slightly dimmed for artist when playing
          }
        })

        -- Try to get artwork URL via AppleScript
        local artwork_success = false
        local handle = io.popen("osascript -e 'tell application \"Spotify\" to try\nget artwork url of current track\nend try' 2>/dev/null")
        if handle then
          local artwork_url = handle:read("*a"):gsub("\n", "")
          handle:close()

          -- Debug: Log what AppleScript returned
          debug_log('AppleScript artwork result: ' .. tostring(artwork_url))

          if artwork_url and artwork_url ~= "" and artwork_url ~= "missing value" then
            -- Create cache directory and generate cache filename from track ID
            local track_id = env.INFO["Track ID"] or ""
            local cache_id = track_id:match("spotify:track:(.+)") or "unknown"
            local cache_dir = "/tmp/spotify_artwork"
            local cached_image = cache_dir .. "/" .. cache_id .. "_24x24.jpg"

            -- Create cache directory if it doesn't exist
            os.execute("mkdir -p '" .. cache_dir .. "'")

            -- Check if cached resized image already exists
            local cache_check = io.popen("ls -la '" .. cached_image .. "' 2>/dev/null")
            local cache_info = cache_check:read("*a")
            cache_check:close()

            if cache_info ~= "" then
              -- Use cached image
              debug_log('Using cached artwork: ' .. cached_image)
              artwork_success = true
            else
              -- Download and resize image
              local temp_download = cache_dir .. "/" .. cache_id .. "_original.jpg"
              local download_cmd = "curl -L -s --max-time 5 '" .. artwork_url .. "' -o '" .. temp_download .. "' 2>/tmp/curl_error.log"
              local download_result = os.execute(download_cmd)

              -- Check if download succeeded
              local file_check = io.popen("ls -la '" .. temp_download .. "' 2>/dev/null")
              local file_info = file_check:read("*a")
              file_check:close()

              local file_size = file_info:match("wheel%s+(%d+)")
              if file_size and tonumber(file_size) > 1000 then
                -- Resize image to 24x24 using macOS sips command
                local resize_cmd = "sips -z 24 24 '" .. temp_download .. "' --out '" .. cached_image .. "' >/dev/null 2>&1"
                local resize_result = os.execute(resize_cmd)

                if resize_result then
                  -- Clean up original download
                  os.execute("rm -f '" .. temp_download .. "'")
                  artwork_success = true
                  debug_log('Downloaded and resized artwork: ' .. cached_image)
                else
                  debug_log('Failed to resize artwork')
                end
              else
                debug_log('Download failed or file too small')
              end
            end

            if artwork_success then
              media_cover:set({
                drawing = true,
                background = {
                  image = {
                    string = cached_image,
                    scale = 1.0,  -- No scaling needed, already resized
                  },
                  corner_radius = 6,
                },
                width = 24,
                height = 24,
              })
            end
          end
        end

        if not artwork_success then
          media_cover:set({
            drawing = true,
            background = {
              image = {
                string = "media.artwork",  -- Fallback to media.artwork
                scale = 0.6,
              },
              color = colors.with_alpha(colors.grey, 0.3),
              corner_radius = 6,
            },
            width = 24,
            height = 24,
          })
          debug_log('Using fallback - AppleScript failed to get artwork')
        end

        debug_log('Successfully showed all widgets')
      end)

      if not success then
        debug_log('Error in playing section: ' .. tostring(err))
      end
    else
      -- Keep widget visible when paused, schedule delayed hide
      local success, err = pcall(function()
        debug_log('Paused - keeping widget visible, scheduling delayed hide')

        -- Keep showing the track info when paused, but dimmed
        media_title:set({
          drawing = true,
          label = {
            string = track_name,
            color = colors.with_alpha(colors.white, 0.4),  -- Dimmed when paused
          }
        })

        media_artist:set({
          drawing = true,
          label = {
            string = artist_name,
            color = colors.with_alpha(colors.white, 0.3),  -- More dimmed for artist
          }
        })

        media_cover:set({
          drawing = true,  -- Always show cover area when playing
        })

        -- Schedule delayed hide after idle time
        schedule_delayed_hide()
      end)

      if not success then
        debug_log('Error in pause section: ' .. tostring(err))
      end
    end
  else
    debug_log('No INFO - hiding widgets')
    media_title:set({ label = { string = "" } })
    media_artist:set({ label = { string = "" } })
    media_cover:set({ drawing = false })
  end
  end) -- End of pcall function

  -- Log any errors from the pcall
  if not success then
    debug_log('ERROR in update_media: ' .. tostring(err))
  end
end

media_title:subscribe("spotify_change", update_media)
media_artist:subscribe("spotify_change", update_media)
media_cover:subscribe("spotify_change", update_media)

SketchyBar.add("item", "spotify.back", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.back },
  label = { drawing = false },
  click_script = "osascript -e 'tell application \"Spotify\" to previous track'",
})

SketchyBar.add("item", "spotify.play_pause", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.play_pause },
  label = { drawing = false },
  click_script = "osascript -e 'tell application \"Spotify\" to playpause'",
})

SketchyBar.add("item", "spotify.forward", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  click_script = "osascript -e 'tell application \"Spotify\" to next track'",
})
media_cover:subscribe("mouse.clicked", function()
  media_cover:set({ popup = { drawing = "toggle" }})
end)

-- Hide popup when clicking elsewhere
media_cover:subscribe("mouse.exited.global", function()
  media_cover:set({ popup = { drawing = false }})
end)
