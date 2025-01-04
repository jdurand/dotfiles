local keymaps = require('user.keymaps.bind')
local nnoremap, nmap, vnoremap = keymaps.nnoremap, keymaps.nmap, keymaps.vnoremap

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
