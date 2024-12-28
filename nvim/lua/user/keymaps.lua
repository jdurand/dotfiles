local keymaps = require('user.keymaps.bind')
local nnoremap, nmap = keymaps.nnoremap, keymaps.nmap

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
