-- Define the leader key
-- ----------------------------------------------------------------------------------------------------
vim.g.mapleader = ";"

require('dependencies')

if vim.g.vscode then
  -- Inside the vscode-neovim extension: VSCode owns the UI, so we skip the
  -- desktop modules (which pull in which-key, noice, telescope, ...) and load
  -- a focused set of editing maps that delegate to native VSCode commands.
  require('user.vscode')
else
  require('user.keymaps')
  require('user.settings')
  require('user.plugins')
end
