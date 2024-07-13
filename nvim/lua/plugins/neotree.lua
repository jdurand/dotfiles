return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    -- lazy = false,
    branch = "v3.x",
    keys = {
      { "<C-f>", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
    },
    config = function()
      require('neo-tree').setup({
        window = {
          mappings = {
            -- ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
            -- ["<space>"] = {
            --   "toggle_node",
            --   nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
            -- },
            ["<space>"] = {
              "toggle_preview", config = { use_float = true, use_image_nvim = false }
            },
            ["<c-f>"] = "close_window",
            ["<c-l>"] = "focus_preview",
            ["<C-d>"] = { "scroll_preview", config = {direction = -10} },
            ["<C-u>"] = { "scroll_preview", config = {direction = 10} },
          }
        }
      })
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  },
  {
    '3rd/image.nvim',
    dependencies = { 'luarocks.nvim' },
    opts = {
      rocks = {
        hererocks = true,
        enabled = false
      }
    }
  },
  {
    'vhyrro/luarocks.nvim',
    priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    config = true,
    opts = {
      rocks = { 'magick' },
    },
  }
}
