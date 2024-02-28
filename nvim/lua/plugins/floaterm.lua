local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'voldikss/vim-floaterm',
    config = function()
      nnoremap('<leader>tt', ':FloatermNew<CR>', { desc = 'List [H]arpoon Marks' })
      nnoremap('<leader>tg', ':FloatermNew lazygit<CR>', { desc = '[A]dd to Harpoon Marks' })
      nnoremap('<leader>td', ':FloatermNew! --height=0.9 --width=0.95 --wintype=float --name=gtasks --position=bottom gtasks tasks view --tasklist "🗓 Reclaim"<CR>', { desc = '[A]dd to Harpoon Marks' })
    end,
  }
}
