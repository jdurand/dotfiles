local whichkey = require('which-key')
local keymaps = require('user.keymaps.bind')
local nnoremap, nmap, vnoremap = keymaps.nnoremap, keymaps.nmap, keymaps.vnoremap

-- Define group keybindings
-- ----------------------------------------------------------------------------------------------------
whichkey.add({
  { '<leader>', group = '<leader>' },
  { '<leader>a', group = '[A]I' }, { '<leader>a_', hidden = true },
  { '<leader>c', group = '[C]ode' }, { '<leader>c_', hidden = true },
  { '<leader>d', group = '[D]ocument' }, { '<leader>d_', hidden = true },
  { '<leader>f', group = '[F]ind' }, { '<leader>f_', hidden = true },
  { '<leader>g', group = '[G]it/Chat[G]PT' }, { '<leader>g_', hidden = true },
  { '<leader>h', group = '[H]arpoon' }, { '<leader>h_', hidden = true },
  { '<leader>r', group = '[R]ename' }, { '<leader>r_', hidden = true },
  { '<leader>t', group = '[T]ab/[T]erminal' }, { '<leader>t_', hidden = true },
  { '<leader>w', group = '[W]ork' }, { '<leader>w_', hidden = true },
  { '<leader>y', group = '[Y]anky' }, { '<leader>y_', hidden = true },

  { '<leader>wn', group = 'New feature' }, { '<leader>wn_', hidden = true },
  { '<leader>wo', group = 'Open feature' }, { '<leader>wo_', hidden = true },
  { '<leader>wg', group = 'Generate feature' }, { '<leader>wg_', hidden = true },

  { '<leader>b', hidden = true },
  { '<leader>e', hidden = true },
  { '<leader>n', hidden = true },
  { '<leader>p', hidden = true },
})

whichkey.add({
  { '<leader>', group = '<leader>', mode = 'v' },
})

-- Define the ZenMode keybind here to prevent conflicts
-- with `config` block options in the plugin file
-- ----------------------------------------------------------------------------------------------------
nnoremap('<leader>z', function()
  require('zen-mode').toggle({
    window = {
      width = .85 -- width will be 85% of the editor width
    }
  })
end, { desc = 'Open in [Z]en Mode' })

-- Other custom keymaps
-- ----------------------------------------------------------------------------------------------------
nmap('<leader>yf', function() vim.fn.setreg('*', vim.fn.expand('%')) end, { desc = 'Copy [f]ile path to clipboard' })

nnoremap('gb', function() require('user.utils').web_browser() end, { desc = 'Open link in web [b]rowser' })
nnoremap('gB', function() require('user.utils').web_browser({ fallback_url = 'https://chatgpt.com/?hints=search' }) end, { desc = 'Open web [B]rowser' })

-- Yank selected text on left mouse release
-- ----------------------------------------------------------------------------------------------------
vnoremap('<LeftRelease>', '"*ygv<escape>', { desc = 'Yank on mouse selection' })

-- Easy new lines
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('n', 'ø', 'mo<Esc>o<Esc>k`o', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'Ø', 'mo<Esc>O<Esc>j`o', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'K', '<Esc>i<CR><Esc><Esc>', { noremap = true })

-- Save with CTRL-S
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('n', '<C-S>', ':update<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-S>', '<C-C>:update<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-S>', '<C-O>:update<CR>', { noremap = true, silent = true })

-- Always go to the mark’s line and column
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('n', "'", "`", { noremap = true })
vim.api.nvim_set_keymap('v', "'", "`", { noremap = true })
vim.api.nvim_set_keymap('n', 'g\'', 'g`', { noremap = true })
vim.api.nvim_set_keymap('v', 'g\'', 'g`', { noremap = true })

-- Remap ^ characters
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('n', 'â', '^a', { noremap = true })
vim.api.nvim_set_keymap('n', 'î', '^i', { noremap = true })
vim.api.nvim_set_keymap('n', 'ô', '^o', { noremap = true })

-- Add new Text Objects
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('o', 'i/', ':normal T/vt/<CR>', { noremap = true })
vim.api.nvim_set_keymap('v', 'i/', 't/oT/', { noremap = true })
vim.api.nvim_set_keymap('o', 'a/', ':normal F/vf/<CR>', { noremap = true })
vim.api.nvim_set_keymap('v', 'a/', 'f/oF/', { noremap = true })
vim.api.nvim_set_keymap('o', 'i|', ':normal T|vt|<CR>', { noremap = true })
vim.api.nvim_set_keymap('v', 'i|', 't|oT|', { noremap = true })
vim.api.nvim_set_keymap('o', 'a|', ':normal F|vf|<CR>', { noremap = true })
vim.api.nvim_set_keymap('v', 'a|', 'f|oF|', { noremap = true })

-- Remap Enter and Backspace
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('v', '<C-M>', '<NOP>', { noremap = true }) -- This maps the Enter key in visual mode
vim.api.nvim_set_keymap('v', '<BS>', 'dk$', { noremap = true })

-- -- Easy line moving
-- -- ----------------------------------------------------------------------------------------------------
-- vim.api.nvim_set_keymap('v', '<M-j>', 'djPV`]', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('v', '<M-k>', 'dkPV`]', { noremap = true, silent = true })

-- Select only the text characters in the current line
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('n', '<M-v>', '^v$h', { noremap = true })

-- Easy indentation in visual mode
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true })
vim.api.nvim_set_keymap('v', '>', '>gv|', { noremap = true })
vim.api.nvim_set_keymap('v', '<Tab>', '>gv|', { noremap = true })
vim.api.nvim_set_keymap('v', '<S-Tab>', '<gv', { noremap = true })
vim.api.nvim_set_keymap('n', '<Tab>', 'mzV>`zl', { noremap = true })
vim.api.nvim_set_keymap('n', '<S-Tab>', 'mzV<`zh', { noremap = true })

-- Clear search-highlighted terms and dismiss Noice messages
-- ----------------------------------------------------------------------------------------------------
vim.keymap.set('n', '\\', function()
  -- Clears highlighted search results.
  vim.cmd('silent noh')
  -- Clears the command-line by echoing an empty string.
  vim.cmd('echo')
  -- Dismiss active noice notifications.
  require('noice').cmd('dismiss')
  -- -- Clears existing code completion suggestion.
  -- require('neocodeium').clear()
end, { noremap = true, silent = true })

-- Use Alt-4 to go to the end of the line, but not totally.
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('v', '¢', '$h', { noremap = true })

-- Search and replace visually selected text
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('v', '<C-r>', '"hy:%s/<C-r>h//g<left><left>', { noremap = true })

-- Buffer navigation and splits
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('n', '<C-c>', ':bp|bd #<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>=', ':vsplit<CR><C-w>l', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>l', ':vsplit<CR><C-w>l', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>-', ':split<CR><C-w>j', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>j', ':split<CR><C-w>j', { noremap = true })

-- Tag navigation
-- ----------------------------------------------------------------------------------------------------
vim.api.nvim_set_keymap('n', '<C-]>', ':tag <C-r><C-w><CR>', { noremap = true })

-- Restore default behavior for Ctrl+i since Tmux overrides it
-- Remaped C-i to A-i in the terminal emulator configuration
vim.keymap.set('n', '<C-i>', '<C-i>', { noremap = true, silent = true })
vim.keymap.set('n', '<A-i>', '<C-i>', { noremap = true, silent = true })
