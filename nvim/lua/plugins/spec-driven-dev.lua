-- Spec-driven development workflow plugin
-- Integrates with Claude for automated task generation and code implementation
-- Uses existing neotest, git tools, and formatting configurations

local nnoremap = require('user.keymaps.bind').nnoremap

return {
  -- Main spec-driven development configuration
  {
    dir = vim.fn.stdpath('config') .. '/lua/user/extensions/spec-driven.lua',
    name = 'spec-driven',
    priority = 1000,
    config = function()
      local spec_driven = require('user.extensions.spec-driven')

      -- Setup with custom configuration
      spec_driven.setup({
        -- Custom directory structure
        features_dir = "features",
        spec_dir = "specs",

        -- Language-specific commands
        linters = {
          ruby = "bundle exec rubocop",
          javascript = "npx eslint",
          typescript = "npx eslint",
          python = "flake8",
        },

        test_runners = {
          ruby = "bundle exec rspec",
          javascript = "npm test",
          typescript = "npm test",
          python = "pytest",
        },

        -- Claude configuration
        claude_model = "claude-3-5-sonnet-20241022",
        max_tokens = 4000,
      })

      -- Key mappings for spec-driven development
      local function setup_keymaps()
        -- Feature management
        nnoremap('<leader>fn', function()
          spec_driven.create_feature()
        end, { desc = 'Create new feature' })

        nnoremap('<leader>fo', function()
          spec_driven.open_feature_files()
        end, { desc = 'Open feature files' })

        -- Claude integration
        nnoremap('<leader>st', function()
          spec_driven.spec_to_tasks()
        end, { desc = 'Generate tasks from spec' })

        nnoremap('<leader>tc', function()
          spec_driven.task_to_code()
        end, { desc = 'Generate code from task' })

        -- Test integration (using existing neotest keymaps: trt, trf, trA, trs, tro)

        -- Quick file navigation within features
        nnoremap('<leader>fs', function()
          local feature = spec_driven.get_current_feature()
          if feature then
            vim.cmd('edit features/' .. feature .. '/spec.md')
          end
        end, { desc = 'Open feature spec' })

        nnoremap('<leader>ft', function()
          local feature = spec_driven.get_current_feature()
          if feature then
            vim.cmd('edit features/' .. feature .. '/tasks.md')
          end
        end, { desc = 'Open feature tasks' })

        nnoremap('<leader>fd', function()
          local feature = spec_driven.get_current_feature()
          if feature then
            vim.cmd('edit features/' .. feature .. '/design.md')
          end
        end, { desc = 'Open feature design' })
      end

      -- Set up keymaps
      setup_keymaps()

      -- Auto-commands for enhanced workflow
      local group = vim.api.nvim_create_augroup("SpecDrivenWorkflow", { clear = true })

      -- Auto-save when switching between feature files
      vim.api.nvim_create_autocmd("BufLeave", {
        group = group,
        pattern = { "*/features/*/*.md", "*/features/*/*.rb", "*/features/*/*.js", "*/features/*/*.ts" },
        callback = function()
          if vim.bo.modified then
            vim.cmd("silent! write")
          end
        end
      })

      -- Highlight TODO/FIXME/NOTE comments in spec files
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        pattern = { "*/features/*/spec.md", "*/features/*/tasks.md", "*/features/*/design.md" },
        callback = function()
          vim.fn.matchadd("Todo", "TODO\\|FIXME\\|NOTE\\|HACK")
        end
      })

      -- Auto-format tasks.md on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        pattern = "*/features/*/tasks.md",
        callback = function()
          -- Sort completed tasks to bottom
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local uncompleted = {}
          local completed = {}

          for _, line in ipairs(lines) do
            if line:match("^%s*- %[x%]") or line:match("^%s*- %[X%]") then
              table.insert(completed, line)
            else
              table.insert(uncompleted, line)
            end
          end

          -- Only reorder if we have both types
          if #uncompleted > 0 and #completed > 0 then
            local reordered = {}
            vim.list_extend(reordered, uncompleted)
            if #completed > 0 then
              table.insert(reordered, "")
              table.insert(reordered, "## Completed")
              table.insert(reordered, "")
              vim.list_extend(reordered, completed)
            end

            vim.api.nvim_buf_set_lines(0, 0, -1, false, reordered)
          end
        end
      })

      -- Status line integration
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
        group = group,
        pattern = { "*/features/*/*.md", "*/features/*/*.rb", "*/features/*/*.js", "*/features/*/*.ts" },
        callback = function()
          local current_feature = spec_driven.get_current_feature()
          if current_feature then
            vim.g.current_feature = current_feature
          end
        end
      })
    end,
  },
}
