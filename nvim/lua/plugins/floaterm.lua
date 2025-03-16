local vim = vim ---@diagnostic disable-line: undefined-global

local keymaps = require('user.keymaps.bind')
local nnoremap = keymaps.nnoremap
local tnoremap = keymaps.tnoremap
local long_press_aware_keybinding = require('user.keymaps.long_press').long_press_aware_keybinding

return {
  {
    'voldikss/vim-floaterm',
    config = function()
      vim.g.floaterm_shell = 'fish'
      vim.g.floaterm_wintype = 'float'
      vim.g.floaterm_borderchars = '─│─│╭╮╯╰'
      vim.g.floaterm_width = 0.9
      vim.g.floaterm_height = 0.8

      nnoremap('<leader>tt', ':FloatermToggle<CR>', { desc = 'Show [T]erminal' })
      tnoremap('<leader>tt', '<C-\\><C-n>:FloatermToggle<CR>', { desc = 'Hide [T]erminal' })

      nnoremap('<leader>tg', ':FloatermNew lazygit<CR>', { desc = 'Lazy[G]it' })
      nnoremap('<leader>td', ':FloatermNew! --height=0.9 --width=0.95 --wintype=float --name=gtasks --position=bottom gtasks tasks view --tasklist "Reclaim.ai"<CR>', { desc = 'Google Tasks (TO[D]O)' })

      nnoremap('<leader>tn', ':FloatermNew<CR>', { desc = '[N]ew Terminal' })
      tnoremap('<leader>tn', '<C-\\><C-n>:FloatermNew<CR>', { desc = '[N]ew Terminal' })

      tnoremap('<C-PageDown>', '<C-\\><C-n>:FloatermNext<CR>', { desc = 'Next Terminal' })
      tnoremap('<C-PageUp>', '<C-\\><C-n>:FloatermPrev<CR>', { desc = 'Previous Terminal' })
      tnoremap('<leader>ty', '<C-\\><C-n>:FloatermNext<CR>', { desc = 'Next Terminal' })
      tnoremap('<leader>tr', '<C-\\><C-n>:FloatermPrev<CR>', { desc = 'Previous Terminal' })
      tnoremap('>>', '<C-\\><C-n>:FloatermNext<CR>', { desc = 'Next Terminal' })
      tnoremap('<<', '<C-\\><C-n>:FloatermPrev<CR>', { desc = 'Previous Terminal' })

      -- Check if any floating terminal is open
      local function is_floaterm_open()
        for _, wid in ipairs(vim.api.nvim_list_wins()) do
          local window = vim.api.nvim_win_get_config(wid)
          local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(wid))

          if name:find("term://.*") and window.zindex ~= nil then
            return true
          end
        end
        return false
      end

      -- Export functions globally
      _G.FloatermIsOpen = is_floaterm_open

      -- Double-Esc to exit insert mode
      -- tnoremap('<Esc><Esc>', '<Esc><Esc><C-\\><C-n>')

      -- Press Esc multiple times to exit insert mode
      -- Allows for immediately sending Esc through
      long_press_aware_keybinding('t', '<Esc>', function()
        vim.api.nvim_input('<C-\\><C-n>')
      end, 200, { noremap = true, silent = true })

      -- CTRL-WQ to hide terminal
      tnoremap('<C-w><C-q>', '<C-\\><C-n><C-w><C-q>')
    end,
  }
}
