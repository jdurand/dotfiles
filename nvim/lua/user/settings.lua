-- Enable automatic reloading of files when they change on disk
vim.o.autoread = true

-- Disable line breaking for long lines
vim.opt.wrap = false
vim.opt.linebreak = false

-- Movement wrapping at line ends.
vim.opt.whichwrap:append('h,l')

-- Indent
vim.opt.expandtab = true    -- Use spaces instead of tabs
vim.opt.shiftwidth = 2      -- Number of spaces for autoindent
vim.opt.tabstop = 2         -- Number of spaces a <Tab> appears as
vim.opt.softtabstop = 2     -- Number of spaces when editing
vim.opt.autoindent = true   -- Copy indentation from the current line

-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = 'python',
--   callback = function()
--     vim.opt_local.expandtab = true
--     vim.opt_local.shiftwidth = 4
--     vim.opt_local.tabstop = 4
--   end,
-- })

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true
vim.o.relativenumber = true

-- -- Disable mouse mode
-- vim.o.mouse = ''

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

--vim.cmd()
vim.opt.clipboard = 'unnamedplus'

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- -- Create an autocommand that triggers on specific events
-- vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
--   -- Check for file updates unless in insert mode
--   command = "if mode() != 'c' | checktime | endif",
--   pattern = { "*" }, -- Apply to all file types
-- })

-- Create a user command 'Q' to close all buffers and exit Neovim
vim.api.nvim_create_user_command('Q', 'qall', {})
vim.api.nvim_create_user_command('QQ', 'qall!', {})
vim.api.nvim_create_user_command('WQ', 'wqall!', {})
