local colors = require("colors")
local settings = require("settings")

-- Configuration constants
local CONFIG = {
  TIME_REFRESH_INTERVAL = 30, -- 30 seconds for updating warning status
  CALENDAR_FETCH_INTERVAL = 300, -- 5 minutes for fetching from Google Calendar
  CALENDAR_SCRIPT = os.getenv("HOME") .. "/.dotfiles/scripts/calendar-meetings",
  GCALCLI_EXECUTABLE = "/opt/homebrew/bin/gcalcli",
  TUI_WIDTH = "140c",
  TUI_HEIGHT = "35c",
  EARLY_WARNING_MINUTES = 15, -- minutes before meeting to show yellow icon
  URGENT_WARNING_MINUTES = 5, -- minutes before meeting to show yellow background
  GRACE_PERIOD_MINUTES = 3, -- minutes after meeting start to still show warning
}

-- Cache for meeting data
local cached_meetings = {}

-- Calendar Meetings Widget
local calendar_meetings = SketchyBar.add("item", "widgets.calendar_meetings", {
  position = "right",
  icon = {
    string = "􀉉", -- calendar icon
    color = colors.magenta,
  },
  label = {
    string = "0 meetings",
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
  popup = {
    align = "center",
    background = {
      color = colors.with_alpha(colors.black, 0.9),
      border_color = colors.with_alpha(colors.grey, 0.3),
      border_width = 1,
      corner_radius = 5,
      shadow = {
        drawing = true,
        color = colors.with_alpha(colors.black, 0.5),
        angle = 90,
        distance = 10
      }
    }
  }
})

-- Add padding item to separate from other widgets
SketchyBar.add("item", "widgets.calendar_meetings.padding", {
  position = "right",
  width = 2
})

-- Function to fetch upcoming meetings
local function fetch_upcoming_meetings(callback)
  SketchyBar.exec(CONFIG.CALENDAR_SCRIPT .. " --upcoming", callback)
end

-- Function to fetch meetings count
local function fetch_meetings_count(callback)
  SketchyBar.exec(CONFIG.CALENDAR_SCRIPT .. " --count --upcoming", callback)
end

-- Function to parse meeting time and check warning level
-- Returns: nil (no warning), "early" (EARLY_WARNING to URGENT_WARNING min before),
--          "urgent" (URGENT_WARNING min before to GRACE_PERIOD min after)
local function get_meeting_warning_level(start_time)
  if not start_time or start_time == "" then
    return nil
  end

  local current_hour = tonumber(os.date("%H"))
  local current_min = tonumber(os.date("%M"))
  local current_minutes = current_hour * 60 + current_min

  local meeting_hour, meeting_min = start_time:match("(%d+):(%d+)")
  if not meeting_hour or not meeting_min then
    return nil
  end

  local meeting_minutes = tonumber(meeting_hour) * 60 + tonumber(meeting_min)
  local time_diff = meeting_minutes - current_minutes

  if time_diff >= -CONFIG.GRACE_PERIOD_MINUTES and time_diff <= CONFIG.URGENT_WARNING_MINUTES then
    return "urgent"  -- URGENT_WARNING min before to GRACE_PERIOD min after
  elseif time_diff > CONFIG.URGENT_WARNING_MINUTES and time_diff <= CONFIG.EARLY_WARNING_MINUTES then
    return "early"   -- EARLY_WARNING to URGENT_WARNING min before
  else
    return nil
  end
end


-- Function to create popup menu items from cached data
local function create_popup_menu()
  -- Clear existing menu items
  SketchyBar.remove("/widgets.calendar_meetings.menu.*/")

  -- Calculate maximum width needed for all items
  local max_width = 150  -- minimum width
  for _, meeting in ipairs(cached_meetings) do
    local title = meeting.title or "No title"
    local start_time = meeting.start_time or ""
    if string.len(title) > 40 then
      title = string.sub(title, 1, 40) .. "..."
    end
    local display_text = (start_time == "" and "All day - " or start_time .. " - ") .. title
    local item_width = math.min(300, string.len(display_text) * 7 + 40)
    max_width = math.max(max_width, item_width)
  end

  -- Add meeting items to popup using cached data
  for i, meeting in ipairs(cached_meetings) do
    local title = meeting.title or "No title"
    local start_time = meeting.start_time or ""
    local warning_level = get_meeting_warning_level(start_time)

    -- Truncate long titles
    if string.len(title) > 40 then
      title = string.sub(title, 1, 40) .. "..."
    end

    -- Check if this is a location-based all-day event for header treatment
    local is_location_header = false
    local display_text, meeting_icon, icon_color

    if start_time == "" then
      -- All-day event - check for special location types
      local title_lower = title:lower()
      if title_lower == "home" or title_lower == "office" then
        is_location_header = true
        display_text = title_lower == "home" and "Working from Home" or "Working from Office"
        meeting_icon = title_lower == "home" and "􀎞" or "􀢼"  -- house icon or office building icon
        icon_color = colors.white
      else
        display_text = "All day - " .. title
        meeting_icon = "􀉉"  -- calendar icon
        icon_color = colors.grey
      end
    else
      -- Timed event
      display_text = start_time .. " - " .. title
      meeting_icon = meeting.has_meet_link and "􀍉" or "􀉉"  -- video icon for Meet, calendar for others
      icon_color = meeting.has_meet_link and colors.green or colors.grey
    end

    local text_color = meeting.has_meet_link and colors.white or colors.with_alpha(colors.white, 0.6)  -- White for Meet links, dimmed white for others

    if is_location_header then
      -- Create location header with subtle styling
      local menu_item = SketchyBar.add("item", "widgets.calendar_meetings.menu.item." .. i, {
        position = "popup.widgets.calendar_meetings",
        icon = {
          string = meeting_icon,
          color = icon_color,
          font = {
            family = settings.font.text,
            size = 12.0,
          },
          padding_left = 10,
          padding_right = 8,
        },
        label = {
          string = display_text,
          font = {
            family = settings.font.text,
            style = settings.font.style_map["Bold"],
            size = 11.0,
          },
          color = colors.white,
          padding_left = 0,
          padding_right = 18,
        },
        background = {
          color = colors.transparent,  -- No background color
          height = 28,  -- Taller for better spacing
          corner_radius = 4,
          border_width = 1,
          border_color = colors.with_alpha(colors.grey, 0.3),  -- Bottom border for separation
        },
        width = max_width,
      })
      -- No click handler or hover effects for headers
    else
      -- Regular menu item
      local menu_item = SketchyBar.add("item", "widgets.calendar_meetings.menu.item." .. i, {
        position = "popup.widgets.calendar_meetings",
        icon = {
          string = meeting_icon,
          color = icon_color,
          font = {
            family = settings.font.text,
            size = 12.0,
          },
          padding_left = 10,
          padding_right = 8,
        },
        label = {
          string = display_text,
          font = {
            family = settings.font.text,
            size = 11.0,
          },
          color = text_color,
          padding_left = 0,
          padding_right = 18,
        },
        background = {
          color = colors.transparent,
          height = 22,
          corner_radius = 4,
        },
        width = max_width,
      })

      -- Set up click handler using cached links
      local hangout_link = meeting.hangout_link and meeting.hangout_link ~= "" and meeting.hangout_link or nil
      local html_link = meeting.html_link and meeting.html_link ~= "" and meeting.html_link or nil
      local link = hangout_link or html_link or "https://calendar.google.com"

      menu_item:set({
        click_script = string.format(
          'open "%s"; sketchybar --set widgets.calendar_meetings popup.drawing=off',
          link:gsub('"', '\\"') -- Escape any quotes in the URL
        )
      })

      -- Add hover effect for regular items only
      menu_item:subscribe("mouse.entered", function()
        menu_item:set({
          background = { color = colors.with_alpha(colors.dark_blue, 0.75) },
          icon = { color = icon_color },
          label = { color = colors.white }
        })
      end)

      menu_item:subscribe("mouse.exited", function()
        menu_item:set({
          background = { color = colors.transparent },
          icon = { color = icon_color },
          label = { color = text_color }
        })
      end)
    end
  end
end

-- Function to update warning status based on cached meetings (no API call)
local function update_warning_status()
  if #cached_meetings == 0 then
    return
  end

  local warning_level = nil
  local count = 0
  local urgent_meeting = nil

  -- Check warning level for meetings with Google Meet links only
  for _, meeting in ipairs(cached_meetings) do
    if meeting.start_time and meeting.start_time ~= "" and meeting.has_meet_link then
      count = count + 1
      local meeting_warning = get_meeting_warning_level(meeting.start_time)
      if meeting_warning == "urgent" then
        warning_level = "urgent"  -- Urgent takes priority
        urgent_meeting = meeting
      elseif meeting_warning == "early" and warning_level ~= "urgent" then
        warning_level = "early"
      end
    end
  end

  -- Update widget appearance based on warning level
  local icon_string, icon_color, text_color, bg_color, label_string

  if warning_level == "urgent" and urgent_meeting then
    -- Urgent warning: bell icon, meeting name, bright yellow background
    icon_string = "􀋚"  -- bell icon
    icon_color = colors.black
    text_color = colors.black
    bg_color = colors.yellow

    -- Truncate meeting title to 20 characters
    local title = urgent_meeting.title or "Meeting"
    if string.len(title) > 20 then
      title = string.sub(title, 1, 20) .. "..."
    end
    label_string = title
  elseif warning_level == "early" then
    -- Early warning: calendar icon with yellow color
    icon_string = "􀉉"  -- calendar icon
    icon_color = colors.yellow
    text_color = colors.white
    bg_color = { alpha = 0 }
    label_string = count .. (count == 1 and " meeting" or " meetings")
  else
    -- No warning: normal calendar icon and colors
    icon_string = "􀉉"  -- calendar icon
    icon_color = colors.magenta
    text_color = colors.white
    bg_color = { alpha = 0 }
    label_string = count .. (count == 1 and " meeting" or " meetings")
  end

  calendar_meetings:set({
    icon = {
      string = icon_string,
      color = icon_color
    },
    label = {
      string = label_string,
      color = text_color
    },
    background = {
      color = bg_color
    },
    drawing = count > 0,
  })
end

-- Function to fetch and update calendar meetings from Google Calendar
local function fetch_and_update_calendar()
  fetch_meetings_count(function(count_result)
    local count = tonumber(count_result and count_result:gsub("%s+", "") or "0") or 0

    if count > 0 then
      -- Also fetch the actual meeting data for popup and warning detection
      fetch_upcoming_meetings(function(meetings_result)
        cached_meetings = {}
        local warning_level = nil

        if meetings_result then
          local lines = {}
          for line in meetings_result:gmatch("[^\n]+") do
            table.insert(lines, line)
          end

          -- Skip header line and parse meetings
          for i = 2, #lines do
            local line = lines[i]
            -- Split by tabs, preserving empty fields
            local parts = {}
            local start = 1
            while true do
              local tab_pos = line:find("\t", start)
              if tab_pos then
                table.insert(parts, line:sub(start, tab_pos - 1))
                start = tab_pos + 1
              else
                table.insert(parts, line:sub(start))
                break
              end
            end

            -- Include all events with times (not all-day events)
            if #parts >= 7 then
              local meeting = {
                start_date = parts[1],
                start_time = parts[2],
                end_date = parts[3],
                end_time = parts[4],
                html_link = parts[5],
                hangout_link = parts[6],
                title = parts[7],
                has_meet_link = parts[6] ~= ""  -- Track if it has a Google Meet link
              }
              table.insert(cached_meetings, meeting)

              -- Only check warning level for meetings with Google Meet links
              if parts[6] ~= "" then
                local meeting_warning = get_meeting_warning_level(parts[2])
                if meeting_warning == "urgent" then
                  warning_level = "urgent"  -- Urgent takes priority
                elseif meeting_warning == "early" and warning_level ~= "urgent" then
                  warning_level = "early"
                end
              end
            end
          end
        end

        -- Update widget appearance based on warning level
        local icon_string, icon_color, text_color, bg_color, label_string
        local urgent_meeting = nil

        -- Find the urgent meeting if any
        for _, meeting in ipairs(cached_meetings) do
          if get_meeting_warning_level(meeting.start_time) == "urgent" then
            urgent_meeting = meeting
            break
          end
        end

        if warning_level == "urgent" and urgent_meeting then
          -- Urgent warning: bell icon, meeting name, bright yellow background
          icon_string = "􀋚"  -- bell icon
          icon_color = colors.black
          text_color = colors.black
          bg_color = colors.yellow

          -- Truncate meeting title to 20 characters
          local title = urgent_meeting.title or "Meeting"
          if string.len(title) > 20 then
            title = string.sub(title, 1, 20) .. "..."
          end
          label_string = title
        elseif warning_level == "early" then
          -- Early warning: calendar icon with yellow color
          icon_string = "􀉉"  -- calendar icon
          icon_color = colors.yellow
          text_color = colors.white
          bg_color = { alpha = 0 }
          label_string = count .. (count == 1 and " meeting" or " meetings")
        else
          -- No warning: normal calendar icon and colors
          icon_string = "􀉉"  -- calendar icon
          icon_color = colors.magenta
          text_color = colors.white
          bg_color = { alpha = 0 }
          label_string = count .. (count == 1 and " meeting" or " meetings")
        end

        calendar_meetings:set({
          icon = {
            string = icon_string,
            color = icon_color
          },
          label = {
            string = label_string,
            color = text_color
          },
          background = {
            color = bg_color
          },
          drawing = true,
        })
      end)
    else
      calendar_meetings:set({
        drawing = false,
      })
      cached_meetings = {}
    end
  end)
end

-- Click handler using cached data
calendar_meetings:subscribe("mouse.clicked", function(env)
  Logger:info("Calendar widget clicked")

  -- Check if there's actually an urgent meeting with Google Meet link right now
  local urgent_meeting = nil
  for _, meeting in ipairs(cached_meetings) do
    if meeting.has_meet_link and get_meeting_warning_level(meeting.start_time) == "urgent" then
      urgent_meeting = meeting
      break
    end
  end

  if urgent_meeting then
    Logger:info("Found urgent meeting: " .. (urgent_meeting.title or "Unknown"))

    -- Use the links from the cached meeting data
    local link = urgent_meeting.hangout_link or urgent_meeting.html_link or "https://calendar.google.com"
    Logger:info("Using direct link: " .. link)
    os.execute('open "' .. link .. '" &')
  else
    Logger:info("No urgent meeting, showing popup menu")
    -- Otherwise show the popup menu
    create_popup_menu()
    calendar_meetings:set({ popup = { drawing = "toggle" } })
  end
end)

-- Hide popup when clicking elsewhere
calendar_meetings:subscribe("mouse.exited.global", function()
  calendar_meetings:set({ popup = { drawing = false } })
end)

-- Set up periodic updates with separate intervals
-- Time-based warning updates (every 30 seconds)
SketchyBar.add("event", "calendar_time_update")
SketchyBar.exec(string.format("while true; do sleep %d; /opt/homebrew/bin/sketchybar --trigger calendar_time_update; done &", CONFIG.TIME_REFRESH_INTERVAL))

-- Calendar fetch updates (every 5 minutes)
SketchyBar.add("event", "calendar_fetch_update")
SketchyBar.exec(string.format("while true; do sleep %d; /opt/homebrew/bin/sketchybar --trigger calendar_fetch_update; done &", CONFIG.CALENDAR_FETCH_INTERVAL))

-- Subscribe to events
calendar_meetings:subscribe("calendar_time_update", update_warning_status)
calendar_meetings:subscribe("calendar_fetch_update", fetch_and_update_calendar)

-- Initial fetch and update
fetch_and_update_calendar()
