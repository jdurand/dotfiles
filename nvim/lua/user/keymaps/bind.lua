local M = {}

local tmp_keymap_set = require('user.keymaps.override').temporarily_override_keybinding

local function bind(mode, outer_opts, temp)
  outer_opts = vim.tbl_extend('force', { noremap = true, silent = true }, outer_opts or {})

  return function(keys, action, opts)
    opts = vim.tbl_extend('force', outer_opts, opts or {})
    local keymap_set = temp and tmp_keymap_set or vim.keymap.set

    return keymap_set(mode, keys, action, opts)
  end
end

M.map = bind('')

M.nmap = bind('n', { noremap = false })
M.vmap = bind('v', { noremap = false })
M.tmap = bind('t', { noremap = false })

M.nnoremap = bind('n')
M.vnoremap = bind('v')
M.xnoremap = bind('x')
M.inoremap = bind('i')
M.tnoremap = bind('t')

M.restorable_nnoremap = bind('n', {}, true)

return M
