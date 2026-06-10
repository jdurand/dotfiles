-- VSCode-specific configuration, loaded only when running inside the
-- vscode-neovim extension (see init.lua). VSCode owns the UI, so here we just
-- delegate a handful of leader mappings to native VSCode commands and keep the
-- pure-vim editing maps that work without any of the disabled plugins.
-- ----------------------------------------------------------------------------------------------------
local vscode = require('vscode')
local keymaps = require('user.keymaps.bind')
local nnoremap, vnoremap = keymaps.nnoremap, keymaps.vnoremap

-- Run a VSCode command, optionally with arguments.
local function cmd(name, opts)
  return function() vscode.action(name, opts) end
end

-- Find / navigate
-- ----------------------------------------------------------------------------------------------------
nnoremap('<leader>ff', cmd('workbench.action.quickOpen'), { desc = '[F]ind [F]iles' })
nnoremap('<leader>fg', cmd('workbench.action.findInFiles'), { desc = '[F]ind by [G]rep' })
nnoremap('<leader>fb', cmd('workbench.action.showAllEditors'), { desc = '[F]ind [B]uffer' })
nnoremap('<leader>fs', cmd('workbench.action.gotoSymbol'), { desc = '[F]ind [S]ymbol' })
nnoremap('<leader>e', cmd('workbench.view.explorer'), { desc = 'Toggle [E]xplorer' })

-- Code actions / LSP (VSCode provides gd, gr, K out of the box)
-- ----------------------------------------------------------------------------------------------------
nnoremap('<leader>rn', cmd('editor.action.rename'), { desc = '[R]e[n]ame symbol' })
nnoremap('<leader>ca', cmd('editor.action.quickFix'), { desc = '[C]ode [A]ction' })
nnoremap('<leader>cf', cmd('editor.action.formatDocument'), { desc = '[C]ode [F]ormat' })
nnoremap('gr', cmd('editor.action.goToReferences'), { desc = 'Goto [R]eferences' })
nnoremap('[d', cmd('editor.action.marker.prev'), { desc = 'Previous [D]iagnostic' })
nnoremap(']d', cmd('editor.action.marker.next'), { desc = 'Next [D]iagnostic' })

-- Splits (delegate to VSCode editor groups)
-- ----------------------------------------------------------------------------------------------------
nnoremap('<leader>=', cmd('workbench.action.splitEditor'), { desc = 'Split right' })
nnoremap('<leader>l', cmd('workbench.action.splitEditor'), { desc = 'Split right' })
nnoremap('<leader>-', cmd('workbench.action.splitEditorDown'), { desc = 'Split down' })
nnoremap('<leader>j', cmd('workbench.action.splitEditorDown'), { desc = 'Split down' })

-- Zen mode (mirrors the <leader>z map from the standalone config)
-- ----------------------------------------------------------------------------------------------------
nnoremap('<leader>z', cmd('workbench.action.toggleZenMode'), { desc = 'Toggle [Z]en Mode' })

-- Save with CTRL-S
-- ----------------------------------------------------------------------------------------------------
nnoremap('<C-S>', cmd('workbench.action.files.save'), { desc = 'Save file' })

-- Pure-vim editing maps worth keeping (no plugin/UI dependency)
-- ----------------------------------------------------------------------------------------------------
-- Easy new lines
vim.api.nvim_set_keymap('n', 'ø', 'mo<Esc>o<Esc>k`o', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'Ø', 'mo<Esc>O<Esc>j`o', { noremap = true, silent = true })

-- Always go to the mark’s line and column
vim.api.nvim_set_keymap('n', "'", "`", { noremap = true })
vim.api.nvim_set_keymap('v', "'", "`", { noremap = true })

-- Remap ^ characters
vim.api.nvim_set_keymap('n', 'â', '^a', { noremap = true })
vim.api.nvim_set_keymap('n', 'î', '^i', { noremap = true })
vim.api.nvim_set_keymap('n', 'ô', '^o', { noremap = true })

-- Easy indentation in visual mode (keep selection)
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true })
vim.api.nvim_set_keymap('v', '>', '>gv', { noremap = true })
vim.api.nvim_set_keymap('v', '<Tab>', '>gv', { noremap = true })
vim.api.nvim_set_keymap('v', '<S-Tab>', '<gv', { noremap = true })

-- Search-insensitivity to match the standalone config
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.clipboard = 'unnamedplus'
