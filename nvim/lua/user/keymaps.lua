local nnoremap = require("user.keymap_utils").nnoremap
local vnoremap = require("user.keymap_utils").vnoremap
local inoremap = require("user.keymap_utils").inoremap
local tnoremap = require("user.keymap_utils").tnoremap
local xnoremap = require("user.keymap_utils").xnoremap

local harpoon_ui = require("harpoon.ui")
local harpoon_mark = require("harpoon.mark")

-- Command-T Keybinds
vim.keymap.set('n', '<Leader>f', '<Plug>(CommandTRipgrep)')
vim.keymap.set('n', '<Leader>g', '<Plug>(CommandTGit)')
vim.keymap.set('n', '<Leader>;', '<Plug>(CommandTBuffer)<ESC>')


-- Harpoon keybinds --
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


-- Git keymaps --
nnoremap("<leader>gb", ":Gitsigns toggle_current_line_blame<cr>")
nnoremap("<leader>gf", function()
  local cmd = {
    "sort",
    "-u",
    "<(git diff --name-only --cached)",
    "<(git diff --name-only)",
    "<(git diff --name-only --diff-filter=U)",
  }

  if not utils.is_git_directory() then
    vim.notify(
      "Current project is not a git directory",
      vim.log.levels.WARN,
      { title = "Telescope Git Files", git_command = cmd }
    )
  else
    require("telescope.builtin").git_files()
  end
end, { desc = "Search [G]it [F]iles" })
