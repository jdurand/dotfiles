-- Spec-driven development workflow for Neovim
-- Inspired by Kiro's approach to feature development

local M = {}

-- Configuration
local config = {
  -- Directory structure
  spec_dir = "specs",
  features_dir = "features",

  -- File patterns
  spec_file = "spec.md",
  tasks_file = "tasks.md",
  design_file = "design.md",

  -- Commands
  linters = {
    ruby = "rubocop",
    javascript = "eslint",
    typescript = "eslint",
  },

  test_runners = {
    ruby = "bin/test",
    javascript = "npm test",
    typescript = "npm test",
  },

  -- Claude integration
  claude_model = "claude-3-5-sonnet-20241022",
  max_tokens = 4000,
}

-- Utility functions
local function get_current_feature()
  local current_file = vim.fn.expand("%:p")
  local feature_match = current_file:match("/" .. config.features_dir .. "/([^/]+)/")
  return feature_match
end

local function get_feature_path(feature_name)
  return config.features_dir .. "/" .. feature_name
end

local function get_spec_path(feature_name)
  return get_feature_path(feature_name) .. "/" .. config.spec_file
end

local function get_tasks_path(feature_name)
  return get_feature_path(feature_name) .. "/" .. config.tasks_file
end

local function get_design_path(feature_name)
  return get_feature_path(feature_name) .. "/" .. config.design_file
end

-- File operations
local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()
  return content
end

local function write_file(path, content)
  local file = io.open(path, "w")
  if not file then
    return false
  end
  file:write(content)
  file:close()
  return true
end

local function ensure_dir(path)
  vim.fn.mkdir(path, "p")
end

-- Claude integration
local function call_claude(prompt, system_prompt)
  local curl_cmd = string.format([[
    curl -s -X POST https://api.anthropic.com/v1/messages \
      -H "Content-Type: application/json" \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -d '{
        "model": "%s",
        "max_tokens": %d,
        "system": "%s",
        "messages": [{
          "role": "user",
          "content": "%s"
        }]
      }'
  ]], config.claude_model, config.max_tokens,
    system_prompt:gsub('"', '\\"'):gsub('\n', '\\n'),
    prompt:gsub('"', '\\"'):gsub('\n', '\\n'))

  local handle = io.popen(curl_cmd)
  local result = handle:read("*all")
  handle:close()

  -- Parse JSON response (simple extraction)
  local content = result:match('"content":%s*%[%s*{.-"text":%s*"(.-)"')
  if content then
    return content:gsub('\\"', '"'):gsub('\\n', '\n')
  end

  return nil
end

-- Core functions
function M.create_feature(feature_name)
  if not feature_name or feature_name == "" then
    vim.ui.input({ prompt = "Feature name: " }, function(input)
      if input then
        M.create_feature(input)
      end
    end)
    return
  end

  local feature_path = get_feature_path(feature_name)
  ensure_dir(feature_path)

  -- Create spec.md
  local spec_content = string.format([[# %s

## Overview
Brief description of what this feature does.

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2
- [ ] Criteria 3

## Technical Notes
Any specific technical requirements or constraints.

## Dependencies
List any dependencies or prerequisites.
]], feature_name)

  write_file(get_spec_path(feature_name), spec_content)

  -- Create empty tasks.md
  write_file(get_tasks_path(feature_name), "# Tasks\n\n*Generate tasks from spec using <leader>st*\n")

  -- Create empty design.md
  write_file(get_design_path(feature_name), "# Design\n\n*Optional architectural notes*\n")

  -- Open spec file
  vim.cmd("edit " .. get_spec_path(feature_name))

  print("Created feature: " .. feature_name)
end

function M.spec_to_tasks()
  local feature_name = get_current_feature()
  if not feature_name then
    print("Not in a feature directory")
    return
  end

  local spec_content = read_file(get_spec_path(feature_name))
  if not spec_content then
    print("No spec.md found")
    return
  end

  local system_prompt =
  [[You are a senior software engineer helping break down feature specifications into actionable tasks.

Given a feature spec, create a detailed tasks.md file with:
1. Clear, actionable tasks in order of implementation
2. Each task should be specific and measurable
3. Include setup, implementation, and testing tasks
4. Use markdown checkboxes for tracking progress
5. Add estimated complexity/time where helpful

Format as a clean markdown file with proper headers and task lists.]]

  local prompt = string.format([[Break down this feature spec into actionable tasks:

%s

Create a comprehensive tasks.md file with implementation steps.]], spec_content)

  print("Generating tasks from spec...")

  local tasks_content = call_claude(prompt, system_prompt)
  if tasks_content then
    write_file(get_tasks_path(feature_name), tasks_content)
    vim.cmd("edit " .. get_tasks_path(feature_name))
    print("Tasks generated successfully!")
  else
    print("Failed to generate tasks")
  end
end

function M.task_to_code()
  local feature_name = get_current_feature()
  if not feature_name then
    print("Not in a feature directory")
    return
  end

  -- Get current line (task)
  local current_line = vim.fn.getline(".")
  if not current_line:match("^%s*-.*") and not current_line:match("^%s*%d+%.") then
    print("Cursor not on a task line")
    return
  end

  -- Get file context
  local tasks_content = read_file(get_tasks_path(feature_name))
  local spec_content = read_file(get_spec_path(feature_name))

  -- Detect file type from context or ask user
  local file_ext = vim.fn.input("File extension (rb/js/ts/py): ")
  if file_ext == "" then
    return
  end

  local target_file = get_feature_path(feature_name) .. "/" .. feature_name .. "." .. file_ext

  -- Read existing file content if it exists
  local existing_content = read_file(target_file) or ""

  local system_prompt =
  [[You are a senior software engineer implementing features based on specifications and task breakdowns.

Given:
1. A feature specification
2. A task breakdown
3. A specific task to implement
4. Existing code (if any)

Generate clean, production-ready code that:
- Follows language best practices
- Includes proper error handling
- Has clear, concise comments
- Follows the existing code style
- Is testable and maintainable

Only provide the code, no explanations unless asked.]]

  local prompt = string.format([[Implement this task:

TASK: %s

FEATURE SPEC:
%s

TASK BREAKDOWN:
%s

EXISTING CODE:
%s

Generate the complete code for the target file.]],
    current_line, spec_content, tasks_content, existing_content)

  print("Generating code for task...")

  local code_content = call_claude(prompt, system_prompt)
  if code_content then
    write_file(target_file, code_content)
    vim.cmd("edit " .. target_file)
    print("Code generated successfully!")
  else
    print("Failed to generate code")
  end
end

function M.open_feature_files()
  local feature_name = get_current_feature()
  if not feature_name then
    print("Not in a feature directory")
    return
  end

  -- Open all feature files in tabs
  vim.cmd("tabedit " .. get_spec_path(feature_name))
  vim.cmd("tabedit " .. get_tasks_path(feature_name))
  vim.cmd("tabedit " .. get_design_path(feature_name))

  -- Find and open source files
  local feature_path = get_feature_path(feature_name)
  local source_files = vim.fn.glob(feature_path .. "/*", false, true)

  for _, file in ipairs(source_files) do
    if not file:match("%.md$") then
      vim.cmd("tabedit " .. file)
    end
  end
end

-- Automation hooks
function M.setup_automation()
  local group = vim.api.nvim_create_augroup("SpecDrivenDev", { clear = true })

  -- Auto-lint and test on save
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = { "*.rb", "*.js", "*.ts", "*.py" },
    callback = function()
      local filetype = vim.bo.filetype
      local file_path = vim.fn.expand("%:p")

      -- Only run in feature directories
      if not file_path:match("/" .. config.features_dir .. "/") then
        return
      end

      -- Run linter
      local linter = config.linters[filetype]
      if linter then
        vim.fn.system(linter .. " " .. vim.fn.shellescape(file_path))
      end

      -- Run tests (in background)
      local test_runner = config.test_runners[filetype]
      if test_runner then
        vim.fn.jobstart(test_runner, {
          on_exit = function(_, code)
            if code == 0 then
              print("✓ Tests passed")
            else
              print("✗ Tests failed")
            end
          end
        })
      end
    end
  })

  -- Auto-format tasks when saving tasks.md
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = "tasks.md",
    callback = function()
      -- Add any task formatting logic here
    end
  })
end

-- Expose helper functions for external use
function M.get_current_feature()
  return get_current_feature()
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)

  -- Set up automation
  M.setup_automation()

  -- Create commands
  vim.api.nvim_create_user_command("CreateFeature", function(args)
    M.create_feature(args.args)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("SpecToTasks", M.spec_to_tasks, {})
  vim.api.nvim_create_user_command("TaskToCode", M.task_to_code, {})
  vim.api.nvim_create_user_command("OpenFeature", M.open_feature_files, {})
end

return M
