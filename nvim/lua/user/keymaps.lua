local nnoremap = require("user.keymaps.bind").nnoremap

-- local vnoremap = require("user.keymap_utils").vnoremap
-- local inoremap = require("user.keymap_utils").inoremap
-- local tnoremap = require("user.keymap_utils").tnoremap
-- local xnoremap = require("user.keymap_utils").xnoremap

-- Define the ZenMode keybind here to prevent conflicts 
-- with `config` block options in the plugin file
nnoremap('<leader>z', function()
  require('zen-mode').toggle({
    window = {
      width = .85 -- width will be 85% of the editor width
    }
  })
end, { desc = 'Open in [Z]en Mode' })
