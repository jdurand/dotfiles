local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'voldikss/vim-floaterm',
    config = function()
      nnoremap('<leader>tt', ':FloatermNew<CR>', { desc = '[T]erminal' })
      nnoremap('<leader>tg', ':FloatermNew lazygit<CR>', { desc = 'Lazy[G]it' })
      nnoremap('<leader>td', ':FloatermNew! --height=0.9 --width=0.95 --wintype=float --name=gtasks --position=bottom gtasks tasks view --tasklist "Reclaim.ai"<CR>', { desc = 'Google Tasks (TO[D]O)' })
    end,
  }
}
