local M = {}

local function bind(mode, outer_opts)
  outer_opts = vim.tbl_extend("force", { noremap = true, silent = true }, outer_opts or {})

  return function(keys, action, opts, docs)
    opts = vim.tbl_extend("force", outer_opts, opts or {})
    docs = docs or {}

    vim.keymap.set(mode, keys, action, opts)
  end
end

M.map = bind("")
M.nmap = bind("n", { noremap = false })
M.vmap = bind("v", { noremap = false })
M.tmap = bind("t", { noremap = false })
M.nnoremap = bind("n")
M.vnoremap = bind("v")
M.xnoremap = bind("x")
M.inoremap = bind("i")
M.tnoremap = bind("t")

return M
