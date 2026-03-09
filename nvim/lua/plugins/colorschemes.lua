return {
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      local transparent = true -- less transparent than before for a bit more opacity

      local is_matrix = vim.env.DOTFILES_THEME == 'matrix'

      require('tokyonight').setup({
        transparent = transparent,
        styles = {
          sidebars = transparent and 'transparent' or 'dark',
          floats = transparent and 'transparent' or 'dark',
        },
        on_colors = function(colors)
          if is_matrix then
            colors.bg = '#0a1a0a'
            colors.bg_dark = '#061206'
            colors.bg_float = '#0d1f0d'
            colors.bg_popup = '#0d1f0d'
            colors.bg_sidebar = '#061206'
            colors.bg_statusline = '#0d2b0d'
            colors.bg_highlight = '#142814'
            colors.bg_visual = '#1a3a1a'
            colors.fg = '#b3ffb3'
            colors.fg_dark = '#80cc80'
            colors.fg_gutter = '#1a3a1a'
            colors.fg_sidebar = '#80cc80'
            colors.fg_float = '#b3ffb3'
            colors.blue = '#00ff41'       -- matrix green (primary)
            colors.cyan = '#00cc33'       -- dim green
            colors.green = '#ccff00'      -- lime accent
            colors.magenta = '#00ff41'    -- keep green
            colors.purple = '#00cc99'     -- teal-green
            colors.orange = '#66ff66'     -- light green
            colors.red = '#ff3333'        -- keep red for errors
            colors.yellow = '#ccff00'     -- lime
            colors.teal = '#00cc99'       -- teal-green
            colors.comment = '#2d5a2d'    -- muted green
            colors.dark3 = '#2d5a2d'
            colors.dark5 = '#3d6b3d'
            colors.border = '#00ff41'
            colors.border_highlight = '#00ff41'
            colors.git = { add = '#00ff41', change = '#ccff00', delete = '#ff3333' }
          end
        end,
        on_highlights = function(highlights, colors)
          if transparent then
            highlights.BufferLineSeparator = { bg = colors.none, fg = colors.fg_gutter, blend = 50 }
            highlights.BufferLineSeparatorSelected = { bg = colors.none, fg = colors.fg_gutter, blend = 50 }
            highlights.BufferLineSeparatorVisible = { bg = colors.none, fg = colors.fg_gutter, blend = 50 }
          end
        end,
      })

      -- vim.cmd.colorscheme 'tokyonight-night'
      -- vim.cmd.colorscheme 'tokyonight-storm'
      -- vim.cmd.colorscheme 'tokyonight-day'
      vim.cmd.colorscheme 'tokyonight-moon'
    end
  },
  {
    'f-person/auto-dark-mode.nvim',
    -- disable auto-dark-mode when using matrix theme (always dark)
    cond = function() return vim.env.DOTFILES_THEME ~= 'matrix' end,
    opts = {
      update_interval = (60 * 1000),
      set_dark_mode = function()
        vim.api.nvim_set_option_value('background', 'dark', {})
        vim.cmd.colorscheme 'tokyonight-night'
        -- buffer separator
        vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#32344D' })
        -- terminal background color for floaterm
        vim.api.nvim_set_hl(0, 'FloaTerm', { bg = vim.g.terminal_color_0 })
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value('background', 'dark', {}) -- or light
        vim.cmd.colorscheme 'tokyonight-moon'
        -- buffer separator
        vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#32344D' })
        -- terminal background color for floaterm
        vim.api.nvim_set_hl(0, 'FloaTerm', { bg = vim.g.terminal_color_0 })
      end
    }
  }
}
