local utils = require('user.utils')
local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = {
      'nvim-lua/plenary.nvim'
    },
    config = function()
      local telescope = require('telescope')
      local scope = require('telescope.builtin')

      telescope.setup {
        pickers = {
          buffers = { theme = 'dropdown' },
          find_files = { theme = 'dropdown' },
          git_files = {
            theme = 'dropdown',
            git_command = {'git', 'diff', '--name-status', '@'},
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,                    -- false will only do exact matching
            override_generic_sorter = true,  -- override the generic sorter
            override_file_sorter = true,     -- override the file sorter
            case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                             -- the default case_mode is "smart_case"
          }
        },
      }

      nnoremap('<leader>ff', scope.find_files, { desc = "Find [F]iles" })
      nnoremap('<leader>fg', scope.live_grep, { desc = "Find Live [G]rep" })
      nnoremap('<leader>fk', scope.keymaps, { desc = "Find [K]eymaps" })
      nnoremap('<leader>fh', scope.help_tags, { desc = "Find [H]elp" })

      nnoremap('<leader>gc', function() utils.assert_git_repo(scope.git_commits) end, { desc = "Find Git [C]ommits" })
      nnoremap('<leader>gg', function()
        utils.assert_git_repo(scope.git_files)
        vim.api.nvim_input('<ESC>')
      end, { desc = "Find [G]it Files" })

      nnoremap('<leader>;', function()
        -- scope.buffers()
        -- use scoped buffers instead
        require('telescope').extensions.scope.buffers()
        vim.api.nvim_input('<ESC>')
      end, { desc = "Find Buffers" })
    end,
  },
  -- improve fuzzy find performance
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension('fzf')
    end,
  },
  -- ensure buffers are scoped to tabs
  {
    'tiagovla/scope.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('scope').setup({})
      require('telescope').load_extension('scope')
    end,
  },
}
