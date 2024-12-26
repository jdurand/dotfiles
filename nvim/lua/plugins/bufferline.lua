local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = 'nvim_lsp',
          separator_style = 'slant', -- "slant" | "slope" | "thick" | "thin" | { 'any', 'any' },
          mode = 'tabs',
          -- sort_by = 'relative_directory', -- 'insert_after_current' |'insert_at_end' | 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
        }
      })

      -- open blank new tab
      nnoremap('<C-t><C-n>', ':tabnew<cr>')
      -- move current buffer to new tab
      nnoremap('<C-t><C-t>', '<C-w>T')
      -- close current tab
      nnoremap('<C-t><C-q>', ':tabclose<cr>')

      nnoremap('<C-t>>', ':tabnext<cr>', { desc = 'Next Tab' })
      nnoremap('<C-t><', ':tabprevious<cr>', { desc = 'Previous Tab' })
      nnoremap('<C-t><C-y>', ':tabnext<cr>', { desc = 'Next Tab' })
      nnoremap('<C-t><C-r>', ':tabprevious<cr>', { desc = 'Previous Tab' })
      nnoremap('>>', ':tabnext<cr>', { desc = 'Next Tab' })
      nnoremap('<<', ':tabprevious<cr>', { desc = 'Previous Tab' })

      nnoremap('<C-S-PageUp>', ':-tabmove<cr>')
      nnoremap('<C-S-PageDown>', ':+tabmove<cr>')

      nnoremap('<C-t><C->>', ':-tabmove<cr>')
      nnoremap('<C-t><C-<>', ':+tabmove<cr>')
    end,
  },
}
