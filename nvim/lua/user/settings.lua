
vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#c099ff' })

-- trigger `autoread` when files changes on disk
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})

require('which-key').add {
  { '<leader>', group = '<leader>' },
  { "<leader>c", group = "[C]ode" }, { "<leader>c_", hidden = true },
  { "<leader>d", group = "[D]ocument" }, { "<leader>d_", hidden = true },
  { "<leader>f", group = "[F]ind" }, { "<leader>f_", hidden = true },
  { "<leader>g", group = "[G]it/Chat[G]PT" }, { "<leader>g_", hidden = true },
  { "<leader>h", group = "[H]arpoon" }, { "<leader>h_", hidden = true },
  { "<leader>r", group = "[R]ename" }, { "<leader>r_", hidden = true },
  { "<leader>t", group = "[T]ab/[T]erminal" }, { "<leader>t_", hidden = true },
  { "<leader>w", group = "[W]orkspace" }, { "<leader>w_", hidden = true },
  { "<leader>y", group = "[Y]anky" }, { "<leader>y_", hidden = true },

  { "<leader>b", hidden = true },
  { "<leader>e", hidden = true },
  { "<leader>n", hidden = true },
  { "<leader>p", hidden = true },
}

require('which-key').add {
  { '<leader>', group = '<leader>', mode = 'v' },
}
