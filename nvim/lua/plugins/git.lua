local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',         -- required
      'sindrets/diffview.nvim',        -- optional - Diff integration

      -- Only one of these is needed, not both.
      'nvim-telescope/telescope.nvim', -- optional
      -- 'ibhagwan/fzf-lua',              -- optional
    },
    config = function()
      require('neogit').setup({})

      nnoremap('<leader>gn', function()
        require('neogit').open({ kind = 'split_above' })
      end, { desc = "Open [N]eoGit" })
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    config = function()
      require('gitsigns').setup({
        current_line_blame = true,

        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          -- Actions
          map('n', '<leader>hs', gs.stage_hunk)
          map('n', '<leader>hr', gs.reset_hunk)
          map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          map('n', '<leader>hS', gs.stage_buffer)
          map('n', '<leader>hu', gs.undo_stage_hunk)
          map('n', '<leader>hR', gs.reset_buffer)
          map('n', '<leader>hp', gs.preview_hunk)
          map('n', '<leader>hb', function() gs.blame_line{full=true} end)
          -- map('n', '<leader>tb', gs.toggle_current_line_blame)
          map('n', '<leader>hd', gs.diffthis)
          map('n', '<leader>hD', function() gs.diffthis('~') end)
          -- map('n', '<leader>td', gs.toggle_deleted)

          -- Text object
          map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end,
      })
    end,
  },
  {
    'pwntester/octo.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      -- OR 'ibhagwan/fzf-lua',
      -- OR 'folke/snacks.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = function ()
      if vim.fn.executable('gh') == 1 then
        require('octo').setup()
      else
        vim.notify('GitHub CLI (gh) not found — skipping octo.nvim setup', vim.log.levels.WARN)
      end
    end
  },
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },

    config = function()
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
        callback = function(args)
          local bufnr = args.buf
          local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

          for _, line in ipairs(content) do
            if line:match('^<<<<<<<') or line:match('^=======$') or line:match('^>>>>>>>') then
              vim.cmd('DiffviewOpen')
              break
            end
          end
        end,
      })

      -- vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
      vim.api.nvim_create_autocmd('BufWinEnter', {
        callback = function(args)
          if vim.bo[args.buf].filetype:match('^Diffview') then
            -- Get all buffers in the current window
            -- local buffers = vim.api.nvim_list_bufs()

            -- Get all buffers in the current tab
            local buffers = vim.api.nvim_list_bufs()
            local current_tabpage = vim.api.nvim_get_current_tabpage()
            local tab_buffers = {}

            for _, buf in ipairs(buffers) do
              if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_tabpage_get_win(current_tabpage) == vim.api.nvim_get_current_win() then
                table.insert(tab_buffers, buf)
              end
            end

            -- Define the keybindings
            local keybindings = {
              { 'n', '<C-f>', ':DiffviewToggleFiles<CR>', { desc = "Toggle Files" } },
              { 'n', 'co', ':diffget LOCAL<CR>', { desc = "Choose Ours (OURS)" } },
              { 'n', 'ct', ':diffget REMOTE<CR>', { desc = "Choose Theirs (THEIRS)" } },
              { 'n', 'cc', ':diffget<CR>', { desc = "Choose under Cursor" } },
              { 'n', 'ca', ':argdo %diffget REMOTE<CR>', { desc = "Choose All (THEIRS)" } },
              { 'n', 'c0', 'u', { desc = "Choose None (Undo)" } },
              { 'n', 'cb', ':diffput<CR>', { desc = "Choose Both (put current into other)" } },
            }

            -- Apply keybindings to each buffer in the window
            for _, buf in ipairs(buffers) do
              for _, keymap in ipairs(keybindings) do
                vim.api.nvim_buf_set_keymap(buf, keymap[1], keymap[2], keymap[3], keymap[4])
              end
            end
          end
        end,

        -- callback = function(args)
        --   vim.notify(vim.wo.diff == true and "Diff mode is enabled" or "Diff mode is disabled")
        --   vim.notify(vim.bo[args.buf].filetype)
        --
        --   if vim.bo[args.buf].filetype:match('^Diffview') then
        --   -- if vim.bo[args.buf].filetype == 'diff' or vim.b.diffview_view ~= nil then
        --     nnoremap('<C-f>', ':DiffviewToggleFiles<CR>', { desc = "Toggle Files", buffer = args.buf })
        --
        --     nnoremap('co', ':DiffviewFilePanelToggle<CR>:diffget LOCAL<CR>', { desc = "Choose Ours (LOCAL)", buffer = args.buf })
        --     nnoremap('ct', ':DiffviewFilePanelToggle<CR>:diffget REMOTE<CR>', { desc = "Choose Theirs (REMOTE)", buffer = args.buf })
        --     nnoremap('cc', ':DiffviewFilePanelToggle<CR>:diffget<CR>',        { desc = "Choose under Cursor", buffer = args.buf })
        --     nnoremap('ca', ':DiffviewFilePanelToggle<CR>:argdo %diffget REMOTE<CR>', { desc = "Choose All (REMOTE)", buffer = args.buf })
        --     nnoremap('c0', 'u',                   { desc = "Choose None (Undo)", buffer = args.buf })
        --     nnoremap('cb', ':DiffviewFilePanelToggle<CR>:diffput<CR>',       { desc = "Choose Both (put current into other)", buffer = args.buf })
        --
        --     if package.loaded['noice'] then
        --       require('noice').notify(
        --         'Diffview Key Bindings:\n' ..
        --         'co: Choose Ours (LOCAL)\n' ..
        --         'ct: Choose Theirs (REMOTE)\n' ..
        --         'ca: Choose All (REMOTE)\n' ..
        --         'c0: Choose None (Undo)\n' ..
        --         'cb: Choose Both (diffput)\n' ..
        --         'cc: Choose under Cursor',
        --         'info',
        --         { title = 'Diff Merge Bindings' }
        --       )
        --     end
        --   end
        -- end,
      })
    end
  },
  {
    'akinsho/git-conflict.nvim',
    config = function()
      -- exclude diffview from conflict highlighting
      vim.api.nvim_create_autocmd('BufWinEnter', {
        pattern = '*',
        callback = function()
          if vim.bo.filetype:match('^Diffview') then
            vim.b.git_conflict_disabled = true
          end
        end
      })
    end,
  },
  {
    'petertriho/cmp-git',
    dependencies = { 'hrsh7th/nvim-cmp' },
    opts = {
      -- options go here
    },
    init = function()
      local cmp_config = require('cmp').get_config()
      table.insert(cmp_config.sources, { name = 'git' })
    end
  },
  {
    -- 'ThePrimeagen/git-worktree.nvim',
    'AndresYague/git-worktree.nvim',
    init = function()
      require('telescope').load_extension('git_worktree')
    end,
    config = function()
      nnoremap('<leader>gw', function()
        require('telescope').extensions.git_worktree.git_worktrees()
      end, { desc = "Git [W]orktrees" })
    end
  }
}
