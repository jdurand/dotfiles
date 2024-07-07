local nnoremap = require('user.keymaps.bind').nnoremap

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
          mode = 'tabs',
          -- sort_by = 'relative_directory', -- 'insert_after_current' |'insert_at_end' | 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
        }
      })

      -- open blank new tab
      nnoremap('<C-t><C-t>', ':tabnew<cr>')
      -- nnoremap('<C-w><C-w>', ':tabclose<cr>')
      nnoremap('<C-t>>', ':tabnext<cr>')
      nnoremap('<C-t><', ':tabprevious<cr>')

      -- nnoremap('<C-t><PageUp>', ':tabnext<cr>')
      -- nnoremap('<C-t><PageDown>', ':tabprevious<cr>')
    end,
  },
}
