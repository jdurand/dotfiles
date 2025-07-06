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
      -- 'olimorris/neotest-rspec',
      'jdurand/neotest-rspec',
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
              local executable = 'bin/docker-rspec'
              local command = {}

              if io.popen('command -v ' .. executable):read('*a') ~= '' then
                command = { executable }
              else
                command = { 'bundle', 'exec', 'rspec' }
              end

              table.insert(command, '--color')
              table.insert(command, '--keep-up') -- keeps the docker container running after execution

              if type == 'test' then
                table.insert(command, '--fail-fast')
              end

              return command
            end,
            transform_spec_path = function(path)
              -- return relative path to specs for docker support
              return vim.fn.fnamemodify(path, ':.')
            end,
            formatter_path = '/neotest-rspec/neotest_formatter.rb',
            results_path = function()
              -- configure a results directory that Docker can access under /rspec-test-output/...
              return './tmp/rspec-test-output' .. require('neotest.async').fn.tempname()
            end
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
