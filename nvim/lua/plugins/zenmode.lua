local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'folke/zen-mode.nvim',
    opts = {
      -- window = {
      --   backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
      --   -- height and width can be:
      --   -- * an absolute number of cells when > 1
      --   -- * a percentage of the width / height of the editor when <= 1
      --   -- * a function that returns the width or the height
      --   width = 120, -- width of the Zen window
      --   height = 1, -- height of the Zen window
      --   -- by default, no options are changed for the Zen window
      --   -- uncomment any of the options below, or add other vim.wo options you want to apply
      --   options = {
      --     -- signcolumn = "no", -- disable signcolumn
      --     -- number = false, -- disable number column
      --     -- relativenumber = false, -- disable relative numbers
      --     -- cursorline = false, -- disable cursorline
      --     -- cursorcolumn = false, -- disable cursor column
      --     -- foldcolumn = "0", -- disable fold column
      --     -- list = false, -- disable whitespace characters
      --   },
      -- },
      plugins = {
        -- disable some global vim options (vim.o...)
        -- comment the lines to not apply the options
        -- options = {
        --   enabled = true,
        --   ruler = false, -- disables the ruler text in the cmd line area
        --   showcmd = false, -- disables the command in the last line of the screen
        --   -- you may turn on/off statusline in zen mode by setting 'laststatus'
        --   -- statusline will be shown only if 'laststatus' == 3
        --   laststatus = 0, -- turn off the statusline in zen mode
        -- },
        twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
        gitsigns = { enabled = true }, -- disables git signs
        tmux = { enabled = true },     -- disables the tmux statusline
        -- this will change the font size on kitty when in zen mode
        -- to make this work, you need to set the following kitty options:
        -- - allow_remote_control socket-only
        -- - listen_on unix:/tmp/kitty
        kitty = {
          enabled = true,
          font = '+4', -- font size increment
        },
        -- this will change the font size on alacritty when in zen mode
        -- requires  Alacritty Version 0.10.0 or higher
        -- uses `alacritty msg` subcommand to change font size
        alacritty = {
          enabled = true,
          font = '20', -- font size
        },
        -- this will change the font size on wezterm when in zen mode
        -- See alse also the Plugins/Wezterm section in this projects README
        wezterm = {
          enabled = true,
          -- can be either an absolute font size or the number of incremental steps
          font = '+4', -- (10% increase per step)
        },
      },
      -- callback where you can add custom code when the Zen window opens
      on_open = function( --[[ win ]])
        -- vim.o.cmdheight = 1
        require('lualine').hide({ place = {}, unhide = false })

        require('tokyonight').setup({ transparent = true })
        vim.cmd.colorscheme(vim.g.colors_name)
      end,
      -- callback where you can add custom code when the Zen window closes
      on_close = function()
        -- vim.o.cmdheight = 0
        require('lualine').hide({ place = {}, unhide = true })

        require('tokyonight').setup({ transparent = false })
        vim.cmd.colorscheme(vim.g.colors_name)

        vim.fn.system('tmux set status on')
      end,
    }
  },
  {
    'folke/twilight.nvim',
    opts = {
      dimming = {
        alpha = 0.35, -- amount of dimming
        -- we try to get the foreground from the highlight groups or fallback color
        color = { "Normal", "#ffffff" },
        term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
        inactive = false,    -- when true, other windows will be fully dimmed (unless they contain the same buffer)
      },
      -- context = 10, -- amount of lines we will try to show around the current line
      -- treesitter = true, -- use treesitter when available for the filetype
      -- -- treesitter is used to automatically expand the visible text,
      -- -- but you can further control the types of nodes that should always be fully expanded
      -- expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
      --   "function",
      --   "method",
      --   "table",
      --   "if_statement",
      -- },
      -- exclude = {}, -- exclude these filetypes
    }
  }
}
