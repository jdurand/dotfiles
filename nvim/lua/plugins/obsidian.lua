return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  -- version = "v3.3.1",
  lazy = true,
  -- ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  event = {
    "BufReadPre " .. vim.fn.expand "~" .. "/Notes/**.md",
    "BufNewFile " .. vim.fn.expand "~" .. "/Notes/**.md",

    "BufReadPre " .. vim.fn.expand "~" .. "/Library/Mobile Documents/iCloud~md~obsidian/Documents/**.md",
    "BufNewFile " .. vim.fn.expand "~" .. "/Library/Mobile Documents/iCloud~md~obsidian/Documents/**.md",
  },

  opts = {
    ui = { enable = false },

    workspaces = {
      {
        name = "Personal",
        path = "~/Notes/Personal",
      },
      {
        name = "Work",
        path = "~/Notes/Work",
        -- Optional, override certain settings.
        -- overrides = {
        --   notes_subdir = "notes",
        -- },
      },
    },

    -- Optional, if you keep notes in a specific subdirectory of your vault.
    -- notes_subdir = "notes",

    templates = {
      subdir = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },

    daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      folder = "inbox/dailies",
      -- Optional, if you want to change the date format for the ID of daily notes.
      date_format = "%Y-%m-%d",
      -- Optional, if you want to change the date format of the default alias of daily notes.
      alias_format = "%B %-d, %Y",
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "daily-notes.md"
    },

    -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
    completion = {
      -- Set to false to disable completion.
      nvim_cmp = true,
      -- Trigger completion at 2 chars.
      min_chars = 2,
    },

    -- Optional, configure key mappings. These are the defaults. If you don't want to set any keymappings this
    -- way then set 'mappings = {}'.
    mappings = {
      -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle check-boxes.
      ["<leader>ch"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- Smart action depending on context, either follow link or toggle checkbox.
      ["<cr>"] = {
        action = function()
          return require("obsidian").util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
      -- Overrides the <leader>ff & <leader>fg mappings for Obsidian functionality
      ["<leader>ff"] = {
        action = function()
          return "<cmd>ObsidianQuickSwitch<CR>"
        end,
        opts = { buffer = true, expr = true },
      },
      ["<leader>fg"] = {
        action = function()
          return "<cmd>ObsidianSearch<CR>"
        end,
        opts = { buffer = true, expr = true },
      },
      ["<leader>fw"] = {
        action = function()
          return "<cmd>ObsidianWorkspace<CR>"
        end,
        opts = { buffer = true, expr = true },
      }
    },

    follow_url_func = function(url)
      -- Open the URL in the default web browser.
      vim.fn.jobstart({ "open", url })  -- Mac OS
      -- vim.fn.jobstart({ "xdg-open", url })  -- linux
    end,
  },

  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies ??
  },
}
