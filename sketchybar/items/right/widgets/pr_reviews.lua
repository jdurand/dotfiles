local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Configuration constants
local CONFIG = {
  ORGANIZATION = "libroreserve",
  REVIEWER = "@me",
  REFRESH_INTERVAL = 300, -- 5 minutes in seconds
  MAX_TITLE_LENGTH = 50,
}

-- Cache for PR data
local cached_prs = {}

-- PR Reviews Widget
local pr_reviews = SketchyBar.add("item", "widgets.pr_reviews", {
  position = "right",
  icon = {
    string = icons.git_branch,
    color = colors.orange,
  },
  label = {
    string = "0 PRs",
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

-- Centralized GitHub CLI command function
local function fetch_pr_reviews(callback)
  local command = string.format(
    '/opt/homebrew/bin/gh search prs --review-requested %s --owner %s --state open --json repository,title,url',
    CONFIG.REVIEWER,
    CONFIG.ORGANIZATION
  )
  SketchyBar.exec(command, callback)
end

-- Function to create popup menu items from cached data
local function create_popup_menu()
  -- Clear existing menu items
  SketchyBar.remove("/widgets.pr_reviews.menu.*/")

  -- Add PR items to popup using cached data
  for i, pr in ipairs(cached_prs) do
    local title = pr.title
    if string.len(title) > CONFIG.MAX_TITLE_LENGTH then
      title = string.sub(title, 1, CONFIG.MAX_TITLE_LENGTH) .. "..."
    end

    -- Extract repository name, removing organization prefix if it matches
    local repo_name = pr.repository.nameWithOwner
    local org_prefix = CONFIG.ORGANIZATION .. "/"
    if string.sub(repo_name, 1, string.len(org_prefix)) == org_prefix then
      repo_name = string.sub(repo_name, string.len(org_prefix) + 1)
    end

    local menu_item = SketchyBar.add("item", "widgets.pr_reviews.menu.item." .. i, {
      position = "popup.widgets.pr_reviews",
      label = {
        string = repo_name .. ": " .. title,
        font = {
          family = settings.font.text,
          size = 11.0,
        },
        color = colors.white,
        padding_left = 18,
        padding_right = 18,
      },
      background = {
        color = colors.transparent,
        height = 22,
        corner_radius = 4,
      },
      click_script = 'open "' .. pr.url .. '"; sketchybar --set widgets.pr_reviews popup.drawing=off',
    })

    -- Add hover effect (macOS style blue highlight)
    menu_item:subscribe("mouse.entered", function()
      menu_item:set({
        background = { color = colors.with_alpha(colors.dark_blue, 0.75) },
        label = { color = colors.white }
      })
    end)

    menu_item:subscribe("mouse.exited", function()
      menu_item:set({
        background = { color = colors.transparent },
        label = { color = colors.white }
      })
    end)
  end
end

-- Function to update PR reviews count and cache
local function update_pr_reviews()
  fetch_pr_reviews(function(result)
    local prs = result or {}
    cached_prs = prs -- Update cache
    local count = #prs

    if count > 0 then
      pr_reviews:set({
        label = count .. (count == 1 and " PR" or " PRs"),
        drawing = true,
      })
    else
      pr_reviews:set({
        drawing = false,
      })
    end
  end)
end

-- Instant click handler using cached data
pr_reviews:subscribe("mouse.clicked", function(env)
  create_popup_menu()
  pr_reviews:set({ popup = { drawing = "toggle" } })
end)

-- Hide popup when clicking elsewhere
pr_reviews:subscribe("mouse.exited.global", function()
  pr_reviews:set({ popup = { drawing = false } })
end)

-- Set up periodic updates
SketchyBar.add("event", "pr_reviews_update")
SketchyBar.exec(string.format("while true; do sleep %d; /opt/homebrew/bin/sketchybar --trigger pr_reviews_update; done &", CONFIG.REFRESH_INTERVAL))

pr_reviews:subscribe("pr_reviews_update", update_pr_reviews)

-- Initial update
update_pr_reviews()

-- Add padding item to separate from other widgets
SketchyBar.add("item", "widgets.pr_reviews.padding", {
  position = "right",
  width = 2
})
