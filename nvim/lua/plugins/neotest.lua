local nnoremap = require('user.keymaps.bind').nnoremap

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
    },
    config = function()
      local api = require('neotest')
      local rspec = require('neotest-rspec')

      api.setup({
        adapters = {
          rspec({
            rspec_cmd = function(type) -- file, test, dir
              if type == "test" then
                return {
                  -- 'RSPEC_OPTS="--format doc"',
                  'bundle', 'exec', 'rspec',
                  '--fail-fast',
                  '--color',
                }
              else
                return {
                  'bundle', 'exec', 'rspec',
                  -- 'RSPEC_OPTS="--format Fuubar"',
                  '--color',
                }
              end
           end
          })
        },
      })

      nnoremap('[t', function() api.jump.prev({ status = 'failed' }) end, { desc = 'Previous failed test' })
      nnoremap(']t', function() api.jump.next({ status = 'failed' }) end, { desc = 'Next failed test' })

      nnoremap('trt', function() api.run.run() end, { desc = '[R]un nearest test' })
      nnoremap('trl', function() api.run.run_last() end, { desc = 'Re-run [l]ast test' })
      nnoremap('trf', function() api.run.run(vim.fn.expand('%')) end, { desc = 'Run current [f]ile' })
      nnoremap('trd', function() api.run.run({ strategy = 'dap' }) end, { desc = '[D]ebug nearest test' })
      nnoremap('trA', function() api.run.run(vim.fn.getcwd()) end, { desc = 'Run [a]ll files' })
      nnoremap('trq', function() api.run.stop() end, { desc = 'Stop test run' })

      nnoremap('trw', function() api.watch.toggle() end, { desc = 'Toggle test [w]atch' })
      nnoremap('trW', function() api.watch.toggle(vim.fn.expand('%')) end, { desc = 'Toggle file [W]atch' })

      nnoremap('trr', function() api.run.attach() end, { desc = '[R]unning test output' })
      nnoremap('trs', function() api.summary.toggle() end, { desc = 'Toggle test [s]ummary' })
      nnoremap('tro', function() api.output.open() end, { desc = 'Test [o]utput' })
      nnoremap('trO', function() api.output_panel.toggle() end, { desc = 'Toggle [O]utput panel' })
    end
  },
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'suketa/nvim-dap-ruby'
    },
    config = function()
      require('dap-ruby').setup()
    end
  }
}
