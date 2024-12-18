return {
  'folke/tokyonight.nvim',
  priority = 1000,
  config = function()
    local transparent = false -- set to true if you would like to enable transparency

    require('tokyonight').setup({
      transparent = transparent,
      styles = {
        sidebars = transparent and 'transparent' or 'dark',
        floats = transparent and 'transparent' or 'dark',
      },
      on_colors = function(--[[colors]])
        -- if transparent then
        --   colors.bg_float = colors.none
        --   colors.bg_sidebar = colors.none
        --   colors.bg_statusline = colors.none
        --   colors.border = colors.none
        -- end
      end,
      on_highlights = function(--[[highlights, colors]]) end,
    })

    -- vim.cmd.colorscheme 'tokyonight-night'
    -- vim.cmd.colorscheme 'tokyonight-storm'
    -- vim.cmd.colorscheme 'tokyonight-day'
    -- vim.cmd.colorscheme 'tokyonight-moon'

    -- local hour = os.date("*t").hour
    -- if hour >= 6 and hour < 18 then
      vim.cmd.colorscheme 'tokyonight-moon'
    -- else
    --   vim.cmd.colorscheme 'tokyonight-night'
    -- end

    -- terminal background color for floaterm
    vim.api.nvim_set_hl(0, 'FloaTerm', { bg = vim.g.terminal_color_0 })

    -- buffer separator
    vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#32344D' })
  end,
}
