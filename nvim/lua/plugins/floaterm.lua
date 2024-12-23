local keymaps = require('user.keymaps.bind')
local nnoremap = keymaps.nnoremap
local tnoremap = keymaps.tnoremap

return {
  {
    'voldikss/vim-floaterm',
    config = function()
      vim.g.floaterm_wintype = 'float'
      vim.g.floaterm_borderchars = '─│─│╭╮╯╰'
      vim.g.floaterm_width = 0.9
      vim.g.floaterm_height = 0.8

      nnoremap('<leader>tt', ':FloatermToggle<CR>', { desc = '[T]erminal' })
      tnoremap('<leader>tt', '<C-\\><C-n>:FloatermToggle<CR>', { desc = '[T]erminal' })

      nnoremap('<leader>tg', ':FloatermNew lazygit<CR>', { desc = 'Lazy[G]it' })
      nnoremap('<leader>td', ':FloatermNew! --height=0.9 --width=0.95 --wintype=float --name=gtasks --position=bottom gtasks tasks view --tasklist "Reclaim.ai"<CR>', { desc = 'Google Tasks (TO[D]O)' })

      nnoremap('<leader>tn', ':FloatermNew<CR>', { desc = '[N]ew Terminal' })
      tnoremap('<leader>tn', '<C-\\><C-n>:FloatermNew<CR>', { desc = '[N]ew Terminal' })

      tnoremap('<C-PageUp>', '<C-\\><C-n>:FloatermPrev<CR>')
      tnoremap('<C-PageDown>', '<C-\\><C-n>:FloatermNext<CR>')

      tnoremap('<escape><escape>', '<C-\\><C-n>')
    end,
  }
}
