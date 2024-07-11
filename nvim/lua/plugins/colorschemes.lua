return {
  -- 'altercation/vim-colors-solarized',
  -- 'craftzdog/solarized-osaka.nvim',
  -- 'polirritmico/monokai-nightasty.nvim',
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.opt.termguicolors = true
      -- vim.cmd.colorscheme 'tokyonight-night'
      -- vim.cmd.colorscheme 'tokyonight-storm'
      -- vim.cmd.colorscheme 'tokyonight-day'
      vim.cmd.colorscheme 'tokyonight-moon'
    end
  },
  -- {
  --   'catppuccin/nvim',
  --   name = 'catppuccin',
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require('catppuccin').setup({
  --       flavour = 'macchiato', -- latte, frappe, macchiato, mocha
  --       background = { -- :h background
  --         light = 'latte',
  --         dark = 'macchiato',
  --       },
  --       integrations = {
  --         cmp = true,
  --         gitsigns = true,
  --         harpoon = true,
  --         illuminate = true,
  --         indent_blankline = {
  --           enabled = false,
  --           scope_color = "sapphire",
  --           colored_indent_levels = false,
  --         },
  --         mason = true,
  --         native_lsp = { enabled = true },
  --         notify = true,
  --         nvimtree = true,
  --         neotree = true,
  --         symbols_outline = true,
  --         telescope = true,
  --         treesitter = true,
  --         treesitter_context = true,
  --       },
  --     })

  --     vim.opt.termguicolors = true
  --     vim.cmd.colorscheme 'catppuccin-macchiato'
  --     -- vim.o.background = 'light'
  --   end,
  -- },
}
