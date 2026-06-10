-- This file can be loaded by calling `lua require('plugins')` from your init.vim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- fix obsidian issue: https://github.com/epwalsh/obsidian.nvim/issues/286
vim.opt.conceallevel = 2

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- When running inside the vscode-neovim extension, VSCode owns the UI,
-- syntax highlighting, file navigation, LSP, completion, etc. We only want
-- to load plugins that improve the *editing* experience (text objects,
-- motions, surround, ...). Everything else is skipped to keep startup fast
-- and to avoid fighting VSCode for control.
--
-- Add a plugin's short name (the repo basename) here to enable it in VSCode.
local vscode_plugins = {
  ['mini.ai'] = true,           -- extended a/i text objects
  ['mini.surround'] = true,     -- add/delete/replace surroundings
  ['mini.operators'] = true,    -- replace/exchange/sort/etc. operators
  ['mini.move'] = true,         -- move lines/selections with Alt+hjkl
  ['mini.bracketed'] = true,    -- ]/[ navigation mappings
  ['mini.pairs'] = true,        -- auto-close pairs
  ['Comment.nvim'] = true,      -- gc/<leader>cc commenting
  ['vim-abolish'] = true,       -- case coercion (crs/crc/cru) & :Subvert
  ['vim-extract-variable'] = true, -- <leader>ev refactor
}

require('lazy').setup('plugins', {
  defaults = {
    -- cond is evaluated per-plugin: return false to skip loading entirely.
    cond = function(plugin)
      if not vim.g.vscode then return true end
      return vscode_plugins[plugin.name] == true
    end,
  },
  change_detection = {
    notify = false
  }
})
