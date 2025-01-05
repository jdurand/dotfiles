return {
  'stevearc/overseer.nvim',
  opts = {},
  config = function()
    local whichkey = require('which-key')

    require('overseer').setup({
      dap = true,
      task_list = {
        bindings = {
          ['<C-l>'] = false,
          ['<C-h>'] = false,
          ['l'] = 'IncreaseDetail',
          ['h'] = 'DecreaseDetail',
          ['<C-u>'] = 'ScrollOutputUp',
          ['<C-d>'] = 'ScrollOutputDown',
        },
      },
    })

    whichkey.add({
      { '<leader>o', group = '[O]verseer' },
      { '<leader>ow', '<cmd>OverseerToggle<cr>',      desc = 'Task list' },
      { '<leader>oo', '<cmd>OverseerRun<cr>',         desc = 'Run task' },
      { '<leader>oq', '<cmd>OverseerQuickAction<cr>', desc = 'Action recent task' },
      { '<leader>oi', '<cmd>OverseerInfo<cr>',        desc = 'Overseer Info' },
      { '<leader>ob', '<cmd>OverseerBuild<cr>',       desc = 'Task builder' },
      { '<leader>ot', '<cmd>OverseerTaskAction<cr>',  desc = 'Task action' },
      { '<leader>oc', '<cmd>OverseerClearCache<cr>',  desc = 'Clear cache' },
    })
  end,
}
