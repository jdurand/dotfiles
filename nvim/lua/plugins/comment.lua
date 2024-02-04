return {
  {
    'numToStr/Comment.nvim',
    lazy = false,
    opts = {
        -- add any options here
    },
    config = function()
      require('Comment').setup({
        -- ignore = '^$',
        -- toggler = {
        --   line = '<leader>cc',
        --   block = '<leader>bc',
        -- },
        -- opleader = {
        --   line = '<leader>c',
        --   block = '<leader>b',
        -- },
      })

      -- vim.keymap.set("n", "<Leader>cc", function() require('Comment.api').toggle.linewise.current() end, { noremap = true, silent = true })
      -- vim.keymap.set("n", "<Leader>bc", function() require('Comment.api').toggle.blockwise.current() end, { noremap = true, silent = true })
    end,
  },
  'tpope/vim-commentary', -- couldn’t figure out how to map <leader>cc using Comment.nvim
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
      }
    end
  },
}
