local keymap = require('user.keymaps.bind')
local nnoremap = keymap.nnoremap
local xnoremap = keymap.xnoremap

return {
  {
    'numToStr/Comment.nvim',
    lazy = false,
    opts = {
        -- add any options here
    },
    config = function()
      local api = require('Comment.api')
      local esc = vim.api.nvim_replace_termcodes(
        '<escape>', true, false, true
      )

      local function toggle_comment(mode, type)
        vim.api.nvim_feedkeys(esc, 'nx', false)
        if mode == 'n' then
          api.toggle[type].current()
        else
          api.toggle[type](vim.fn.visualmode())
        end
      end

      nnoremap('<Leader>cc', function() toggle_comment('n', 'linewise') end)
      nnoremap('<Leader>bc', function() toggle_comment('n', 'blockwise') end)
      xnoremap('<leader>cc', function() toggle_comment('x', 'linewise') end)
      xnoremap('<leader>bc', function() toggle_comment('x', 'blockwise') end)
    end,
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
      }
    end
  },
}
