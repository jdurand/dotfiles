-- Define the leader key
-- ----------------------------------------------------------------------------------------------------
vim.g.mapleader = ";"

-- Bust the vim.loader bytecode cache when the Neovim runtime changes (e.g. a
-- `brew upgrade neovim`). Stale entries from a previous build cause "module
-- not found" errors on builtin runtime modules (vim.filetype.detect, ...).
-- Must run before any module loading — lazy.nvim bootstraps the loader inside
-- `dependencies`.
do
  local stamp = vim.fn.stdpath('cache') .. '/runtime_stamp'
  local f = io.open(stamp, 'r')
  local prev = f and f:read('*a') or ''
  if f then f:close() end
  if prev ~= vim.env.VIMRUNTIME then
    vim.fn.delete(vim.fn.stdpath('cache') .. '/luac', 'rf')
    local w = io.open(stamp, 'w')
    if w then
      w:write(vim.env.VIMRUNTIME)
      w:close()
    end
  end
end
vim.loader.enable()

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
