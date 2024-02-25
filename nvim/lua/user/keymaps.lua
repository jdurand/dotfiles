local nnoremap = require("user.keymaps.bind").nnoremap
-- local vnoremap = require("user.keymap_utils").vnoremap
-- local inoremap = require("user.keymap_utils").inoremap
-- local tnoremap = require("user.keymap_utils").tnoremap
-- local xnoremap = require("user.keymap_utils").xnoremap

local harpoon_ui = require("harpoon.ui")
local harpoon_mark = require("harpoon.mark")

-- command-t keybinds
nnoremap('<Leader>f', '<Plug>(CommandTRipgrep)')
nnoremap('<Leader>g', '<Plug>(CommandTGit)')
-- vim.keymap.set('n', '<Leader>;', '<Plug>(CommandTBuffer)<ESC>')


-- harpoon keybinds --
-- Open harpoon ui
nnoremap("<leader>ho", function()
  harpoon_ui.toggle_quick_menu()
end)

-- Add current file to harpoon
nnoremap("<leader>ha", function()
  harpoon_mark.add_file()
end)

-- Remove current file from harpoon
nnoremap("<leader>hr", function()
  harpoon_mark.rm_file()
end)

-- Remove all files from harpoon
nnoremap("<leader>hc", function()
  harpoon_mark.clear_all()
end)

-- Quickly jump to harpooned files
nnoremap("<leader>1", function()
  harpoon_ui.nav_file(1)
end)

nnoremap("<leader>2", function()
  harpoon_ui.nav_file(2)
end)

nnoremap("<leader>3", function()
  harpoon_ui.nav_file(3)
end)

nnoremap("<leader>4", function()
  harpoon_ui.nav_file(4)
end)

nnoremap("<leader>5", function()
  harpoon_ui.nav_file(5)
end)
