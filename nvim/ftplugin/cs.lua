local bufnr = vim.api.nvim_get_current_buf()
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
end

local dap_cs = require('user.extensions.nvim-dap-cs')

local function code_action_only(kinds)
  return function()
    vim.lsp.buf.code_action({ context = { only = kinds }, apply = true })
  end
end

map('n', '<leader>Nr', function() dap_cs.run_project() end,                                'C#: run project')
map('n', '<leader>Nd', function() dap_cs.debug_project() end,                              'C#: debug project (netcoredbg)')
map('n', '<leader>Nb', '<cmd>Dotnet build<cr>',                                            'C#: build')
map('n', '<leader>NR', '<cmd>Dotnet restore<cr>',                                          'C#: restore')
map('n', '<leader>Nw', '<cmd>Dotnet watch<cr>',                                            'C#: watch')
map('n', '<leader>Ns', '<cmd>Dotnet secrets<cr>',                                          'C#: user-secrets')
map('n', '<leader>No', code_action_only({ 'source.organizeImports' }),                     'C#: organize imports')
map('n', '<leader>Nv', code_action_only({ 'refactor.extract.variable', 'refactor.extract' }), 'C#: extract variable')
map('n', '<leader>Nc', code_action_only({ 'refactor.extract.constant' }),                  'C#: extract constant')
map('n', '<leader>Nm', code_action_only({ 'refactor.extract.function', 'refactor.extract' }), 'C#: extract method')

map('n', '<leader>Nt', '<cmd>Dotnet testrunner<cr>',                                       'C#: test runner UI')
map('n', '<leader>NT', '<cmd>Dotnet test<cr>',                                             'C#: dotnet test')

map('v', '<leader>Nv', code_action_only({ 'refactor.extract.variable', 'refactor.extract' }), 'C#: extract variable')
map('v', '<leader>Nc', code_action_only({ 'refactor.extract.constant' }),                  'C#: extract constant')
map('v', '<leader>Nm', code_action_only({ 'refactor.extract.function', 'refactor.extract' }), 'C#: extract method')

local wk_ok, whichkey = pcall(require, 'which-key')
if wk_ok then
  whichkey.add({
    { '<leader>N', group = '[N]et / C#', buffer = bufnr },
    { '<leader>N', group = '[N]et / C#', mode = 'v', buffer = bufnr },
  })
end
