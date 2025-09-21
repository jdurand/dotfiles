local colors = require("colors")
local settings = require("settings")
local Timer = require("helpers.timer")

-- Configuration constants
local CONFIG = {
  TIME_REFRESH_INTERVAL = 30, -- 30 seconds for updating warning status
  CALENDAR_FETCH_INTERVAL = 300, -- 5 minutes for fetching from Google Calendar
  CALENDAR_SCRIPT = os.getenv("HOME") .. "/.dotfiles/scripts/calendar-meetings",
  TUI_WIDTH = "140c",
  TUI_HEIGHT = "35c",
  EARLY_WARNING_MINUTES = 15, -- minutes before meeting to show yellow icon
  URGENT_WARNING_MINUTES = 5, -- minutes before meeting to show yellow background
  GRACE_PERIOD_MINUTES = 3, -- minutes after meeting start to still show warning
  TITLE_MAX_LENGTH = 40, -- Maximum title length for display
  URGENT_TITLE_MAX_LENGTH = 20, -- Maximum title length for urgent display
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
  drawing = true, -- Start visible, will be controlled by logic
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

-- ===========================================================================
-- HELPER FUNCTIONS
-- ===========================================================================

-- Truncate a string to a specified length
local function truncate_string(str, max_length)
  if string.len(str) > max_length then
    return string.sub(str, 1, max_length) .. "..."
  end
  return str
end

-- Format meeting count as string
local function format_meeting_count(count)
  return count .. (count == 1 and " meeting" or " meetings")
end

-- Parse time string into minutes
local function parse_time_to_minutes(time_str)
  if not time_str or time_str == "" then
    return nil
  end

  local hour, min = time_str:match("(%d+):(%d+)")
  if not hour or not min then
    return nil
  end

  return tonumber(hour) * 60 + tonumber(min)
end

-- Get current time in minutes
local function get_current_minutes()
  local current_hour = tonumber(os.date("%H"))
  local current_min = tonumber(os.date("%M"))
  return current_hour * 60 + current_min
end

-- Parse meeting time and check warning level
-- Returns: nil (no warning), "early" (EARLY_WARNING to URGENT_WARNING min before),
--          "urgent" (URGENT_WARNING min before to GRACE_PERIOD min after)
local function get_meeting_warning_level(start_time)
  local meeting_minutes = parse_time_to_minutes(start_time)
  if not meeting_minutes then
    return nil
  end

  local current_minutes = get_current_minutes()
  local time_diff = meeting_minutes - current_minutes

  if time_diff >= -CONFIG.GRACE_PERIOD_MINUTES and time_diff <= CONFIG.URGENT_WARNING_MINUTES then
    return "urgent"  -- URGENT_WARNING min before to GRACE_PERIOD min after
  elseif time_diff > CONFIG.URGENT_WARNING_MINUTES and time_diff <= CONFIG.EARLY_WARNING_MINUTES then
    return "early"   -- EARLY_WARNING to URGENT_WARNING min before
  else
    return nil
  end
end

-- Analyze meetings and return statistics
local function analyze_meetings()
  local stats = {
    warning_level = nil,
    meet_count = 0,
    has_any_timed_events = false,
    urgent_meeting = nil
  }

  for _, meeting in ipairs(cached_meetings) do
    if meeting.start_time and meeting.start_time ~= "" then
      stats.has_any_timed_events = true

      -- Count only meetings with Google Meet links
      if meeting.has_meet_link then
        stats.meet_count = stats.meet_count + 1
      end

      -- Check warning level (only for meetings with Google Meet links)
      if meeting.has_meet_link then
        local meeting_warning = get_meeting_warning_level(meeting.start_time)
        if meeting_warning == "urgent" then
          stats.warning_level = "urgent"  -- Urgent takes priority
          stats.urgent_meeting = meeting
        elseif meeting_warning == "early" and stats.warning_level ~= "urgent" then
          stats.warning_level = "early"
        end
      end
    end
  end

  return stats
end

-- Determine widget appearance based on meeting statistics
local function get_widget_appearance(stats)
  local appearance = {}

  if stats.warning_level == "urgent" and stats.urgent_meeting then
    -- Urgent warning: bell icon, meeting name, bright yellow background
    appearance.icon_string = "􀋚"  -- bell icon
    appearance.icon_color = colors.black
    appearance.text_color = colors.black
    appearance.bg_color = colors.yellow
    appearance.label_string = truncate_string(
      stats.urgent_meeting.title or "Meeting",
      CONFIG.URGENT_TITLE_MAX_LENGTH
    )
  elseif stats.warning_level == "early" then
    -- Early warning: calendar icon with yellow color
    appearance.icon_string = "􀉉"  -- calendar icon
    appearance.icon_color = colors.yellow
    appearance.text_color = colors.white
    appearance.bg_color = { alpha = 0 }
    appearance.label_string = format_meeting_count(stats.meet_count)
  else
    -- No warning: normal calendar icon and colors
    appearance.icon_string = "􀉉"  -- calendar icon
    appearance.icon_color = stats.meet_count == 0 and colors.grey or colors.magenta
    appearance.text_color = colors.white
    appearance.bg_color = { alpha = 0 }
    appearance.label_string = format_meeting_count(stats.meet_count)
  end

  return appearance
end

-- Update widget with new appearance
local function update_widget_display(stats)
  if not stats.has_any_timed_events then
    -- No timed events - keep widget present but transparent for event handling
    calendar_meetings:set({
      icon = {
        string = "􀉉",  -- Keep icon for consistent width
        color = colors.transparent,  -- Make it invisible
      },
      label = {
        string = "0 meetings",  -- Keep label for consistent width
        color = colors.transparent,  -- Make it invisible
      },
      background = { color = colors.transparent },
      drawing = true,  -- Always keep drawing for event handling
    })
    return
  end

  -- Has timed events - show widget normally
  local appearance = get_widget_appearance(stats)

  calendar_meetings:set({
    icon = {
      string = appearance.icon_string,
      color = appearance.icon_color,
    },
    label = {
      string = appearance.label_string,
      color = appearance.text_color,
    },
    background = {
      color = appearance.bg_color
    },
    drawing = true,
  })
end

-- Parse TSV line into parts
local function parse_tsv_line(line)
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
  return parts
end

-- Parse meeting data from TSV result
local function parse_meetings_result(meetings_result)
  local meetings = {}
  local stats = {
    warning_level = nil,
    meet_count = 0,
    has_any_timed_events = false,
    urgent_meeting = nil
  }

  if not meetings_result then
    return meetings, stats
  end

  local lines = {}
  for line in meetings_result:gmatch("[^\n]+") do
    table.insert(lines, line)
  end

  -- Skip header line and parse meetings
  for i = 2, #lines do
    local parts = parse_tsv_line(lines[i])

    if #parts >= 7 then
      local meeting = {
        start_date = parts[1],
        start_time = parts[2],
        end_date = parts[3],
        end_time = parts[4],
        html_link = parts[5],
        hangout_link = parts[6],
        title = parts[7],
        has_meet_link = parts[6] ~= ""
      }
      table.insert(meetings, meeting)

      -- Update statistics for timed meetings
      if parts[2] ~= "" then
        stats.has_any_timed_events = true

        if parts[6] ~= "" then
          stats.meet_count = stats.meet_count + 1
        end

        -- Check warning level (only for meetings with Google Meet links)
        if parts[6] ~= "" then
          local meeting_warning = get_meeting_warning_level(parts[2])
          if meeting_warning == "urgent" then
            stats.warning_level = "urgent"
            stats.urgent_meeting = meeting
          elseif meeting_warning == "early" and stats.warning_level ~= "urgent" then
            stats.warning_level = "early"
          end
        end
      end
    end
  end

  return meetings, stats
end

-- Format date label for separators
local function format_date_label(date_str)
  local current_date = os.date("%Y-%m-%d")
  if date_str == current_date then
    return "Today"
  end

  -- Format date as "Mon, Sep 22"
  local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
  if year and month and day then
    local time = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day)})
    return os.date("%a, %b %d", time)
  end

  return date_str
end

-- Get meeting display properties
local function get_meeting_display_props(meeting)
  local title = truncate_string(meeting.title or "No title", CONFIG.TITLE_MAX_LENGTH)
  local start_time = meeting.start_time or ""
  local props = {}

  if start_time == "" then
    -- All-day event - check for special location types
    local title_lower = title:lower()
    if title_lower == "home" or title_lower == "office" then
      props.is_location_header = true
      props.display_text = title_lower == "home" and "Working from Home" or "Working from Office"
      props.meeting_icon = title_lower == "home" and "􀎞" or "􀤨"  -- house icon or building.2 icon
      props.icon_color = colors.white
    else
      props.display_text = "All day - " .. title
      props.meeting_icon = "􀉉"  -- calendar icon
      props.icon_color = colors.grey
    end
  else
    -- Timed event
    props.display_text = start_time .. " - " .. title
    props.meeting_icon = meeting.has_meet_link and "􀍉" or "􀉉"  -- video icon for Meet, calendar for others
    props.icon_color = meeting.has_meet_link and colors.green or colors.grey
  end

  props.text_color = meeting.has_meet_link and colors.white or colors.with_alpha(colors.white, 0.6)
  return props
end

-- Create a date separator item
local function create_date_separator(index, date_str, max_width)
  local date_label = format_date_label(date_str)

  return SketchyBar.add("item", "widgets.calendar_meetings.menu.separator." .. index, {
    position = "popup.widgets.calendar_meetings",
    icon = {
      string = "── " .. date_label .. " ──",
      font = {
        family = settings.font.text,
        style = settings.font.style_map["Semibold"],
        size = 10.0,
      },
      color = colors.with_alpha(colors.white, 0.5),
      padding_left = 0,
      padding_right = 0,
      width = max_width,
      align = "center",
    },
    label = {
      string = "",
      padding_left = 0,
      padding_right = 0,
    },
    background = {
      color = colors.transparent,
      height = 20,
    },
    width = max_width,
  })
end

-- Create a menu item for a meeting
local function create_menu_item(index, meeting, props, max_width)
  local item_config = {
    position = "popup.widgets.calendar_meetings",
    icon = {
      string = props.meeting_icon,
      color = props.icon_color,
      font = {
        family = settings.font.text,
        size = 12.0,
      },
      padding_left = 10,
      padding_right = 8,
    },
    label = {
      string = props.display_text,
      font = {
        family = settings.font.text,
        style = props.is_location_header and settings.font.style_map["Bold"] or nil,
        size = props.is_location_header and 11.0 or 11.0,
      },
      color = props.is_location_header and colors.white or props.text_color,
      padding_left = 0,
      padding_right = 18,
    },
    background = {
      color = colors.transparent,
      height = props.is_location_header and 28 or 22,
      corner_radius = 4,
      border_width = props.is_location_header and 1 or 0,
      border_color = props.is_location_header and colors.with_alpha(colors.grey, 0.3) or nil,
    },
    width = max_width,
  }

  local menu_item = SketchyBar.add("item", "widgets.calendar_meetings.menu.item." .. index, item_config)

  -- Add interactivity for non-header items
  if not props.is_location_header then
    -- Set up click handler
    local link = nil
    if meeting.hangout_link and meeting.hangout_link ~= "" then
      link = meeting.hangout_link
    elseif meeting.html_link and meeting.html_link ~= "" then
      link = meeting.html_link
    end

    if link then
      menu_item:set({
        click_script = string.format(
          'open "%s"; sketchybar --set widgets.calendar_meetings popup.drawing=off',
          link:gsub('"', '\\"')
        )
      })
    else
      -- No valid link, just close the popup when clicked
      menu_item:set({
        click_script = 'sketchybar --set widgets.calendar_meetings popup.drawing=off'
      })
    end

    -- Add hover effects
    menu_item:subscribe("mouse.entered", function()
      menu_item:set({
        background = { color = colors.with_alpha(colors.dark_blue, 0.75) },
        icon = { color = props.icon_color },
        label = { color = colors.white }
      })
    end)

    menu_item:subscribe("mouse.exited", function()
      menu_item:set({
        background = { color = colors.transparent },
        icon = { color = props.icon_color },
        label = { color = props.text_color }
      })
    end)
  end

  return menu_item
end

-- ===========================================================================
-- PUBLIC FUNCTIONS
-- ===========================================================================

-- Function to fetch upcoming meetings
local function fetch_upcoming_meetings(callback)
  SketchyBar.exec(CONFIG.CALENDAR_SCRIPT .. " --upcoming", callback)
end

-- Function to create popup menu items from cached data
local function create_popup_menu()
  -- Clear existing menu items
  SketchyBar.remove("/widgets.calendar_meetings.menu.*/")

  -- Calculate maximum width needed for all items
  local max_width = 150  -- minimum width
  for _, meeting in ipairs(cached_meetings) do
    local props = get_meeting_display_props(meeting)
    local item_width = math.min(300, string.len(props.display_text) * 7 + 40)
    max_width = math.max(max_width, item_width)
  end

  -- Track current date to add separators
  local last_date = nil
  local item_index = 0

  -- Add meeting items to popup using cached data
  for _, meeting in ipairs(cached_meetings) do
    -- Check if we need a date separator
    if meeting.start_date ~= last_date then
      item_index = item_index + 1
      create_date_separator(item_index, meeting.start_date, max_width)
      last_date = meeting.start_date
    end

    item_index = item_index + 1
    local props = get_meeting_display_props(meeting)
    create_menu_item(item_index, meeting, props, max_width)
  end
end

-- Function to update warning status based on cached meetings
local function update_warning_status()
  if #cached_meetings == 0 then
    return
  end

  local stats = analyze_meetings()
  update_widget_display(stats)
end

-- Function to fetch and update calendar meetings from Google Calendar
local function fetch_and_update_calendar()
  fetch_upcoming_meetings(function(meetings_result)
    local meetings, stats = parse_meetings_result(meetings_result)
    cached_meetings = meetings

    -- Always update widget display (maintains event handling)
    update_widget_display(stats)

    -- Clear cache only if no events at all
    if not stats.has_any_timed_events then
      cached_meetings = {}
    end
  end)
end

-- Find urgent meeting from cache
local function find_urgent_meeting()
  for _, meeting in ipairs(cached_meetings) do
    -- Only consider meetings with Google Meet links for urgent status
    if meeting.has_meet_link and get_meeting_warning_level(meeting.start_time) == "urgent" then
      return meeting
    end
  end
  return nil
end

-- ===========================================================================
-- EVENT HANDLERS
-- ===========================================================================

-- Click handler using cached data
calendar_meetings:subscribe("mouse.clicked", function(env)
  Logger:info("Calendar widget clicked")

  local urgent_meeting = find_urgent_meeting()

  if urgent_meeting then
    Logger:info("Found urgent meeting with Google Meet: " .. (urgent_meeting.title or "Unknown"))
    -- Only auto-open Google Meet links for urgent meetings
    local link = urgent_meeting.hangout_link
    if link and link ~= "" then
      Logger:info("Opening Google Meet link: " .. link)
      os.execute('open "' .. link .. '" &')
    else
      -- Fallback to showing popup if no Meet link (shouldn't happen with our logic)
      Logger:info("Urgent meeting has no Meet link, showing popup")
      create_popup_menu()
      calendar_meetings:set({ popup = { drawing = "toggle" } })
    end
  else
    Logger:info("No urgent Google Meet meeting, showing popup menu")
    -- Otherwise show the popup menu
    create_popup_menu()
    calendar_meetings:set({ popup = { drawing = "toggle" } })
  end
end)

-- Hide popup when clicking elsewhere
calendar_meetings:subscribe("mouse.exited.global", function()
  calendar_meetings:set({ popup = { drawing = false } })
end)

-- ===========================================================================
-- INITIALIZATION
-- ===========================================================================

-- Set up managed timers with automatic sleep/wake handling
Timer.create_group({
  item = calendar_meetings,
  timers = {
    { name = "calendar_time_update", interval = CONFIG.TIME_REFRESH_INTERVAL },
    { name = "calendar_fetch_update", interval = CONFIG.CALENDAR_FETCH_INTERVAL }
  },
  on_wake = function()
    -- Trigger immediate update after wake
    fetch_and_update_calendar()
  end
})

-- Subscribe to timer events
calendar_meetings:subscribe("calendar_time_update", update_warning_status)
calendar_meetings:subscribe("calendar_fetch_update", fetch_and_update_calendar)

-- Initial fetch and update
fetch_and_update_calendar()