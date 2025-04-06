return {
  'stevearc/overseer.nvim',
  opts = {},
  config = function()
    local overseer = require('overseer')
    local whichkey = require('which-key')

    overseer.setup({
      dap = true,
      task_list = {
        bindings = {
          ['<C-l>'] = false,
          ['<C-h>'] = false,
          ['<C-u>'] = 'ScrollOutputUp',
          ['<C-d>'] = 'ScrollOutputDown',
          ['k'] = 'PrevTask',
          ['j'] = 'NextTask',
          ['l'] = 'IncreaseDetail',
          ['h'] = 'DecreaseDetail',
          ['<C-c>'] = '<cmd>OverseerQuickAction dispose<cr>',
        },
      },
    })

    whichkey.add({
      { '<leader>o', group = '[O]verseer' },
      { '<leader>oo', '<cmd>OverseerToggle<cr>',      desc = 'Task list' },
      { '<leader>or', '<cmd>OverseerRun<cr>',         desc = 'Run task' },
      { '<leader>oq', '<cmd>OverseerQuickAction<cr>', desc = 'Action recent task' },
      { '<leader>oi', '<cmd>OverseerInfo<cr>',        desc = 'Overseer Info' },
      { '<leader>ob', '<cmd>OverseerBuild<cr>',       desc = 'Task builder' },
      { '<leader>ot', '<cmd>OverseerTaskAction<cr>',  desc = 'Task action' },
      { '<leader>oc', '<cmd>OverseerClearCache<cr>',  desc = 'Clear cache' },
    })
  end,
}
