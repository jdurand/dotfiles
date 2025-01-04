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
      'mfussenegger/nvim-dap',
    },
    config = function()
      local api = require('neotest')
      local rspec = require('neotest-rspec')

      ---@diagnostic disable: missing-fields
      api.setup({
        log_level = vim.log.levels.INFO,
        consumers = {},
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
      })
      ---@diagnostic enable: missing-fields

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
      'rcarriga/nvim-dap-ui',
      'theHamsta/nvim-dap-virtual-text',
      'nvim-telescope/telescope-dap.nvim',
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')

      ---@diagnostic disable: missing-fields
      dapui.setup({
        layouts = {
          {
          --   elements = {
          --     {
          --       id = "scopes",
          --       size = 0.25
          --     }, {
          --       id = "breakpoints",
          --       size = 0.25
          --     }, {
          --       id = "stacks",
          --       size = 0.25
          --     }, {
          --       id = "watches",
          --       size = 0.25
          --     }
          --   },
          --   position = "left",
          --   size = 40
          -- }, {
            elements = {
              {
                id = 'watches',
                size = 0.25
              }, {
                id = 'repl',
                size = 0.75
              -- }, {
              --   id = 'console',
              --   size = 0.5
              }
            },
            position = 'bottom',
            size = 10
          }
        },
      })
      require('nvim-dap-virtual-text').setup({
        commented = true
      })
      require('user.extensions.nvim-dap-ruby').setup()
      ---@diagnostic enable: missing-fields

      local function float_debug_console()
        dapui.float_element('repl', {
          title = 'Debuging Console',
          width = 100,
          height = 20,
          enter = true,
          position = 'center'
        })
      end

      local function float_debug_watches()
        dapui.float_element('watches', {
          title = 'Watches',
          width = 100,
          height = 20,
          enter = true,
          position = 'center'
        })
      end

      -- Configure DAP UI to open and close with debug events
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      local whichkey = require('which-key')

      whichkey.add({
        { 'td', group = 'Debug', nowait = false, remap = false },

        { 'tdC', function() dap.set_breakpoint(vim.fn.input("[Condition] > ")) end, desc = 'Conditional Breakpoint', nowait = false, remap = false },

        { 'tdt', function() dap.toggle_breakpoint() end, desc = 'Toggle Breakpoint', nowait = false, remap = false },
        { 'tdX', function() dap.clear_breakpoints() end, desc = 'Clear breakpoints', nowait = false, remap = false },

        { 'tds', function() dap.continue() end, desc = 'Start', nowait = false, remap = false },
        { 'tdc', function() dap.continue() end, desc = 'Continue', nowait = false, remap = false },
        { 'tda', function() dap.restart() end, desc = 'Restart', nowait = false, remap = false },
        { 'tdx', function() dap.terminate() end, desc = 'Terminate', nowait = false, remap = false },

        { 'tdj', function() dap.up() end, desc = 'Go up the stack frame', nowait = false, remap = false },
        { 'tdk', function() dap.down() end, desc = 'Go down the stack frame', nowait = false, remap = false },
        { 'tdi', function() dap.step_into() end, desc = 'Step Into', nowait = false, remap = false },
        { 'tdu', function() dap.step_out() end, desc = 'Step Out', nowait = false, remap = false },
        { 'tdo', function() dap.step_over() end, desc = 'Step Over', nowait = false, remap = false },
        { 'tdd', function() dap.focus_frame() end, desc = 'Focus current frame', nowait = false, remap = false },

        { 'tde', function() dapui.eval(); dapui.eval() end, desc = 'Evaluate', nowait = false, remap = false },

        { 'tdh', function() require("dap.ui.widgets").hover() end, desc = 'Hover Variables', nowait = false, remap = false },
        { 'tdr', function() float_debug_console() end, desc = 'Toggle Repl', nowait = false, remap = false },
        { 'tdw', function() float_debug_watches() end, desc = 'Toggle Watch', nowait = false, remap = false },
        { 'tdU', function() dapui.toggle() end, desc = 'Toggle UI', nowait = false, remap = false },

        { 'tdb', "<cmd>Telescope dap list_breakpoints<cr>", desc = 'Telescope list breakpoints', nowait = false, remap = false },
        { 'tdf', "<cmd>Telescope dap frames<cr>", desc = 'Telescope frames', nowait = false, remap = false },
        { 'tdv', '<cmd>Telescope dap variables<cr>', desc = 'Telescope list variables', nowait = false, remap = false },
      })

      whichkey.add({
        { 'td', group = 'Debug', mode = 'v', nowait = false, remap = false },
        { 'tde', function() require('dapui').eval(); require('dapui').eval() end, desc = 'Evaluate', mode = 'v', nowait = false, remap = false },
      })
    end
  },
  {
    'm00qek/baleia.nvim',
    config = function()
      local baleia = require('baleia').setup({})

      vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = 'dap-repl',
        callback = function()
          baleia.automatically(vim.api.nvim_get_current_buf())
        end,
      })
    end
  }
}
