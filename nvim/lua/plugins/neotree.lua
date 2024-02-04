return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    -- lazy = false,
    branch = "v3.x",
    keys = {
      { "<C-f>", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
    },
    config = function()
      require('neo-tree').setup()
    end,
    depencencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  },
}
