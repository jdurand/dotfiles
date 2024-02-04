
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
