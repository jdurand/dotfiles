local utils = require('user.utils')
local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim'
    },
    config = function()
      local telescope = require('telescope')
      local scope = require('telescope.builtin')

      telescope.setup {
        defaults = vim.tbl_extend(
          'force',
          require('telescope.themes').get_dropdown(), -- or get_cursor, get_ivy
          {
            --- your own `default` options go here, e.g.:
            path_display = {
              truncate = 2
            },
            -- mappings = {
            --   i = {
            --     ["<esc>"] = actions.close,
            --   },
            -- }
          }
        ),
        pickers = { -- dropdown | ivy | cursor | compact
          -- buffers = { theme = 'dropdown' },
          -- find_files = { theme = 'dropdown' },
          -- git_status = { theme = 'dropdown' },
          git_commits = { theme = 'ivy' },
          keymaps = { theme = 'ivy' },
          live_grep = { theme = 'ivy' },
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
        utils.assert_git_repo(scope.git_status)
        vim.api.nvim_input('<ESC>')
      end, { desc = "Find [G]it Status" })

      nnoremap('<leader>;', function()
        -- scope.buffers()
        -- use unscoped buffers instead
        local unscoped = require('telescope').extensions.scope

        unscoped.buffers({
          attach_mappings = function(_, map)
            map({ 'n', 'i' }, '<C-c>', function(--[[ prompt_bufnr ]])
              -- local actions = require('telescope.actions')
              local action_state = require('telescope.actions.state')
              local selection = action_state.get_selected_entry()

              -- actions.close(prompt_bufnr) -- close the Telescope interface
              if selection and selection.bufnr then
                vim.api.nvim_buf_delete(selection.bufnr, { force = true })
                unscoped.buffers() -- reload bufders
              end
            end)
            return true
          end
        })
        vim.api.nvim_input('<Esc>')
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
