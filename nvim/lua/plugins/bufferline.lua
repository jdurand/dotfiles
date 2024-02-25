return {
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      vim.opt.termguicolors = true
      require("bufferline").setup({
        options = {
          diagnostics = 'nvim_lsp',
          separator_style = 'thick', -- "slant" | "slope" | "thick" | "thin" | { 'any', 'any' },
        }
      })
    end,
  },
}
