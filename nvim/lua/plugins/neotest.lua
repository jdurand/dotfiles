local bind = require('user.keymaps.bind')
local nnoremap = bind.nnoremap

return {
  {
    'nvim-neotest/neotest',
    lazy = false,
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'olimorris/neotest-rspec',
      'mfussenegger/nvim-dap',
      'stevearc/overseer.nvim'
    },
    config = function()
      local api = require('neotest')
      local overseer = require('overseer')
      local rspec = require('neotest-rspec')

      ---@diagnostic disable: missing-fields
      api.setup({
        log_level = vim.log.levels.INFO,
        consumers = {
          overseer = require('neotest.consumers.overseer'), ---@diagnostic disable-line: assign-type-mismatch
        },
        icons = {},
        highlights = {},
        projects = {},
        adapters = {
          rspec({
            rspec_cmd = function(type) -- file, test, dir
              if type == 'test' then
                return {
                  'bundle', 'exec', 'rspec',
                  '--fail-fast',
                  '--color',
                }
              else
                return {
                  'bundle', 'exec', 'rspec',
                  '--color',
                }
              end
            end,
          }),
        },
        overseer = {
          enabled = true,
          -- When this is true (the default), it will replace all neotest.run.* commands
          force_default = true,
        },
      })
      ---@diagnostic enable: missing-fields

      nnoremap('[t', function() api.jump.prev({ status = 'failed' }) end, { desc = 'Previous failed test' })
      nnoremap(']t', function() api.jump.next({ status = 'failed' }) end, { desc = 'Next failed test' })

      nnoremap('trt', function() api.run.run(); overseer.open({ enter = false }) end, { desc = 'Run nearest test' })
      nnoremap('trl', function() api.run.run_last(); overseer.open({ enter = false }) end, { desc = 'Re-run last test' })
      nnoremap('trf', function() api.run.run(vim.fn.expand('%')); overseer.open({ enter = false }) end, { desc = 'Run current file' })

      nnoremap('trD', function() api.run.run({ suite = false, strategy = 'dap' }) end, { desc = 'Debug nearest test' })
      -- Workaround for the lack of a DAP strategy in nvim-dap-ruby
      nnoremap('trd', function() require('user.extensions.nvim-dap-ruby').debug_test() end, { desc = "Debug test (ruby)" })
      nnoremap('trA', function() api.run.run(vim.fn.getcwd()) end, { desc = 'Run all files' })
      nnoremap('trq', function() api.run.stop() end, { desc = 'Stop test run' })

      nnoremap('trw', function() api.watch.toggle() end, { desc = 'Toggle test watch' })
      nnoremap('trW', function() api.watch.toggle(vim.fn.expand('%')) end, { desc = 'Toggle file watch' })

      nnoremap('trr', function() api.run.attach() end, { desc = 'Running test output' })
      nnoremap('trs', function() api.summary.toggle() end, { desc = 'Toggle test summary' })
      nnoremap('tro', function() api.output.open() end, { desc = 'Test output' })
      nnoremap('trO', function() api.output_panel.toggle() end, { desc = 'Toggle output panel' })
    end
  }
}
