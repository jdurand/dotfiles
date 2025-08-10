local vim = vim ---@diagnostic disable-line: undefined-global

local keymaps = require('user.keymaps.bind')
local nnoremap = keymaps.nnoremap
local tnoremap = keymaps.tnoremap
local long_press_aware_keybinding = require('user.keymaps.long_press').long_press_aware_keybinding

return {
  {
    'voldikss/vim-floaterm',
    config = function()
      -- vim.g.floaterm_shell = 'fish'
      -- Automatically run direnv reload in each new Floaterm
      vim.g.floaterm_shell = 'fish --init-command "direnv reload >/dev/null ^&1"'
      -- vim.g.floaterm_shell = 'zsh -c "direnv reload; exec zsh"'
      -- vim.g.floaterm_shell = 'bash -c "direnv reload; exec bash"'
      vim.g.floaterm_wintype = 'float'
      vim.g.floaterm_borderchars = '─│─│╭╮╯╰'
      vim.g.floaterm_width = 0.9
      vim.g.floaterm_height = 0.8

      nnoremap('<leader>tt', ':FloatermToggle<CR>', { desc = 'Show [T]erminal' })
      nnoremap('<leader>tT', function()
        -- Check if we're inside tmux
        if vim.env.TMUX then
          -- Check if a popup already exists
          local popup_exists = vim.fn.system('tmux list-panes -F "#{pane_id}" -f "#{popup_pane}"'):match('%S')

          if not popup_exists then
            -- No popup exists, create one
            local cwd = vim.fn.getcwd()
            local session_name = 'scratch-terminal-popup'
            vim.fn.system('tmux display-popup -w 90% -h 90% -d "' .. cwd .. '" -E "tmux new-session -A -s ' .. session_name .. '"')
          end
        else
          -- Fallback to floaterm if not in tmux
          vim.cmd('FloatermToggle')
        end
      end, { desc = 'Show [T]erminal' })
      tnoremap('<leader>tt', '<C-\\><C-n>:FloatermToggle<CR>', { desc = 'Hide [T]erminal' })

      nnoremap('<leader>tg', function()
        -- Check if we're inside tmux
        if vim.env.TMUX then
          local cwd = vim.fn.getcwd()
          vim.fn.system('tmux display-popup -d "' .. cwd .. '" -w 90% -h 90% -E lazygit')
        else
          -- Fallback to floaterm if not in tmux
          vim.cmd('FloatermNew lazygit')
        end
      end, { desc = 'Lazy[G]it' })

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
