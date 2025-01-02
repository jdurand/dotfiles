local whichkey = require('which-key')
local keymaps = require('user.keymaps.bind')
local nnoremap, nmap, vnoremap = keymaps.nnoremap, keymaps.nmap, keymaps.vnoremap

-- Define group keybindings
whichkey.add({
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
})

whichkey.add({
  { '<leader>', group = '<leader>', mode = 'v' },
})

-- Define the ZenMode keybind here to prevent conflicts
-- with `config` block options in the plugin file
nnoremap('<leader>z', function()
  require('zen-mode').toggle({
    window = {
      width = .85 -- width will be 85% of the editor width
    }
  })
end, { desc = 'Open in [Z]en Mode' })

-- Other custom keymaps
nmap('<leader>yf', function()
  vim.fn.setreg('*', vim.fn.expand('%'))
end, { desc = 'Copy [f]ile path to clipboard' })

-- Yank selected text on left mouse release
vnoremap('<LeftRelease>', '"*ygv<escape>', { desc = 'Yank on mouse selection' })
