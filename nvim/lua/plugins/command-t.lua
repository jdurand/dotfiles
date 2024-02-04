return {
  {
    'wincent/command-t',
    -- lazy = false,
    -- branch = '5-x-release',
    build = 'cd lua/wincent/commandt/lib && make && cd - && cd ruby/command-t/ext/command-t && ruby extconf.rb && make',
    init = function ()
      -- vim.g.CommandTPreferredImplementation = 'ruby'
      vim.g.CommandTPreferredImplementation = 'lua'
    end,
    config = function()
      require('wincent.commandt').setup({
        -- Customizations go here.
      })
    end,
  },
}
