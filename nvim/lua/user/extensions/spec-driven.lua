-- Spec-driven development workflow for Neovim
-- Inspired by Kiro's approach to feature development

local M = {}

-- Configuration
local config = {
  -- Directory structure
  features_dir = "features",

  -- File patterns
  spec_file = "spec.md",
  tasks_file = "tasks.md",
  design_file = "design.md",
  ticket_file = "ticket.md",

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

  -- Claude CLI integration
  claude_model = "sonnet",
}

-- Utility functions

-- Helper function to print error and show notification
local function print_error(message)
  print("❌ " .. message)
  vim.notify(message, vim.log.levels.ERROR, { title = "Spec-Driven Development" })
end
-- Find feature directory based on Jira ticket from branch name
local function find_feature_by_ticket(ticket_number)
  if not ticket_number then return nil end

  -- Look for feature directories that start with the ticket number
  local features_path = config.features_dir
  if vim.fn.isdirectory(features_path) == 0 then
    return nil
  end

  local directories = vim.fn.glob(features_path .. "/*", false, true)
  for _, dir in ipairs(directories) do
    local feature_name = vim.fn.fnamemodify(dir, ":t")
    -- Check if feature directory starts with the ticket number (case insensitive)
    -- Escape special regex characters in ticket number
    local escaped_ticket = ticket_number:lower():gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
    if feature_name:lower():match("^" .. escaped_ticket) then
      return feature_name
    end
  end

  return nil
end

-- Extract Jira ticket number from git branch name
local function get_jira_ticket_from_branch()
  local branch_name = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+", "")

  if branch_name == "" or branch_name == "HEAD" then
    return nil
  end

  -- Match pattern: [A-Za-z]{2,5}[-_][0-9]{1,5}
  local jira_ticket = branch_name:match("([A-Za-z][A-Za-z][A-Za-z]?[A-Za-z]?[A-Za-z]?[_-]%d%d?%d?%d?%d?)")

  if jira_ticket then
    -- Convert to uppercase and normalize separator to dash
    jira_ticket = jira_ticket:upper():gsub("_", "-")
    return jira_ticket
  end

  return nil
end

local function get_current_feature()
  -- First try to get from current file path
  local current_file = vim.fn.expand("%:p")
  local feature_match = current_file:match("/" .. config.features_dir .. "/([^/]+)/")

  if feature_match then
    return feature_match
  end

  -- If not in a feature directory, try to find feature based on git branch
  local ticket_number = get_jira_ticket_from_branch()
  if ticket_number then
    return find_feature_by_ticket(ticket_number)
  end

  return nil
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

local function get_ticket_path(feature_name)
  return get_feature_path(feature_name) .. "/" .. config.ticket_file
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

-- Claude integration with Overseer
local function call_claude_async(prompt, system_prompt, title, callback)
  title = title or "Claude AI Task"

  -- Create temporary files for prompts to avoid shell escaping issues
  local temp_dir = vim.fn.tempname() .. "_claude"
  vim.fn.mkdir(temp_dir, "p")

  local system_file = temp_dir .. "/system_prompt.txt"
  local user_file = temp_dir .. "/user_prompt.txt"
  local output_file = temp_dir .. "/claude_output.txt"

  -- Write prompts to temporary files
  if not write_file(system_file, system_prompt) then
    print("❌ Failed to create system prompt file")
    if callback then callback(nil, "Failed to create system prompt file") end
    return
  end

  if not write_file(user_file, prompt) then
    print("❌ Failed to create user prompt file")
    if callback then callback(nil, "Failed to create user prompt file") end
    return
  end

  -- Build Claude CLI command that captures output properly
  local claude_cmd = string.format(
    "claude --model %s --system-prompt %s %s",
    config.claude_model,
    vim.fn.shellescape(system_file),
    vim.fn.shellescape(user_file)
  )

  -- Show loading state
  print("🤖 " .. title .. " - Processing with Claude...")

  -- Use Overseer to run the command asynchronously
  local overseer_available, overseer = pcall(require, "overseer")

  if overseer_available then
    local task = overseer.new_task({
      name = title,
      cmd = { "sh", "-c", claude_cmd },
      cwd = vim.fn.getcwd(),
      components = {
        { "on_output_quickfix", open = false },
        "on_result_diagnostics",
        "on_exit_set_status",
        {
          "on_complete_notify",
          statuses = { "SUCCESS", "FAILURE" },
        },
      },
    })

    task:add_component({
      "on_complete_callback",
      callback = function(task_obj, status)
        -- Read the output file
        local output = read_file(output_file)
        if output then
          output = clean_claude_response(output)
        end

        -- Clean up temporary files
        vim.fn.delete(temp_dir, "rf")

        if status == "SUCCESS" and output then
          print("✅ " .. title .. " completed successfully")
          if callback then callback(output, nil) end
        else
          print("❌ " .. title .. " failed")
          if callback then callback(nil, "Claude command failed") end
        end
      end,
    })

    task:start()
    print("📊 Task started in Overseer: " .. title)
  else
    -- Fallback: run synchronously if Overseer is not available
    print("⚠️ Overseer not available, running synchronously...")
    local result = vim.fn.system(claude_cmd)

    if vim.v.shell_error == 0 then
      local output = read_file(output_file)
      if output then
        output = clean_claude_response(output)
        if callback then callback(output, nil) end
      else
        if callback then callback(nil, "Failed to read output") end
      end
    else
      if callback then callback(nil, "Claude command failed: " .. result) end
    end

    -- Clean up temporary files
    vim.fn.delete(temp_dir, "rf")
  end
end

-- Helper function to clean Claude response from command line noise
local function clean_claude_response(response)
  if not response then return nil end

  -- Split into lines for processing (preserving empty lines)
  local lines = {}
  for line in (response .. "\n"):gmatch("([^\r\n]*)\r?\n") do
    table.insert(lines, line)
  end

  local cleaned_lines = {}
  for _, line in ipairs(lines) do
    -- Skip common command line noise patterns
    if not (
          line:match("^direnv:") or                      -- direnv output
          line:match("^%[Process exited") or             -- Process exit messages
          line:match("^Loading") or                      -- Loading messages
          line:match("^Loaded") or                       -- Loaded messages
          line:match("I've created a comprehensive") or  -- Claude commentary
          line:match("^I've ") or                        -- Claude "I've done X" statements
          line:match("^The .* file has been created") or -- Claude file creation commentary
          line:match("^The .* has been created") or      -- Claude creation commentary
          false                                          -- Don't filter empty lines to preserve markdown formatting
        ) then
      table.insert(cleaned_lines, line)
    end
  end

  return table.concat(cleaned_lines, "\n"):gsub("^%s*", ""):gsub("%s*$", "")
end

-- Simple synchronous Claude function for now (we can make it async later)
local function call_claude_sync(prompt, system_prompt, title)
  title = title or "Claude AI Task"

  -- Create temporary files for prompts to avoid shell escaping issues
  local temp_dir = vim.fn.tempname() .. "_claude"
  vim.fn.mkdir(temp_dir, "p")

  local system_file = temp_dir .. "/system_prompt.txt"
  local user_file = temp_dir .. "/user_prompt.txt"

  -- Write prompts to temporary files
  if not write_file(system_file, system_prompt) then
    print("❌ Failed to create system prompt file")
    vim.fn.delete(temp_dir, "rf")
    return nil, "Failed to create system prompt file"
  end

  if not write_file(user_file, prompt) then
    print("❌ Failed to create user prompt file")
    vim.fn.delete(temp_dir, "rf")
    return nil, "Failed to create user prompt file"
  end

  -- Combine system and user prompts
  local combined_prompt_file = temp_dir .. "/combined_prompt.txt"
  local combined_content = system_prompt .. "\n\n" .. prompt

  if not write_file(combined_prompt_file, combined_content) then
    print("❌ Failed to create combined prompt file")
    vim.fn.delete(temp_dir, "rf")
    return nil, "Failed to create combined prompt file"
  end

  -- Build Claude CLI command with proper flags (using cat to pipe content)
  local claude_cmd = string.format(
    "cat %s | claude --print --model %s",
    vim.fn.shellescape(combined_prompt_file),
    config.claude_model
  )

  print("🤖 " .. title .. " - Processing with Claude...")

  -- Execute synchronously and capture output
  print("🔧 Debug: Running command: " .. claude_cmd)
  local output = vim.fn.system(claude_cmd .. " 2>&1") -- Capture stderr too
  local exit_code = vim.v.shell_error

  print("🔧 Debug: Exit code: " .. exit_code)
  print("🔧 Debug: Output length: " .. string.len(output or ""))
  if output and output ~= "" then
    print("🔧 Debug: Output preview: " .. string.sub(output, 1, 200) .. "...")
  end

  -- Clean up temporary files
  vim.fn.delete(temp_dir, "rf")

  if exit_code == 0 and output and output ~= "" then
    output = clean_claude_response(output)
    print("✅ " .. title .. " completed successfully")
    return output, nil
  else
    local error_msg = title .. " failed (exit code: " .. exit_code .. ")"
    if output and output ~= "" then
      error_msg = error_msg .. ". Error details: " .. output
    end
    print_error(error_msg)
    return nil, "Claude command failed with exit code " .. exit_code .. ". Error: " .. (output or "No output")
  end
end

-- Claude API direct integration
local function call_claude_api(prompt, system_prompt)
  -- Check for Anthropic API key (direct API calls only support API keys, not OAuth)
  local api_key = vim.fn.getenv("ANTHROPIC_API_KEY")

  if not api_key or api_key == "" then
    return nil,
        "ANTHROPIC_API_KEY environment variable not set. Get your API key from https://console.anthropic.com/ and set it in your environment."
  end

  -- Create the API request payload
  local payload = {
    model = "claude-3-5-sonnet-20241022",
    max_tokens = 4000,
    system = system_prompt,
    messages = {
      {
        role = "user",
        content = prompt
      }
    }
  }

  -- Convert payload to JSON
  local json_payload = vim.fn.json_encode(payload)

  -- Create temporary file for the payload
  local temp_file = vim.fn.tempname() .. ".json"
  local file = io.open(temp_file, "w")
  if not file then
    return nil, "Failed to create temporary file for API request"
  end
  file:write(json_payload)
  file:close()

  -- Make the API call using curl with API key authentication
  local curl_cmd = string.format([[curl -s \
    -H "Content-Type: application/json" \
    -H "x-api-key: %s" \
    -H "anthropic-version: 2023-06-01" \
    -d @%s \
    https://api.anthropic.com/v1/messages]], api_key, temp_file)

  print("🔄 Calling Claude API...")
  local response = vim.fn.system(curl_cmd)
  local exit_code = vim.v.shell_error

  -- Clean up temp file
  os.remove(temp_file)

  if exit_code ~= 0 then
    return nil, "API request failed with exit code " .. exit_code
  end

  -- Parse the JSON response
  local success, response_data = pcall(vim.fn.json_decode, response)
  if not success then
    return nil, "Failed to parse API response: " .. tostring(response_data)
  end

  -- Check for API errors
  if response_data.error then
    return nil, "Claude API error: " .. (response_data.error.message or "Unknown error")
  end

  -- Extract the content from the response
  if response_data.content and response_data.content[1] and response_data.content[1].text then
    return response_data.content[1].text, nil
  else
    return nil, "Unexpected API response format"
  end
end

-- Helper function to generate proper product specification from Jira ticket data
local function generate_spec_from_jira(feature_name, jira_description, callback)
  local system_prompt =
  [[You are a technical specification generator. You MUST output ONLY markdown. DO NOT respond conversationally. DO NOT ask questions. DO NOT provide explanations. START IMMEDIATELY with markdown that begins with "#". Keep all lines under 80 characters.]]

  local prompt = string.format(
    [[JIRA TICKET DATA:
%s

TASK: Create a comprehensive engineering specification from this Jira ticket data above.

RULES:
- Output ONLY markdown specification
- Do NOT respond conversationally
- Do NOT ask questions
- Do NOT provide explanations
- Start IMMEDIATELY with markdown beginning with "#"

REQUIRED STRUCTURE - Be extremely detailed in each section:
# [Ticket Key] - [Summary]

## Problem Statement
[Describe the exact problem in detail - include all context from the ticket description, environment details, user impact, business impact]

## Current Behavior
[Document precisely how the system currently behaves - include specific examples, error conditions, data flow, affected components]

## Root Cause Analysis
[Based on ticket details, identify potential causes, affected systems, data inconsistencies, timing issues, etc.]

## Expected Behavior
[Define exactly how the system should behave - include specific scenarios, edge cases, data validation, error handling]

## Technical Requirements
[List all technical constraints, dependencies, performance requirements, data integrity requirements, integration points]

## Acceptance Criteria
[Create specific, testable criteria for each aspect mentioned in the ticket - include positive and negative test cases]

## Investigation Steps
[Define systematic approach to investigate and validate the issue - include data analysis, log review, testing procedures]

## Implementation Approach
[Outline technical approach including affected components, data migration needs, rollback plan, monitoring requirements]

## Risk Assessment
[Identify potential risks, impact on existing functionality, downstream effects, mitigation strategies]

## Success Metrics
[Define measurable outcomes, monitoring alerts, validation queries, user experience improvements]

## Testing Strategy
[Comprehensive testing approach including unit tests, integration tests, data validation, performance testing]

CRITICAL: Extract every detail from the ticket. Do not invent information. Be thorough with what's provided. Start with "# " and output ONLY markdown. Keep all lines under 80 characters.]],
    jira_description)

  print("🤖 Generating specific specification with Claude...")
  local spec_result, spec_error = call_claude_sync(prompt, system_prompt, "Generate Spec from Jira")

  if spec_result and not spec_error then
    -- Clean up conversational responses and extract only markdown
    local cleaned_spec = clean_claude_response(spec_result)

    -- Validate that we got a proper spec (should start with #)
    if cleaned_spec:match("^%s*#") then
      if callback then callback(cleaned_spec) end
    else
      -- If no proper markdown found, use fallback
      local ticket_key = jira_description:match("%*%*Jira Ticket:%*%* ([A-Z]+%-[0-9]+)") or feature_name:upper()
      local summary = jira_description:match("%*%*Summary:%*%* ([^\n]+)") or "Feature Implementation"

      local fallback_spec = string.format([[# %s - %s

## 🤖 Generation Failed - Conversational Response

Claude responded conversationally instead of generating a specification.

Original Claude response:
%s

Please manually create the specification or adjust the Claude prompt.

See ticket.md for the raw Jira ticket information.]], ticket_key, summary, spec_result)
      if callback then callback(fallback_spec) end
    end
  else
    -- Fallback to basic template if Claude failed
    local ticket_key = jira_description:match("%*%*Jira Ticket:%*%* ([A-Z]+%-[0-9]+)") or feature_name:upper()
    local summary = jira_description:match("%*%*Summary:%*%* ([^\n]+)") or "Feature Implementation"

    local fallback_spec = string.format([[# %s - %s

## 🤖 Generation Failed

%s

Please manually create the specification or check your Claude CLI configuration.

See ticket.md for the raw Jira ticket information.]], ticket_key, summary, spec_error or "Claude generation failed")
    if callback then callback(fallback_spec) end
  end
end


-- Claude integration using Claude Code CLI with interactive terminal
local function call_claude(prompt, system_prompt, task_name)
  task_name = task_name or "Claude AI Request"

  -- Create temporary file for the prompt in .claude/spec-driven-prompts with unique timestamp
  local temp_dir = vim.fn.getcwd() .. "/.claude/spec-driven-prompts"
  vim.fn.mkdir(temp_dir, "p")
  local temp_file = temp_dir .. "/prompt_" .. vim.fn.localtime() .. "_" .. math.random(1000, 9999) .. ".md"

  -- Write combined system prompt and user prompt to temporary file
  local file = io.open(temp_file, "w")
  if not file then
    print("❌ Failed to create temporary file for Claude request")
    print("📁 Attempted path: " .. temp_file)
    return nil
  end

  -- Write system prompt as a clear instruction block
  file:write("# SYSTEM INSTRUCTIONS\n\n")
  file:write(system_prompt)
  file:write("\n\n# USER REQUEST\n\n")
  file:write(prompt)
  file:close()

  -- Build the Claude CLI command
  local claude_cmd = string.format(
    'claude --model %s %s',
    config.claude_model,
    vim.fn.shellescape(temp_file)
  )

  print("🤖 Opening Claude CLI for: " .. task_name)
  print("📁 Prompt file: " .. temp_file)
  print("⚡ Command: " .. claude_cmd)

  -- Test if claude command exists first
  local claude_test = vim.fn.system("which claude 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    print("❌ Claude CLI not found. Please install: https://docs.anthropic.com/en/docs/claude-code")
    return nil
  end

  -- Open Claude CLI in terminal for interactive use
  local success, err = pcall(vim.cmd, "terminal " .. claude_cmd)
  if not success then
    print("❌ Failed to open terminal: " .. tostring(err))
    print("💡 Try running manually: " .. claude_cmd)
    return nil
  end

  print("✅ Claude session launched in terminal")
  return nil
end

-- Helper function to extract ticket number from URL or return as-is
local function extract_ticket_number(input)
  if not input or input == "" then
    return nil
  end

  -- Clean up whitespace
  input = input:gsub("^%s*(.-)%s*$", "%1")

  -- Check if it's a URL and extract ticket number
  local ticket_from_url = input:match("/browse/([A-Z]+%-%d+)")
  if ticket_from_url then
    return ticket_from_url:upper()
  end

  -- Check if it's just a ticket number (with or without project prefix)
  local ticket_direct = input:match("([A-Z]+%-?%d+)")
  if ticket_direct then
    -- Ensure it has the dash format
    ticket_direct = ticket_direct:upper():gsub("([A-Z]+)(%d+)", "%1-%2")
    return ticket_direct
  end

  return nil
end

-- Jira API integration functions
local function fetch_jira_ticket(ticket_number)
  print("🎫 DEBUG: Fetching issue number: " .. tostring(ticket_number))

  -- Load Jira credentials from environment variables for security
  local jira_base_url = vim.fn.getenv("JIRA_BASE_URL")
  local jira_email = vim.fn.getenv("JIRA_EMAIL")
  local jira_api_token = vim.fn.getenv("JIRA_API_TOKEN")

  -- Convert userdata to strings or nil (handle vim.NIL properly)
  jira_base_url = (jira_base_url ~= vim.NIL and jira_base_url ~= nil) and tostring(jira_base_url) or nil
  jira_email = (jira_email ~= vim.NIL and jira_email ~= nil) and tostring(jira_email) or nil
  jira_api_token = (jira_api_token ~= vim.NIL and jira_api_token ~= nil) and tostring(jira_api_token) or nil

  print("🔍 DEBUG: Environment check:")
  print("   JIRA_BASE_URL: " .. (jira_base_url or "NOT SET"))
  print("   JIRA_EMAIL: " .. (jira_email or "NOT SET"))
  print("   JIRA_API_TOKEN: " .. (jira_api_token and (string.sub(jira_api_token, 1, 10) .. "...") or "NOT SET"))

  if not jira_base_url or jira_base_url == "" then
    print_error("JIRA_BASE_URL environment variable not set.")
    print("💡 Set it with: export JIRA_BASE_URL=\"https://your-company.atlassian.net\"")
    return nil
  end

  if not jira_email or jira_email == "" then
    print_error("JIRA_EMAIL environment variable not set.")
    print("💡 Set it with: export JIRA_EMAIL=\"your-email@company.com\"")
    return nil
  end

  if not jira_api_token or jira_api_token == "" then
    print_error("JIRA_API_TOKEN environment variable not set.")
    print("💡 Set it with: export JIRA_API_TOKEN=\"your-api-token\"")
    print("💡 Create token at: https://id.atlassian.com/manage-profile/security/api-tokens")
    return nil
  end

  -- Clean up the base URL - remove /jira suffix if present since API doesn't use it
  local clean_base_url = jira_base_url:gsub("/jira$", "")
  local url = string.format("%s/rest/api/3/issue/%s", clean_base_url, ticket_number)

  print("🔄 Fetching from URL: " .. url)

  -- Create base64 auth more reliably to avoid direnv pollution
  local auth_string = jira_email .. ":" .. jira_api_token
  local auth = vim.fn.system(string.format("printf '%%s' '%s' | base64", auth_string)):gsub("%s+", "")

  print("🔍 DEBUG: Auth details:")
  print("   Auth string length: " .. string.len(auth_string))
  print("   Base64 auth length: " .. string.len(auth))
  print("   Base64 auth (first 20 chars): " .. string.sub(auth, 1, 20) .. "...")

  local curl_cmd = string.format(
    'curl -s -w "HTTP_CODE:%%{http_code}" -H "Authorization: Basic %s" -H "Accept: application/json" "%s" 2>/dev/null',
    auth, url
  )

  print("🔄 Fetching Jira ticket: " .. ticket_number)
  print("🔍 DEBUG: Full curl command: " .. curl_cmd)
  local response = vim.fn.system(curl_cmd)

  -- Extract HTTP status code
  local http_code = response:match("HTTP_CODE:(%d+)$")
  local json_response = response:gsub("HTTP_CODE:%d+$", "")

  print("🔍 HTTP Status: " .. (http_code or "unknown"))

  if vim.v.shell_error ~= 0 then
    print_error("Curl command failed. Exit code: " .. vim.v.shell_error)
    print("🔍 Response: " .. response)
    return nil
  end

  if http_code and http_code ~= "200" then
    print_error("HTTP Error " .. http_code)
    if http_code == "401" then
      print("🔑 Authentication failed. Check your email and API token")
    elseif http_code == "403" then
      print("🚫 Access forbidden. Check your permissions")
    elseif http_code == "404" then
      print("🔍 Ticket not found: " .. ticket_number)
    end
    print("🔍 Response: " .. json_response)
    return nil
  end

  -- Parse JSON response using vim.fn.json_decode for better reliability
  local success, ticket_data = pcall(vim.fn.json_decode, json_response)
  if not success then
    print_error("Failed to parse Jira response as JSON")
    print("🔍 Raw response (first 500 chars): " .. json_response:sub(1, 500))
    return nil
  end

  if ticket_data.errorMessages then
    print_error("Jira API error: " .. table.concat(ticket_data.errorMessages, ", "))
    return nil
  end

  -- Extract comprehensive ticket information
  local fields = ticket_data.fields or {}
  local issue_type = fields.issuetype and fields.issuetype.name or "Unknown"
  local summary = fields.summary or "No summary"
  local description = fields.description or ""

  print("🔍 DEBUG: Raw extracted data:")
  print("   ticket_data.key: " .. tostring(ticket_data.key))
  print("   fields.summary: " .. tostring(summary))
  print("   ticket_number param: " .. tostring(ticket_number))

  -- Handle description content (might be in Atlassian Document Format or null)
  if type(description) == "table" and description.content then
    local desc_text = ""
    for _, content in ipairs(description.content) do
      if content.type == "paragraph" and content.content then
        for _, text_item in ipairs(content.content) do
          if text_item.text then
            desc_text = desc_text .. text_item.text
          end
        end
        desc_text = desc_text .. "\n"
      end
    end
    description = desc_text:gsub("\n$", "")
  elseif description == vim.NIL or type(description) ~= "string" then
    description = ""
  end

  -- Extract additional fields (handle vim.NIL properly)
  local priority = (fields.priority ~= vim.NIL and fields.priority and fields.priority.name) or "Medium"
  local status = (fields.status ~= vim.NIL and fields.status and fields.status.name) or "Unknown"
  local assignee = (fields.assignee ~= vim.NIL and fields.assignee and fields.assignee.displayName) or "Unassigned"
  local reporter = (fields.reporter ~= vim.NIL and fields.reporter and fields.reporter.displayName) or "Unknown"
  local created = (fields.created ~= vim.NIL and fields.created) or ""
  local updated = (fields.updated ~= vim.NIL and fields.updated) or ""

  -- Extract components
  local components = {}
  if fields.components ~= vim.NIL and fields.components then
    for _, component in ipairs(fields.components) do
      if component and component.name then
        table.insert(components, component.name)
      end
    end
  end

  -- Extract labels
  local labels = {}
  if fields.labels ~= vim.NIL and fields.labels then
    for _, label in ipairs(fields.labels) do
      if label and type(label) == "string" then
        table.insert(labels, label)
      end
    end
  end

  print("🔍 Parsed successfully:")
  print("   Key: " .. ticket_number)
  print("   Summary: " .. summary)
  print("   Type: " .. issue_type)
  print("   Description length: " .. string.len(description))
  print("   Assignee: " .. assignee)

  return {
    key = ticket_number,
    summary = summary,
    description = description,
    issue_type = issue_type,
    priority = priority,
    status = status,
    assignee = assignee,
    reporter = reporter,
    created = created,
    updated = updated,
    components = components,
    labels = labels,
    parent_info = "",
    subtasks_info = "",
    raw_data = ticket_data -- Keep full data for debugging
  }
end

-- Create descriptive feature name from ticket data (ticket-prefix + 3-5 words from summary)
local function create_feature_name_from_ticket(ticket_data)
  if not ticket_data or not ticket_data.key or not ticket_data.summary then
    return nil
  end

  -- Start with ticket key in lowercase
  local feature_name = ticket_data.key:lower()

  -- Extract meaningful words from summary (3-5 words)
  local summary_words = {}
  local summary = ticket_data.summary:lower()

  -- Remove common words and get meaningful terms
  local stop_words = {
    "a", "an", "and", "are", "as", "at", "be", "by", "for", "from", "has", "he", "in", "is", "it", "its", "of", "on",
    "that", "the", "to", "was", "will", "with", "the", "not", "are", "be", "been", "have", "has", "had", "do", "does",
    "did", "should", "could", "would"
  }

  for word in summary:gmatch("%w+") do
    if #word > 2 and not stop_words[word] then
      table.insert(summary_words, word)
      if #summary_words >= 4 then -- Limit to 4 words from summary
        break
      end
    end
  end

  -- Join with hyphens
  if #summary_words > 0 then
    feature_name = feature_name .. "-" .. table.concat(summary_words, "-")
  end

  -- Ensure total length is reasonable (max 50 chars)
  if #feature_name > 50 then
    feature_name = feature_name:sub(1, 50):gsub("%-[^-]*$", "") -- Cut at word boundary
  end

  return feature_name
end

local function create_branch_name(ticket_data)
  if not ticket_data or not ticket_data.key or not ticket_data.summary then
    return nil
  end

  -- Determine branch prefix based on issue type
  local branch_prefix = "feat"

  if ticket_data.issue_type then
    local issue_type = ticket_data.issue_type:lower()
    if issue_type:match("bug") or issue_type:match("defect") then
      branch_prefix = "fix"
    elseif issue_type:match("chore") or issue_type:match("task") then
      branch_prefix = "task"
    elseif issue_type:match("story") or issue_type:match("feature") then
      branch_prefix = "story"
    elseif issue_type:match("epic") then
      branch_prefix = "epic"
    end
  end

  -- Create descriptive part from summary
  local descriptive = ticket_data.summary
      :lower()
      :gsub("[^%w%s%-]", "") -- Remove special characters except hyphens and spaces
      :gsub("%s+", "-")      -- Replace spaces with hyphens
      :gsub("%-+", "-")      -- Replace multiple hyphens with single
      :gsub("^%-", "")       -- Remove leading hyphen
      :gsub("%-$", "")       -- Remove trailing hyphen

  -- Limit length
  if #descriptive > 50 then
    descriptive = descriptive:sub(1, 50):gsub("%-[^-]*$", "") -- Cut at word boundary
  end

  return string.format("%s/%s-%s", branch_prefix, ticket_data.key:lower(), descriptive)
end

function M.start_work()
  local ok, err = pcall(function()
    local ticket_number = vim.fn.input("Jira ticket number (e.g. LIB-1234): ")
    if ticket_number == "" then
      print_error("No ticket number provided")
      return
    end

    -- Normalize ticket format
    ticket_number = ticket_number:upper():gsub("_", "-")
    print("🎫 Processing ticket: " .. ticket_number)

    -- Fetch ticket from Jira API
    local ticket_data = fetch_jira_ticket(ticket_number)
    if not ticket_data then
      print_error("Failed to fetch ticket data")
      return
    end

    print("✅ Fetched ticket: " .. (ticket_data.summary or "No summary"))
    print("📋 Issue Type: " .. (ticket_data.issue_type or "Unknown"))
    print("📊 Status: " .. (ticket_data.status or "Unknown"))

    -- Create branch name
    local branch_name = create_branch_name(ticket_data)
    if not branch_name then
      print("❌ Failed to create branch name from ticket data")
      print("🔍 Debug - ticket_data.key: " .. (ticket_data.key or "nil"))
      print("🔍 Debug - ticket_data.summary: " .. (ticket_data.summary or "nil"))
      return
    end

    print("🌿 Creating branch: " .. branch_name)

    -- Create and checkout new branch
    local git_result = vim.fn.system("git checkout -b " .. vim.fn.shellescape(branch_name))
    if vim.v.shell_error ~= 0 then
      print("❌ Failed to create branch. Git error:")
      print(git_result)
      return
    end

    print("✅ Created and checked out branch: " .. branch_name)

    -- Create feature directory structure
    local feature_name = ticket_number:lower()
    local feature_path = get_feature_path(feature_name)

    print("📁 Creating feature directory: " .. feature_path)
    ensure_dir(feature_path)

    -- Generate comprehensive spec using Claude
    local system_prompt =
    [[You are a product manager and software engineer creating feature specifications from Jira tickets.

IMPORTANT:
- Create a comprehensive feature specification based on the Jira ticket information
- Return ONLY the markdown specification content, not any commentary
- Base everything on the provided ticket details

Create a detailed specification with:
1. Clear overview based on ticket summary and description
2. Detailed functional requirements derived from the ticket
3. Specific acceptance criteria (from ticket or inferred from requirements)
4. Technical considerations and implementation notes
5. Dependencies and prerequisites
6. Edge cases and error handling requirements

Format as clean markdown with proper headers.]]

    local jira_details = string.format([[
**Ticket:** %s
**Summary:** %s
**Type:** %s
**Status:** %s
**Description:** %s
**Acceptance Criteria:** %s
**Assignee:** %s]],
      ticket_data.key or "Unknown",
      ticket_data.summary or "No summary",
      ticket_data.issue_type or "Unknown",
      ticket_data.status or "Unknown",
      ticket_data.description or "No description",
      ticket_data.acceptance_criteria ~= "" and ticket_data.acceptance_criteria or "Not specified",
      ticket_data.assignee or "Unassigned"
    )

    local prompt = string.format([[Create a comprehensive feature specification from this Jira ticket:

%s

Generate a detailed specification that covers all aspects needed for implementation.

Return only the markdown specification content.]], jira_details)

    print("🤖 Generating specification with Claude...")

    -- Generate spec with Claude
    print("🔍 DEBUG: About to call Claude with ticket: " .. ticket.key)
    print("🔍 DEBUG: Comprehensive description starts with: " .. string.sub(comprehensive_description, 1, 200) .. "...")
    call_claude(prompt, system_prompt, "Generate Specification from " .. ticket_number)

    -- Create spec file with ticket info
    local spec_content = string.format([[# %s - %s

> **Jira Ticket:** [%s](%s/browse/%s)
> **Type:** %s
> **Status:** %s
> **Assignee:** %s

## Original Description
%s

## Acceptance Criteria
%s

---

*Paste the generated specification below this line*

]],
      ticket_data.key or "Unknown",
      ticket_data.summary or "No summary",
      ticket_data.key or "Unknown",
      config.jira_base_url,
      ticket_data.key or "Unknown",
      ticket_data.issue_type or "Unknown",
      ticket_data.status or "Unknown",
      ticket_data.assignee or "Unassigned",
      ticket_data.description or "No description",
      ticket_data.acceptance_criteria ~= "" and ticket_data.acceptance_criteria or "Not specified"
    )

    local spec_path = get_spec_path(feature_name)
    local tasks_path = get_tasks_path(feature_name)
    local design_path = get_design_path(feature_name)

    print("📝 Writing spec file: " .. spec_path)
    write_file(spec_path, spec_content)
    write_file(tasks_path, "# Tasks\n\n*Generate tasks from spec using :GenerateTaskList*\n")
    write_file(design_path, "# Design\n\n*Optional architectural notes*\n")

    print("📁 Created feature directory: " .. feature_path)
    print("📝 Please copy the generated spec and paste it into the spec.md file")

    -- Open spec file for editing
    vim.cmd("edit " .. spec_path)

    print("🚀 Ready to start work on " .. ticket_number .. "!")
  end)

  if not ok then
    print_error("StartWork failed with error: " .. tostring(err))
    print("🔍 Please check your Jira configuration and try again")
    print("💡 Jira URL should be like: https://company.atlassian.net (without /jira)")
  end
end

-- List all available feature directories
function M.list_features()
  local features_path = config.features_dir
  if vim.fn.isdirectory(features_path) == 0 then
    print("📁 No features directory found at: " .. features_path)
    return
  end

  local directories = vim.fn.glob(features_path .. "/*", false, true)
  if #directories == 0 then
    print("📁 No features found in: " .. features_path)
    return
  end

  -- Get current branch ticket for sorting
  local ticket_number = get_jira_ticket_from_branch()
  local matched_feature = nil
  local other_features = {}

  -- Separate matched feature from others
  for _, dir in ipairs(directories) do
    if vim.fn.isdirectory(dir) == 1 then
      local feature_name = vim.fn.fnamemodify(dir, ":t")

      -- Check if this feature matches current branch ticket
      if ticket_number then
        local escaped_ticket = ticket_number:lower():gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        if feature_name:lower():match("^" .. escaped_ticket) then
          matched_feature = feature_name
        else
          table.insert(other_features, feature_name)
        end
      else
        table.insert(other_features, feature_name)
      end
    end
  end

  print("📋 Available features:")

  -- Show matched feature first (highlighted)
  if matched_feature then
    print("  🎯 " .. matched_feature .. " (matches current branch)")
  end

  -- Show other features
  for _, feature_name in ipairs(other_features) do
    print("  📁 " .. feature_name)
  end

  -- Show current branch and ticket detection status
  if ticket_number then
    if matched_feature then
      print("\n✅ Current branch (" .. ticket_number .. ") → feature: " .. matched_feature)
    else
      print("\n❌ Current branch (" .. ticket_number .. ") → no matching feature found")
      print("💡 Create feature first with :CreateFeatureFromJira or :CreateFeature")
    end
  else
    print("\n💡 No Jira ticket detected in current branch name")
  end
end

-- Core functions
function M.create_feature(feature_name, description)
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

  -- Handle Jira vs regular descriptions differently
  if description and description ~= "" then
    -- Check if this looks like Jira ticket data (contains **Jira Ticket:** marker)
    if description:match("%*%*Jira Ticket:%*%*") then
      print("📋 Processing Jira ticket data...")

      -- Create ticket.md with raw Jira data
      write_file(get_ticket_path(feature_name), description)
      print("✅ Created ticket.md with Jira data")

      -- Create placeholder spec.md and generate real spec asynchronously
      local loading_spec = string.format([[# %s

## 🤖 Generating Product Specification...

Claude is analyzing the Jira ticket data and generating a comprehensive product specification.
This may take a few moments.

See ticket.md for the raw Jira ticket information.

*This content will be replaced automatically when generation completes.*
]], feature_name)

      write_file(get_spec_path(feature_name), loading_spec)

      -- Generate proper spec asynchronously
      generate_spec_from_jira(feature_name, description, function(spec_content)
        if spec_content then
          write_file(get_spec_path(feature_name), spec_content)
          print("✅ Generated product specification in spec.md")
          -- Refresh the buffer if it's open
          vim.schedule(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local buf_name = vim.api.nvim_buf_get_name(buf)
              if buf_name:match(feature_name .. "/spec%.md$") then
                vim.api.nvim_buf_call(buf, function()
                  vim.cmd("edit!")
                end)
                break
              end
            end
          end)
        end
      end)
    else
      print("🤖 Generating spec from description using Claude...")
      M.generate_spec_from_description(feature_name, description)
      -- Create placeholder spec
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
    end
  else
    -- No description provided, create template
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
  end

  -- Create empty tasks.md
  write_file(get_tasks_path(feature_name), "# Tasks\n\n*Generate tasks from spec using :GenerateTaskList*\n")

  -- Create empty design.md
  write_file(get_design_path(feature_name), "# Design\n\n*Optional architectural notes*\n")

  -- Open spec file
  vim.cmd("edit " .. get_spec_path(feature_name))

  print("Created feature: " .. feature_name)
end

-- Generate feature name from description using Claude
function M.generate_feature_name_from_description(description)
  local system_prompt = [[You are a senior software engineer creating feature names from descriptions.

IMPORTANT: Base your feature name ENTIRELY on the user-provided description below. While you may have access to git history or other project context, you must focus exclusively on the feature description provided by the user.

Given a description, create a concise, dasherized feature name that:
1. Is lowercase and uses dashes (kebab-case)
2. Is 2-4 words maximum
3. Captures the core functionality from the user's description
4. Is suitable for directory/file names
5. Avoids generic terms like "feature", "system", "module"

Examples:
- "User authentication with email verification" -> "user-authentication"
- "Real-time chat messaging between users" -> "chat-messaging"
- "PDF report generation with charts" -> "pdf-reports"
- "Shopping cart checkout with payment" -> "checkout-payment"

Return ONLY the feature name, no explanations.]]

  local prompt = string.format([[Generate a dasherized feature name from this description:

%s

Return only the feature name in kebab-case format. Base it entirely on the description above.]], description)

  call_claude(prompt, system_prompt, "Generate Feature Name")
  print("📝 Please copy the generated feature name and use :CreateFeature <name> <description>")
  return nil
end

-- Generate spec from description using Claude
-- Create feature from description: generate name and comprehensive spec
function M.create_feature_from_description(description)
  print("🤖 Generating feature name from description...")

  -- First generate the feature name
  local name_system_prompt = [[You generate feature names. Output ONLY a kebab-case feature name. NO explanations.]]
  local name_prompt = string.format(
    [[Generate a short, descriptive kebab-case feature name (2-4 words) from this description:

%s

Output ONLY the feature name in kebab-case format. Examples: user-authentication, payment-processing, search-filters]],
    description)

  local feature_name, name_error = call_claude_sync(name_prompt, name_system_prompt, "Generate Feature Name")

  if not feature_name or name_error then
    print_error("Failed to generate feature name: " .. (name_error or "Unknown error"))
    return
  end

  -- Clean up the generated name
  feature_name = feature_name:gsub("%s+", ""):gsub("[^a-zA-Z0-9%-]", ""):lower()
  print("✅ Generated feature name: " .. feature_name)

  -- Create feature directory
  local feature_path = get_feature_path(feature_name)
  ensure_dir(feature_path)

  -- Generate comprehensive spec
  print("🤖 Generating comprehensive specification...")
  local spec_system_prompt =
  [[You generate product specifications. Output ONLY markdown specifications starting with # title. Keep all lines under 80 characters.]]

  local spec_prompt = string.format([[Create a comprehensive product specification from this description:

%s

REQUIRED STRUCTURE:
# [Feature Name]

## Overview
[Brief overview of the feature based on description]

## Functional Requirements
- [ ] [Specific requirement 1]
- [ ] [Specific requirement 2]
- [ ] [Additional requirements based on description]

## Acceptance Criteria
- [ ] [Testable criteria 1]
- [ ] [Testable criteria 2]
- [ ] [Additional criteria based on description]

## Technical Considerations
[Implementation notes, constraints, dependencies]

## Security & Performance
[Relevant security and performance considerations]

CRITICAL: Base everything on the description. Be specific and actionable. Output ONLY markdown. Keep all lines under 80 characters.]],
    description)

  local spec_content, spec_error = call_claude_sync(spec_prompt, spec_system_prompt, "Generate Feature Spec")

  if spec_content and not spec_error then
    -- Write the generated spec
    write_file(get_spec_path(feature_name), spec_content)
    print("✅ Generated comprehensive specification in spec.md")

    -- Create empty tasks and design files
    write_file(get_tasks_path(feature_name),
      string.format("# Tasks for %s\n\n*Generate tasks using :GenerateTaskList*", feature_name))
    write_file(get_design_path(feature_name),
      string.format("# Design Notes for %s\n\n## Architecture\n\n## Technical Details\n\n## Implementation Notes",
        feature_name))

    print("📁 Created feature directory: " .. feature_path)
    print("📝 Next steps:")
    print("   1. Review generated spec.md")
    print("   2. Use :GenerateTaskList to generate tasks")
    print("   3. Use :TaskToCode to generate code")

    -- Open the spec file
    vim.cmd("edit " .. get_spec_path(feature_name))
  else
    print_error("Failed to generate specification: " .. (spec_error or "Unknown error"))

    -- Create basic structure as fallback
    local basic_spec = string.format([[# %s

## Overview
%s

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2]], feature_name, description)

    write_file(get_spec_path(feature_name), basic_spec)
    write_file(get_tasks_path(feature_name),
      string.format("# Tasks for %s\n\n*Generate tasks using :GenerateTaskList*", feature_name))
    write_file(get_design_path(feature_name),
      string.format("# Design Notes for %s\n\n## Architecture\n\n## Technical Details\n\n## Implementation Notes",
        feature_name))

    print("📁 Created feature directory with basic template: " .. feature_path)
    vim.cmd("edit " .. get_spec_path(feature_name))
  end
end

-- Enhanced create feature with multi-input UI
function M.create_feature_interactive()
  -- Simple input prompt for feature description
  vim.ui.input({
    prompt = "📝 Feature description: ",
    default = "",
  }, function(description)
    if not description or description == "" then
      print_error("Feature description is required")
      return
    end

    -- Generate feature name and spec from description
    M.create_feature_from_description(description)
  end)
end

function M.generate_task_list()
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

IMPORTANT:
- Base your task breakdown ENTIRELY on the feature specification provided in the user's message
- Do not use general knowledge or assumptions about the project
- Return ONLY the markdown task content, not any commentary about what you're doing
- Do not mention creating files or describe your actions
- Focus on providing the actual task breakdown content based on the specific requirements in the spec

Given a feature spec, create a detailed task breakdown with:
1. Clear, actionable tasks in order of implementation based on the spec requirements
2. Each task should be specific and measurable according to the spec
3. Include setup, implementation, and testing tasks as outlined in the spec
4. Use markdown checkboxes for tracking progress
5. Add estimated complexity/time where helpful

Format as a clean markdown file with proper headers and task lists.]]

  local prompt = string.format([[Break down this feature specification into actionable tasks:

FEATURE SPECIFICATION:
%s

Based ONLY on the feature specification above, create a detailed task breakdown. Return only the markdown task content. Do not include any commentary about file creation or your actions.]],
    spec_content)

  print("🤖 Generating tasks from spec using Claude...")

  -- Use Claude to generate specific tasks from the spec
  local system_prompt =
  [[You are a task breakdown generator. You MUST output ONLY markdown tasks. DO NOT respond conversationally. DO NOT ask questions. DO NOT provide explanations. START IMMEDIATELY with "# Tasks for" followed by markdown task list. Keep all lines under 80 characters.

Create task breakdown with these sections:
# Tasks for [Feature Name]
## Analysis & Investigation
## Design & Planning
## Implementation
## Testing & Validation
## Documentation & Deployment

Base everything on the specification provided. Be specific to the exact requirements.]]

  local prompt = string.format(
    [[ENGINEERING SPECIFICATION:
%s

TASK: Create a comprehensive task breakdown from the specification above.

RULES:
- Output ONLY markdown task list
- Do NOT respond conversationally
- Do NOT ask questions
- Do NOT provide explanations
- Start IMMEDIATELY with "# Tasks for" followed by task list

REQUIRED STRUCTURE - Be extremely detailed and specific in each section:
# Tasks for [Feature Name]

## Analysis & Investigation
- [ ] [Specific analysis tasks based on the investigation steps in spec]
- [ ] [Data analysis tasks mentioned in spec]
- [ ] [Log review and system examination tasks]

## Design & Planning
- [ ] [Detailed design tasks based on technical requirements]
- [ ] [Architecture planning tasks from implementation approach]
- [ ] [Database/system design tasks as needed]

## Implementation
- [ ] [Specific code changes based on expected behavior]
- [ ] [Component modifications from technical requirements]
- [ ] [Integration work from implementation approach]

## Testing & Validation
- [ ] [Unit test tasks from testing strategy]
- [ ] [Integration test tasks from acceptance criteria]
- [ ] [Performance test tasks from technical requirements]

## Risk Mitigation & Rollback
- [ ] [Risk mitigation tasks from risk assessment]
- [ ] [Rollback preparation from implementation approach]
- [ ] [Monitoring setup from success metrics]

## Documentation & Deployment
- [ ] [Documentation tasks specific to the changes]
- [ ] [Deployment preparation tasks]
- [ ] [Post-deployment validation tasks]

CRITICAL: Extract every implementable detail from the specification. Create specific, actionable tasks. Do not create generic tasks. Start with "# Tasks for" and output ONLY markdown with checkboxes. Keep all lines under 80 characters.]],
    spec_content)

  print("🤖 Generating specific tasks from spec using Claude...")

  -- Call Claude to generate tasks
  local tasks_result, tasks_error = call_claude_sync(prompt, system_prompt, "Generate Tasks from Spec")

  local tasks_path = get_tasks_path(feature_name)

  if tasks_result and not tasks_error then
    -- Clean up conversational responses and extract only markdown
    local cleaned_tasks = clean_claude_response(tasks_result)

    -- Validate that we got proper tasks (should start with # Tasks for)
    if cleaned_tasks:match("^%s*#%s*Tasks%s+for") then
      write_file(tasks_path, cleaned_tasks)
      print("✅ Generated specific tasks in tasks.md")
    else
      -- If no proper markdown found, use fallback
      local placeholder_tasks = string.format([[# Tasks for %s

## 🤖 Task Generation Failed - Conversational Response

Claude responded conversationally instead of generating tasks.

Original Claude response:
%s

Please manually create the tasks or adjust the Claude prompt.

See spec.md for the feature specification.]], feature_name, tasks_result)

      write_file(tasks_path, placeholder_tasks)
      print_error("Task generation failed - Claude responded conversationally")
    end
  else
    -- Fallback to placeholder if Claude failed
    local placeholder_tasks = string.format([[# Tasks for %s

## 🤖 Task Generation Failed

%s

Please manually create the tasks or try again.

See spec.md for the feature specification.]], feature_name, tasks_error or "Claude generation failed")

    write_file(tasks_path, placeholder_tasks)
    print_error("Task generation failed - created placeholder tasks.md")
  end

  -- Refresh the buffer if it's open
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name:match(feature_name .. "/tasks%.md$") then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("edit!")
      end)
      break
    end
  end
  vim.cmd("edit " .. tasks_path)
end

function M.task_to_code()
  local feature_name = get_current_feature()
  if not feature_name then
    print_error("No feature found. Use :CreateFeatureFromJira or :CreateFeature")
    return
  end

  -- Get current line (task)
  local current_line = vim.fn.getline(".")
  if not current_line:match("^%s*-.*") and not current_line:match("^%s*%d+%.") then
    print_error("Cursor not on a task line")
    return
  end

  -- Get file context
  local tasks_content = read_file(get_tasks_path(feature_name))
  local spec_content = read_file(get_spec_path(feature_name))

  if not tasks_content or tasks_content == "" then
    print_error("No tasks found. Generate tasks first with :GenerateTaskList")
    return
  end

  if not spec_content or spec_content == "" then
    print_error("No specification found. Create spec.md first")
    return
  end

  -- Get existing files in the feature directory for context
  local feature_path = get_feature_path(feature_name)
  local existing_files = {}
  local existing_files_list = vim.fn.glob(feature_path .. "/*", false, true)

  for _, file_path in ipairs(existing_files_list) do
    if not file_path:match("%.md$") then -- Skip markdown files
      local file_name = vim.fn.fnamemodify(file_path, ":t")

      -- Skip common large/irrelevant files
      if not (file_name:match("%.log$") or file_name:match("%.tmp$") or
            file_name:match("%.cache$") or file_name:match("%.lock$") or
            file_name:match("node_modules") or file_name:match("%.git")) then
        table.insert(existing_files, file_name)
      end
    end
  end

  -- Create complete prompt for Claude including context and implementation request
  local full_prompt = string.format([[# Task Implementation Context

## Current Task
%s

## Feature: %s

## Specification
%s

## All Tasks (for context)
%s

## Existing Files
%s

---

Please implement the code for the current task described above. Generate clean, production-ready code.]],
    current_line, feature_name, spec_content, tasks_content,
    #existing_files > 0 and ("- " .. table.concat(existing_files, "\n- ")) or "None")

  -- Write prompt to temp file to avoid shell quoting issues
  local temp_prompt_file = get_feature_path(feature_name) .. "/.task_prompt.txt"
  write_file(temp_prompt_file, full_prompt)

  print("🚀 Launching Claude CLI for task implementation...")
  print("🎯 Task: " .. current_line)
  print("📁 Feature: " .. feature_name)

  -- Launch Claude using bash to avoid fish shell quoting issues
  local claude_cmd = string.format("bash -c 'claude \"$(cat %s)\" --model %s && rm %s'", temp_prompt_file,
    config.claude_model, temp_prompt_file)
  vim.cmd(string.format("FloatermNew --title=TaskToCode --width=0.9 --height=0.9 %s", claude_cmd))
end

-- Generate code for ALL tasks in the feature
function M.generate_all_code()
  local feature_name = get_current_feature()
  if not feature_name then
    print_error("No feature found. Use :CreateFeatureFromJira or :CreateFeature")
    return
  end

  -- Get file context
  local tasks_content = read_file(get_tasks_path(feature_name))
  local spec_content = read_file(get_spec_path(feature_name))

  if not tasks_content or tasks_content == "" then
    print_error("No tasks found. Generate tasks first with :GenerateTaskList")
    return
  end

  if not spec_content or spec_content == "" then
    print_error("No specification found. Create spec.md first")
    return
  end

  -- Get existing files in the feature directory for context
  local feature_path = get_feature_path(feature_name)
  local existing_files = {}
  local existing_files_list = vim.fn.glob(feature_path .. "/*", false, true)

  for _, file_path in ipairs(existing_files_list) do
    if not file_path:match("%.md$") then -- Skip markdown files
      local file_name = vim.fn.fnamemodify(file_path, ":t")

      -- Skip common large/irrelevant files
      if not (file_name:match("%.log$") or file_name:match("%.tmp$") or
            file_name:match("%.cache$") or file_name:match("%.lock$") or
            file_name:match("node_modules") or file_name:match("%.git")) then
        table.insert(existing_files, file_name)
      end
    end
  end

  -- Create complete prompt for Claude including context and implementation request
  local full_prompt = string.format([[# Complete Feature Implementation Context

## Feature: %s

## Specification
%s

## ALL Tasks to Implement
%s

## Existing Files
%s

---

Please implement complete code for ALL tasks described above. Generate all necessary files with clean, production-ready code.]],
    feature_name, spec_content, tasks_content,
    #existing_files > 0 and ("- " .. table.concat(existing_files, "\n- ")) or "None")

  -- Write prompt to temp file to avoid shell quoting issues
  local temp_prompt_file = get_feature_path(feature_name) .. "/.all_tasks_prompt.txt"
  write_file(temp_prompt_file, full_prompt)

  print("🚀 Launching Claude CLI for complete feature implementation...")
  print("📁 Feature: " .. feature_name)
  print("🎯 Implementing ALL tasks")

  -- Launch Claude using bash to avoid fish shell quoting issues
  local claude_cmd = string.format("bash -c 'claude \"$(cat %s)\" --model %s && rm %s'", temp_prompt_file,
    config.claude_model, temp_prompt_file)
  vim.cmd(string.format("FloatermNew --title=GenerateAllCode --width=0.9 --height=0.9 %s", claude_cmd))
end

function M.open_feature_files()
  local feature_name = get_current_feature()
  if not feature_name then
    local ticket_number = get_jira_ticket_from_branch()
    if ticket_number then
      print("❌ No feature directory found for ticket: " .. ticket_number)
      print("💡 Create feature first with :CreateFeatureFromJira or :CreateFeature")
    else
      print("❌ Not in a feature directory and no Jira ticket detected in branch name")
      print("💡 Switch to a feature branch or create a new feature")
    end
    return
  end

  -- Check if feature was found via branch detection
  local current_file = vim.fn.expand("%:p")
  local in_feature_dir = current_file:match("/" .. config.features_dir .. "/([^/]+)/")
  if not in_feature_dir then
    local ticket_number = get_jira_ticket_from_branch()
    print("🎯 Opening feature '" .. feature_name .. "' detected from branch: " .. (ticket_number or "unknown"))
  end

  -- Open all feature files in tabs
  vim.cmd("tabedit " .. get_spec_path(feature_name))
  vim.cmd("tabedit " .. get_tasks_path(feature_name))
  vim.cmd("tabedit " .. get_design_path(feature_name))

  -- Open ticket.md if it exists
  local ticket_path = get_ticket_path(feature_name)
  if vim.fn.filereadable(ticket_path) == 1 then
    vim.cmd("tabedit " .. ticket_path)
  end

  -- Find and open source files
  local feature_path = get_feature_path(feature_name)
  local source_files = vim.fn.glob(feature_path .. "/*", false, true)

  for _, file in ipairs(source_files) do
    if not file:match("%.md$") then
      vim.cmd("tabedit " .. file)
    end
  end
end

function M.start_work()
  -- Wrapper function with comprehensive error handling
  local success, err = pcall(function()
    print("🚀 Starting work on Jira ticket...")

    -- Always prompt user for ticket number or URL
    local input = vim.fn.input("Enter Jira ticket number (e.g., LIB-123): ")
    if not input or input == "" then
      print_error("No ticket number provided")
      return
    end

    local ticket_number = extract_ticket_number(input)
    if not ticket_number then
      print_error("Could not extract valid ticket number from: " .. input)
      return
    end

    print("🎫 Using ticket: " .. ticket_number)

    -- Fetch ticket data from Jira
    print("📡 Fetching ticket data from Jira...")
    local ticket = fetch_jira_ticket(ticket_number)
    if not ticket then
      print_error("Failed to fetch ticket data")
      return
    end

    print("✅ Successfully fetched ticket: " .. ticket.summary)

    -- Determine branch prefix based on issue type (conventional patterns)
    local branch_prefix = "feat"
    local issue_type_lower = ticket.issue_type:lower()
    if issue_type_lower:match("bug") or issue_type_lower:match("defect") then
      branch_prefix = "fix"
    elseif issue_type_lower:match("task") or issue_type_lower:match("chore") then
      branch_prefix = "chore"
    elseif issue_type_lower:match("improvement") or issue_type_lower:match("enhancement") then
      branch_prefix = "feat"
    elseif issue_type_lower:match("spike") or issue_type_lower:match("research") then
      branch_prefix = "spike"
    end

    -- Create temporary branch name (will be updated after spec generation)
    local temp_sanitized_summary = ticket.summary:lower()
        :gsub("[^%w%s%-]", "") -- Remove special chars except word chars, spaces, hyphens
        :gsub("%s+", "-")      -- Replace spaces with hyphens
        :gsub("%-+", "-")      -- Replace multiple hyphens with single
        :gsub("^%-", "")       -- Remove leading hyphen
        :gsub("%-$", "")       -- Remove trailing hyphen

    -- Limit temporary branch name length
    if #temp_sanitized_summary > 45 then
      temp_sanitized_summary = temp_sanitized_summary:sub(1, 45):gsub("%-*$", "")
    end

    local temp_branch_name = string.format("%s/%s-%s", branch_prefix, ticket.key:lower(), temp_sanitized_summary)

    -- Create and checkout temporary branch
    print("🌿 Creating temporary branch: " .. temp_branch_name)
    local git_result = vim.fn.system("git checkout -b " .. vim.fn.shellescape(temp_branch_name) .. " 2>&1")
    if vim.v.shell_error ~= 0 then
      print("⚠️  Branch creation failed (might already exist): " .. git_result:gsub("\n", " "))
      print("🔄 Attempting to checkout existing branch...")
      git_result = vim.fn.system("git checkout " .. vim.fn.shellescape(temp_branch_name) .. " 2>&1")
      if vim.v.shell_error ~= 0 then
        print("❌ Failed to checkout branch: " .. git_result:gsub("\n", " "))
        return
      end
    end

    print("✅ Successfully checked out temporary branch: " .. temp_branch_name)

    -- Create descriptive feature name from ticket data
    local feature_name = create_feature_name_from_ticket(ticket)
    if not feature_name then
      print_error("Failed to create feature name from ticket data")
      return
    end
    print("📁 Creating feature directory: " .. feature_name)

    -- Build comprehensive description for Claude
    print("🔍 DEBUG: start_work - Building description with:")
    print("   Description length: " .. string.len(ticket.description))
    print("   Description preview: " .. string.sub(ticket.description, 1, 100) .. "...")

    local comprehensive_description = string.format([[**Jira Ticket:** %s
**Type:** %s
**Priority:** %s
**Status:** %s
**Assignee:** %s
**Reporter:** %s

**Summary:** %s

**Description:**
%s

**Components:** %s
**Labels:** %s%s%s

**Created:** %s
**Updated:** %s]],
      ticket.key,
      ticket.issue_type,
      ticket.priority,
      ticket.status,
      ticket.assignee,
      ticket.reporter,
      ticket.summary,
      ticket.description,
      table.concat(ticket.components, ", "),
      table.concat(ticket.labels, ", "),
      ticket.parent_info,
      ticket.subtasks_info,
      ticket.created,
      ticket.updated
    )

    -- Create feature with comprehensive ticket data
    M.create_feature(feature_name, comprehensive_description)

    print("🎯 StartWork completed successfully!")
    print("📝 Next steps:")
    print("   1. Review generated spec.md")
    print("   2. Use :GenerateTaskList to generate tasks")
    print("   3. Use :TaskToCode to generate code")
  end)

  if not success then
    print("❌ StartWork failed with error: " .. tostring(err))
    print("🔍 Debug info:")
    print("   - Check Jira configuration in spec-driven-dev.lua")
    print("   - Verify internet connection")
    print("   - Check Jira credentials and permissions")
  end
end

function M.create_feature_from_jira()
  -- Always prompt user for ticket number or URL
  local input = vim.fn.input(
  "Enter Jira ticket number or URL (e.g., LIB-123 or https://company.atlassian.net/browse/LIB-123): ")
  if not input or input == "" then
    print_error("No ticket number provided")
    return
  end

  local ticket_number = extract_ticket_number(input)
  if not ticket_number then
    print_error("Could not extract valid ticket number from: " .. input)
    return
  end

  print("🎫 Using ticket: " .. ticket_number)

  -- Fetch ticket data from Jira
  print("📡 Fetching ticket data from Jira...")
  local ticket = fetch_jira_ticket(ticket_number)
  if not ticket then
    print("❌ Failed to fetch ticket data")
    return
  end

  print("✅ Successfully fetched ticket: " .. ticket.summary)

  -- Create descriptive feature name from ticket data
  local feature_name = create_feature_name_from_ticket(ticket)
  if not feature_name then
    print_error("Failed to create feature name from ticket data")
    return
  end
  print("📁 Feature name: " .. feature_name)

  -- Build comprehensive description for Claude
  print("🔍 DEBUG: Building description with:")
  print("   Description length: " .. string.len(ticket.description))
  print("   Description preview: " .. string.sub(ticket.description, 1, 100) .. "...")

  local comprehensive_description = string.format([[**Jira Ticket:** %s
**Type:** %s
**Priority:** %s
**Status:** %s
**Assignee:** %s
**Reporter:** %s

**Summary:** %s

**Description:**
%s

**Components:** %s
**Labels:** %s%s%s

**Created:** %s
**Updated:** %s]],
    ticket.key,
    ticket.issue_type,
    ticket.priority,
    ticket.status,
    ticket.assignee,
    ticket.reporter,
    ticket.summary,
    ticket.description,
    table.concat(ticket.components, ", "),
    table.concat(ticket.labels, ", "),
    ticket.parent_info,
    ticket.subtasks_info,
    ticket.created,
    ticket.updated
  )

  -- Create feature with comprehensive ticket data
  M.create_feature(feature_name, comprehensive_description)

  print("🎯 Feature created from Jira ticket!")
  print("📝 Next steps:")
  print("   1. Review generated spec.md")
  print("   2. Use :GenerateTaskList to generate tasks")
  print("   3. Use :TaskToCode to generate code")
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
    if not args.args or args.args == "" then
      M.create_feature_interactive()
      return
    end

    local args_table = {}
    for arg in args.args:gmatch("%S+") do
      table.insert(args_table, arg)
    end

    local first_arg = args_table[1]
    local remaining_args = table.concat(args_table, " ", 2)

    -- Check if first argument is a dasherized feature name or a description
    local is_feature_name = first_arg:match("^[a-z0-9-]+$") and first_arg:match("-")

    if is_feature_name then
      -- First arg is a feature name, rest is description
      local feature_name = first_arg
      local description = remaining_args
      M.create_feature(feature_name, description)
    else
      -- First arg is part of description, generate feature name
      local full_description = args.args
      print("🤖 Generating feature name from description using Claude...")

      local generated_name = M.generate_feature_name_from_description(full_description)
      if generated_name then
        print("✅ Generated feature name: " .. generated_name)
        M.create_feature(generated_name, full_description)
      else
        print("Failed to generate feature name, using interactive form...")
        M.create_feature_interactive()
      end
    end
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("StartWork", M.start_work, {})
  vim.api.nvim_create_user_command("CreateFeatureFromJira", M.create_feature_from_jira, {})
  vim.api.nvim_create_user_command("OpenFeature", M.open_feature_files, {})
  vim.api.nvim_create_user_command("GenerateTaskList", M.generate_task_list, {})
  vim.api.nvim_create_user_command("TaskToCode", M.task_to_code, {})
  vim.api.nvim_create_user_command("GenerateAllCode", M.generate_all_code, {})
end

return M
