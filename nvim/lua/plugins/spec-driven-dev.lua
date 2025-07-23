-- Spec-driven development workflow plugin
-- Integrates with Claude for automated task generation and code implementation
-- Uses existing neotest, git tools, and formatting configurations

local bind = require('user.keymaps.bind')
local nnoremap = bind.nnoremap
local tnoremap = bind.tnoremap

-- Load and configure the spec-driven development extension
local spec_driven = require('user.extensions.spec-driven')

-- Setup with custom configuration
spec_driven.setup({
  -- Custom directory structure
  features_dir = "features",

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

  -- Jira credentials loaded from environment variables for security
  -- Set these in your shell: export JIRA_BASE_URL="https://company.atlassian.net"
  --                         export JIRA_EMAIL="your-email@company.com"
  --                         export JIRA_API_TOKEN="your-api-token"
})

-- Key mappings for spec-driven development
local function setup_keymaps()
  -- Feature management
  nnoremap('<leader>wnf', function()
    spec_driven.create_feature_interactive()
  end, { desc = 'Create new feature' })

  nnoremap('<leader>wnj', function()
    spec_driven.create_feature_from_jira()
  end, { desc = 'Create feature from Jira ticket' })

  nnoremap('<leader>ww', function()
    spec_driven.start_work()
  end, { desc = 'Start work on Jira ticket' })

  -- Claude integration
  nnoremap('<leader>wgt', function()
    spec_driven.generate_task_list()
  end, { desc = 'Generate tasks from spec' })

  nnoremap('<leader>wgc', function()
    spec_driven.task_to_code()
  end, { desc = 'Generate code from current task' })

  nnoremap('<leader>wga', function()
    spec_driven.generate_all_code()
  end, { desc = 'Generate code for all tasks' })

  -- Quick file navigation within features
  nnoremap('<leader>woa', function()
    spec_driven.open_feature_files()
  end, { desc = 'Open feature files' })

  nnoremap('<leader>wol', function()
    spec_driven.list_features()
  end, { desc = 'List available features' })

  nnoremap('<leader>wos', function()
    local feature = spec_driven.get_current_feature()
    if feature then
      vim.cmd('edit features/' .. feature .. '/spec.md')
      -- Check if feature was found via branch detection and show feedback
      local current_file = vim.fn.expand("%:p")
      local in_feature_dir = current_file:match("/features/([^/]+)/")
      if not in_feature_dir then
        print("🎯 Opened spec for feature '" .. feature .. "' (detected from git branch)")
      end
    else
      print("❌ No feature found. Use :CreateFeatureFromJira or :CreateFeature")
      vim.notify("No feature found. Use :CreateFeatureFromJira or :CreateFeature", vim.log.levels.ERROR, { title = "Spec-Driven Development" })
    end
  end, { desc = 'Open feature spec' })

  nnoremap('<leader>wot', function()
    local feature = spec_driven.get_current_feature()
    if feature then
      vim.cmd('edit features/' .. feature .. '/tasks.md')
      -- Check if feature was found via branch detection and show feedback
      local current_file = vim.fn.expand("%:p")
      local in_feature_dir = current_file:match("/features/([^/]+)/")
      if not in_feature_dir then
        print("🎯 Opened tasks for feature '" .. feature .. "' (detected from git branch)")
      end
    else
      print("❌ No feature found. Use :CreateFeatureFromJira or :CreateFeature")
      vim.notify("No feature found. Use :CreateFeatureFromJira or :CreateFeature", vim.log.levels.ERROR, { title = "Spec-Driven Development" })
    end
  end, { desc = 'Open feature tasks' })

  nnoremap('<leader>wod', function()
    local feature = spec_driven.get_current_feature()
    if feature then
      vim.cmd('edit features/' .. feature .. '/design.md')
      -- Check if feature was found via branch detection and show feedback
      local current_file = vim.fn.expand("%:p")
      local in_feature_dir = current_file:match("/features/([^/]+)/")
      if not in_feature_dir then
        print("🎯 Opened design for feature '" .. feature .. "' (detected from git branch)")
      end
    else
      print("❌ No feature found. Use :CreateFeatureFromJira or :CreateFeature")
      vim.notify("No feature found. Use :CreateFeatureFromJira or :CreateFeature", vim.log.levels.ERROR, { title = "Spec-Driven Development" })
    end
  end, { desc = 'Open feature design' })

  vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*',
    callback = function()
      local buffer = vim.api.nvim_get_current_buf()
      local name = vim.api.nvim_buf_get_name(buffer)

      if name:match('claude') then
        -- Switch to normal mode when pressing Escape in terminal mode
        tnoremap('<Esc>', '<C-\\><C-n>', { buffer = buffer })
        -- Send Escape when pressing Ctrl-X in terminal mode
        tnoremap('<C-x>', '<Esc>', { buffer = buffer })
        -- Map Ctrl+h/j/k/l to navigate between tmux panes
        tnoremap('<C-h>', '<cmd>lua require("tmux").move_left()<cr>', { buffer = buffer })
        tnoremap('<C-j>', '<cmd>lua require("tmux").move_bottom()<cr>', { buffer = buffer })
        tnoremap('<C-k>', '<cmd>lua require("tmux").move_top()<cr>', { buffer = buffer })
        tnoremap('<C-l>', '<cmd>lua require("tmux").move_right()<cr>', { buffer = buffer })
      end
    end
  })
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

-- Return empty table since this is now a configuration file, not a plugin spec
return {}
