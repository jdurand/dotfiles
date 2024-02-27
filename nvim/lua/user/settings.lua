
-- vim.cmd([[
--   augroup MyColors
--   autocmd!
--   autocmd ColorScheme * highlight BufferLineFill guibg=#191724
--   autocmd ColorScheme * highlight BufferLineSeparator guifg=#191724
--   autocmd ColorScheme * highlight BufferLineSeparatorSelected guifg=#191724
--   augroup END
-- ]])

-- trigger `autoread` when files changes on disk
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})

-- document existing key chains
require('which-key').register {
  ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
  ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = '[G]it/Chat[G]PT', _ = 'which_key_ignore' },
  -- ['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
  ['<leader>h'] = { name = '[H]arpoon', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
  -- ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
  ['<leader>f'] = { name = '[F]ind', _ = 'which_key_ignore' },
  -- ['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
  -- ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
}
-- register which-key VISUAL mode
-- required for visual <leader>hs (hunk stage) to work
require('which-key').register({
  ['<leader>'] = { name = 'VISUAL <leader>' },
  -- ['<leader>h'] = { 'Git [H]unk' },
}, { mode = 'v' })
