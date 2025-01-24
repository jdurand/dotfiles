local bind = require('user.keymaps.bind')
local restorable_nnoremap = bind.restorable_nnoremap

return {
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

      vim.fn.sign_define('DapBreakpoint', { text='🛑', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl='DapBreakpoint' })

      local whichkey = require('which-key')

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

      local keybinding_restore_callbacks = {}

      local function initialize_debug_tools()
        dapui.open()

        keybinding_restore_callbacks = {
          restorable_nnoremap('<enter>', function() dap.step_into() end),
          restorable_nnoremap('<space>', function() dap.step_over() end),
          restorable_nnoremap('<backspace>', function() dap.step_out() end),
          restorable_nnoremap('<del>', function() dap.continue() end),
        }
      end

      local function cleanup_debug_tools()
        dapui.close()

        for _, restore in ipairs(keybinding_restore_callbacks) do
          restore()  -- Call the keybinding restore function
        end
      end

      -- Configure DAP UI to open and close with debug events
      dap.listeners.before.attach.dapui_config = initialize_debug_tools
      dap.listeners.before.launch.dapui_config = initialize_debug_tools
      dap.listeners.before.event_terminated.dapui_config = cleanup_debug_tools
      dap.listeners.before.event_exited.dapui_config = cleanup_debug_tools

      whichkey.add({
        { 'td', group = 'Debug', nowait = false, remap = false },

        { 'tdC', function() dap.set_breakpoint(vim.fn.input("[Condition] > ")) end, desc = 'Conditional Breakpoint', nowait = false, remap = false },

        { 'tdt', function() dap.toggle_breakpoint() end, desc = 'Toggle Breakpoint', nowait = false, remap = false },
        { 'tdX', function() dap.clear_breakpoints() end, desc = 'Clear breakpoints', nowait = false, remap = false },

        { 'tds', function() dap.continue() end, desc = 'Start', nowait = false, remap = false },
        { 'tdc', function() dap.continue() end, desc = 'Continue', nowait = false, remap = false },
        { 'tda', function() dap.restart() end, desc = 'Restart', nowait = false, remap = false },
        { 'tdx', function() dap.terminate() end, desc = 'Terminate', nowait = false, remap = false },
        { 'tdl', function() dap.run_last() end, desc = 'Run Last' },

        { 'tdk', function() dap.up() end, desc = 'Go up the stack frame', nowait = false, remap = false },
        { 'tdj', function() dap.down() end, desc = 'Go down the stack frame', nowait = false, remap = false },
        { 'tdi', function() dap.step_into() end, desc = 'Step Into', nowait = false, remap = false },
        { 'tdu', function() dap.step_out() end, desc = 'Step Out', nowait = false, remap = false },
        { 'tdo', function() dap.step_over() end, desc = 'Step Over', nowait = false, remap = false },
        { 'tdd', function() dap.focus_frame() end, desc = 'Focus current frame', nowait = false, remap = false },

        { 'tde', function() dapui.eval(); dapui.eval() end, desc = 'Evaluate', nowait = false, remap = false },

        { 'tdh', function() require('dap.ui.widgets').hover() end, desc = 'Hover Variables', nowait = false, remap = false },
        { 'tdr', function() float_debug_console() end, desc = 'Toggle Repl', nowait = false, remap = false },
        { 'tdw', function() float_debug_watches() end, desc = 'Toggle Watch', nowait = false, remap = false },
        { 'tdU', function() dapui.toggle() end, desc = 'Toggle UI', nowait = false, remap = false },

        { 'tdb', "<cmd>Telescope dap list_breakpoints<cr>", desc = 'Telescope list breakpoints', nowait = false, remap = false },
        { 'tdf', "<cmd>Telescope dap frames<cr>", desc = 'Telescope frames', nowait = false, remap = false },
        { 'tdv', '<cmd>Telescope dap variables<cr>', desc = 'Telescope list variables', nowait = false, remap = false },

        -- { 'tdC', function() dap.run_to_cursor() end, desc = 'Run to Cursor' },
        -- { 'tdg', function() dap.goto_() end, desc = 'Go to Line (No Execute)' },
        -- { 'tdP', function() dap.pause() end, desc = 'Pause' },
        -- { 'tdr', function() dap.repl.toggle() end, desc = 'Toggle REPL' },
        -- { 'tds', function() dap.session() end, desc = 'Session' },
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
