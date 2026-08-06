local tnoremap = require('user.keymaps.bind').tnoremap
local long_press_aware_keybinding = require('user.keymaps.long_press').long_press_aware_keybinding
local terminal_ai_agent_jobs = {}

local function get_project_root()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  for _, client in ipairs(clients) do
    local root_dir = client.config.root_dir
    if root_dir then return root_dir end
  end

  return vim.fn.getcwd()
end

local function get_env_from_tmux(name)
  if not vim.env.TMUX then return nil end

  local value = vim.fn.system({ 'tmux', 'show-environment', '-g', name })
  if vim.v.shell_error ~= 0 then return nil end

  return value:match('^' .. name .. '=(.*)%s*$')
end

local function explicit_preferred_ai_agent()
  return vim.env.DEFAULT_AGENT
    or vim.env.AGENT
    or get_env_from_tmux('DEFAULT_AGENT')
    or get_env_from_tmux('AGENT')
end

local function default_ai_agent()
  if vim.fn.executable('codex') == 1 then return 'codex' end
  if vim.fn.executable('claude') == 1 then return 'claude' end

  return 'claude'
end

local function preferred_ai_agent()
  local agent = explicit_preferred_ai_agent() or default_ai_agent()

  return vim.trim(agent)
end

local function preferred_ai_agent_args()
  local args = vim.env.DEFAULT_AGENT_ARGS
    or get_env_from_tmux('DEFAULT_AGENT_ARGS')
    or ''

  return vim.trim(args)
end

local function ai_agent_split_args()
  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)

  if width / height > 2.4 then
    return { '--width', '30' }
  end

  return { '--height', '40' }
end

local function ai_agent_tag(root, agent)
  return 'nvim-ai-agent:' .. agent .. ':' .. root
end

local function map_ai_terminal_navigation(buffer)
  tnoremap('<C-h>', '<cmd>lua require("tmux").move_left()<cr>', { buffer = buffer })
  tnoremap('<C-j>', '<cmd>lua require("tmux").move_bottom()<cr>', { buffer = buffer })
  tnoremap('<C-k>', '<cmd>lua require("tmux").move_top()<cr>', { buffer = buffer })
  tnoremap('<C-l>', '<cmd>lua require("tmux").move_right()<cr>', { buffer = buffer })
end

local function open_terminal_ai_agent(command, agent)
  local root = get_project_root()
  local command_with_error_pause = command
    .. [[; status=$?; if [ "$status" -ne 0 ]; then printf '\nAI agent exited with status %s.\nPress Enter to close...' "$status"; read -r _; fi]]

  if vim.env.TMUX then
    local tmux_command = { 'tmux-run', '--tag', ai_agent_tag(root, agent) }
    vim.list_extend(tmux_command, ai_agent_split_args())
    table.insert(tmux_command, command_with_error_pause)

    vim.fn.jobstart(tmux_command, { detach = true, cwd = root })
    return
  end

  vim.cmd('botright 20split')
  terminal_ai_agent_jobs[ai_agent_tag(root, agent)] = vim.fn.termopen(
    { '/bin/sh', '-c', command_with_error_pause },
    { cwd = root }
  )
  map_ai_terminal_navigation(vim.api.nvim_get_current_buf())
  vim.cmd('startinsert')
end

local function open_claude_code()
  if vim.fn.exists(':ClaudeCode') == 0 then
    local ok, lazy = pcall(require, 'lazy')

    if ok then
      lazy.load({ plugins = { 'claudecode.nvim' } })
    end
  end

  vim.cmd('ClaudeCode')
end

local function open_preferred_ai_agent()
  local agent = preferred_ai_agent()
  local args = preferred_ai_agent_args()
  local normalized_agent = agent:lower():gsub('[%s_%-]+', '')

  if agent == '' then
    vim.notify('DEFAULT_AGENT/AGENT is empty; falling back to claude', vim.log.levels.WARN)
    open_claude_code()
    return
  end

  if args == '' and (normalized_agent == 'claude' or normalized_agent == 'claudecode') then
    open_claude_code()
    return
  end

  open_terminal_ai_agent(vim.trim(agent .. ' ' .. args), normalized_agent)
end

local function current_visual_selection()
  local start_pos = vim.fn.getpos('v')
  local end_pos = vim.fn.getpos('.')
  local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.mode() })

  if #lines == 0 then return nil end

  local root = get_project_root()
  local file = vim.api.nvim_buf_get_name(0)
  local relative_file = vim.fs.relpath(root, file) or file
  local first_line = math.min(start_pos[2], end_pos[2])
  local last_line = math.max(start_pos[2], end_pos[2])
  local header = string.format('[Selection from %s:%d-%d]', relative_file, first_line, last_line)

  return header .. '\n' .. table.concat(lines, '\n'), root
end

local function find_ai_agent_tmux_pane(root, agent)
  local panes = vim.fn.system({ 'tmux', 'list-panes', '-a', '-F', '#{pane_id}\t#{@tmux_run_tag}' })
  if vim.v.shell_error ~= 0 then return nil end

  local expected_tag = ai_agent_tag(root, agent)
  for _, line in ipairs(vim.split(panes, '\n', { trimempty = true })) do
    local pane_id, tag = line:match('^(%%%d+)\t(.*)$')
    if tag == expected_tag then return pane_id end
  end

  return nil
end

local function paste_into_terminal_agent(text, root, agent, success_message)
  if vim.env.TMUX then
    local pane_id = find_ai_agent_tmux_pane(root, agent)
    if not pane_id then
      vim.notify('No AI agent opened by <leader>ac for this project', vim.log.levels.WARN)
      return
    end

    local buffer_name = 'nvim-ai-selection-' .. vim.fn.getpid()
    vim.fn.system({ 'tmux', 'load-buffer', '-b', buffer_name, '-' }, text)
    if vim.v.shell_error ~= 0 then
      vim.notify('Could not copy the selection into tmux', vim.log.levels.ERROR)
      return
    end

    vim.fn.system({ 'tmux', 'paste-buffer', '-d', '-p', '-b', buffer_name, '-t', pane_id })
    if vim.v.shell_error ~= 0 then
      vim.notify('Could not paste the selection into the AI agent', vim.log.levels.ERROR)
      return
    end

    vim.notify(success_message)
    return
  end

  local job_id = terminal_ai_agent_jobs[ai_agent_tag(root, agent)]
  if not job_id or vim.fn.jobwait({ job_id }, 0)[1] ~= -1 then
    vim.notify('No AI agent opened by <leader>ac for this project', vim.log.levels.WARN)
    return
  end

  vim.fn.chansend(job_id, '\27[200~' .. text .. '\27[201~')
  vim.notify(success_message)
end

local function send_selection_to_preferred_ai_agent()
  local agent = preferred_ai_agent()
  local args = preferred_ai_agent_args()
  local normalized_agent = agent:lower():gsub('[%s_%-]+', '')

  if agent == '' or (args == '' and (normalized_agent == 'claude' or normalized_agent == 'claudecode')) then
    if vim.fn.exists(':ClaudeCodeSend') == 0 then
      local ok, lazy = pcall(require, 'lazy')
      if ok then lazy.load({ plugins = { 'claudecode.nvim' } }) end
    end

    vim.cmd('ClaudeCodeSend')
    return
  end

  local selection, root = current_visual_selection()
  if selection then
    paste_into_terminal_agent(selection, root, normalized_agent, 'Added selection to the AI agent prompt')
  end
end

local function mini_files_paths(first_line, last_line)
  local ok, mini_files = pcall(require, 'mini.files')
  if not ok then return nil, 'mini.files is not available' end

  local root = get_project_root()
  local bufnr = vim.api.nvim_get_current_buf()
  local paths = {}
  local seen = {}

  for line = first_line, last_line do
    local entry_ok, entry = pcall(mini_files.get_fs_entry, bufnr, line)
    if entry_ok and entry and entry.path and entry.path ~= '' then
      local path = entry.path:gsub('^minifiles://[^/]*/', '')
      path = vim.fs.normalize(path)
      local relative_path = vim.fs.relpath(root, path) or path

      if not seen[relative_path] then
        seen[relative_path] = true
        table.insert(paths, relative_path)
      end
    end
  end

  if #paths == 0 then return nil, 'No files selected in mini.files' end

  return paths, root
end

local function send_mini_files_to_preferred_ai_agent(first_line, last_line)
  local agent = preferred_ai_agent()
  local args = preferred_ai_agent_args()
  local normalized_agent = agent:lower():gsub('[%s_%-]+', '')

  if agent == '' or (args == '' and (normalized_agent == 'claude' or normalized_agent == 'claudecode')) then
    if vim.fn.exists(':ClaudeCodeTreeAdd') == 0 then
      local ok, lazy = pcall(require, 'lazy')
      if ok then lazy.load({ plugins = { 'claudecode.nvim' } }) end
    end

    vim.cmd('ClaudeCodeTreeAdd')
    return
  end

  local paths, root_or_error = mini_files_paths(first_line, last_line)
  if not paths then
    vim.notify(root_or_error, vim.log.levels.WARN)
    return
  end

  local count = #paths
  local message = count == 1 and 'Added file path to the AI agent prompt'
    or string.format('Added %d file paths to the AI agent prompt', count)
  paste_into_terminal_agent(table.concat(paths, '\n'), root_or_error, normalized_agent, message)
end

return {
  {
    'preferred-ai-agent-keymap',
    dir = vim.fn.stdpath('config'),
    lazy = false,
    init = function()
      vim.keymap.set('n', '<leader>ac', open_preferred_ai_agent, { desc = 'ai: open preferred agent' })
      vim.keymap.set('v', '<leader>as', send_selection_to_preferred_ai_agent, { desc = 'ai: send selection' })
      vim.api.nvim_create_user_command('PreferredAiAgentSendFiles', function(opts)
        local first_line = opts.range > 0 and opts.line1 or vim.fn.line('.')
        local last_line = opts.range > 0 and opts.line2 or first_line
        send_mini_files_to_preferred_ai_agent(first_line, last_line)
      end, { range = true, desc = 'Send MiniFiles paths to the preferred AI agent' })
    end,
  },
  {
    -- 'robitx/gp.nvim',
    'jdurand/gp.nvim',
    branch = 'fix/ollama',
    config = function()
      require('gp').setup({
        providers = {
          anthropic = {
            endpoint = "https://api.anthropic.com/v1/messages",
            secret = os.getenv("ANTHROPIC_API_KEY"),
          },
          googleai = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{{model}}:streamGenerateContent?key={{secret}}",
            secret = os.getenv("GEMINI_API_KEY"),
          },
          openai = {
            endpoint = "https://api.openai.com/v1/chat/completions",
            secret = os.getenv("OPENAI_API_KEY"),
          },
          ollama = {
            endpoint = "http://localhost:11434/api/chat",
          },
        },
        agents = {
          --
          -- Anthropic Models
          --
          {
            provider = "anthropic",
            name = "CodeClaude-3-5-Haiku",
            -- $1/1M input, $5/1M output | fast, low cost, basic tasks
            chat = false,
            command = true,
            -- string with model name or table with model name and parameters
            model = { model = "claude-3-5-haiku-latest", temperature = 0.8, top_p = 1 },
            system_prompt = require("gp.defaults").code_system_prompt,
          },
          { -- default
            name = 'CodeClaude-3-7-Sonnet',
            disable = true,
            -- $3/1M input, $15/1M output | high quality, moderate speed
          },
          -- {
          --   provider = "anthropic",
          --   name = "CodeClaude-4-0-Sonnet",
          --   chat = false,
          --   command = true,
          --   -- $3/1M input, $15/1M output | high quality, moderate speed, 1M context
          --   model = {
          --     model = 'claude-sonnet-4-20250514',
          --     temperature = 0.8,
          --     top_p = 0.9
          --   },
          --   system_prompt = require('gp.defaults').code_system_prompt,
          -- },

          --
          -- Google AI Models
          --
          {
            provider = 'googleai',
            name = 'CodeGemini-flash',
            chat = false,
            command = true,
            -- $0.075/1M input, $0.30/1M output | ultra low cost, high volume, low latency
            model = {
              model = 'gemini-1.5-flash',
              -- Alternative models you could use:
              -- - gemini-1.5-pro (more capable but slower)
              -- - gemini-1.5-flash-8b (smaller, faster variant)
              temperature = 0.8,
              top_p = 0.9
            },
            system_prompt = require('gp.defaults').code_system_prompt,
          },
          {
            name = 'CodeGemini',
            disable = true,
            -- TODO: Is this pro or flash?
            -- Pro: $7/1M input, $21/1M output | multimodal, 2M context
          },

          --
          -- OpenAI Models
          --
          {
            provider = 'openai',
            name = 'CodeGPT5-nano',
            chat = false,
            command = true,
            -- $0.05/1M input, $0.40/1M output | ultra low cost, 4 reasoning levels, 272k context
            model = {
              model = 'gpt-5-nano',
              temperature = 1.0
            },
            system_prompt = table.concat({
              "Always remove any trailing spaces or tabs at the ends of lines.",
              "Preserve necessary indentation but ensure no trailing whitespace.",
              require("gp.defaults").code_system_prompt,
            }, "\n"),
          },
          -- { -- default
          --   name = 'CodeGPT4o-mini',
          --   disable = true,
          --   -- $0.15/1M input, $0.60/1M output | very low cost, low latency, 128k context
          -- },
          -- {
          --   provider = 'openai',
          --   name = 'CodeGPT5-mini',
          --   chat = false,
          --   command = true,
          --   -- $0.25/1M input, $2/1M output | very low cost, 4 reasoning levels, 272k context
          --   model = {
          --     model = 'gpt-5-mini',
          --     temperature = 1.0
          --   },
          --   system_prompt = table.concat({
          --     "Always remove any trailing spaces or tabs at the ends of lines.",
          --     "Preserve necessary indentation but ensure no trailing whitespace.",
          --     require("gp.defaults").code_system_prompt,
          --   }, "\n"),
          -- },
          {
            name = 'CodeGPT-o3-mini',
            disable = true,
            -- pricing TBD | reasoning model, optimized for coding/math/science
          },
          -- {
          --   provider = 'openai',
          --   name = 'CodeGPT5',
          --   chat = false,
          --   command = true,
          --   -- $1.25/1M input, $10/1M output | flagship model, competitive pricing
          --   model = {
          --     model = 'gpt-5',
          --     temperature = 1.0
          --   },
          --   system_prompt = require('gp.defaults').code_system_prompt,
          -- },
          { -- default
            name = 'CodeGPT4o',
            disable = true,
            -- $2.50/1M input, $10/1M output | multimodal, vision, 128k context
          },

          --
          -- Open Source Models
          --
          {
            provider = 'ollama',
            name = 'CodeOllamaGemma3-4B',
            chat = false,
            command = true,
            -- FREE local inference | ~134 tokens/s, ~4GB VRAM/RAM, multimodal, 128k context
            model = {
              model = 'gemma3',
              -- temperature = 0.7,
              -- top_p = 0.9,
              -- min_p = 0.05,
            },
            system_prompt = require('gp.defaults').code_system_prompt,
            -- system prompt (use this to specify the persona/role of the AI)
            -- system_prompt = "You are a general AI assistant.",
          },
          -- { -- default
          --   name = "CodeOllamaLlama3.1-8B", -- standard agent name to disable
          --   disable = true,
          --   -- FREE local inference | ~33 tokens/s, ~16GB VRAM, multilingual, 128k context, GQA architecture
          -- },
        }
      })

      -- Visual mode mappings
      vim.keymap.set('v', '<leader>aa', ":<C-u>'<,'>GpRewrite<cr>", { desc = 'gp: rewrite selection' })
      vim.keymap.set('v', '<leader>ar', ":<C-u>'<,'>GpRewrite<cr>", { desc = 'gp: rewrite selection' })
      vim.keymap.set('v', '<leader>ao', ":<C-u>'<,'>GpAppend<cr>", { desc = 'gp: append after selection' })
      vim.keymap.set('v', '<leader>aO', ":<C-u>'<,'>GpPrepend<cr>", { desc = 'gp: prepend before selection' })
      vim.keymap.set('v', '<leader>ai', ":<C-u>'<,'>GpImplement<cr>", { desc = 'gp: implement from selection' })
      vim.keymap.set('v', '<leader>ax', ":<C-u>'<,'>GpContext<cr>", { desc = 'gp: show context' })
      vim.keymap.set('v', '<leader>ac', '<cmd>GpStop<cr>', { desc = 'gp: stop current process' })

      -- Normal and Insert mode mappings
      vim.keymap.set({ 'n', 'i' }, '<leader>ao', '<cmd>GpAppend<cr>', { desc = 'gp: append after' })

      vim.keymap.set('n', '<leader>an', '<cmd>GpSelectAgent<cr>', { desc = 'gp: select AI agent' })
      vim.keymap.set({ 'v', 'i' }, '<leader>an', '<cmd>GpNextAgent<cr>', { desc = 'gp: next AI agent' })
    end,
  },
  {
    'coder/claudecode.nvim',
    dependencies = { 'folke/snacks.nvim' },
    config = function()
      -- default claude to resume last session
      local claude_options = ' --permission-mode "acceptEdits"  --allowed-tools "Edit Bash(git:*) Bash(grep:*) Bash(find:*) Bash(ls:*) Bash(cat:*) Bash(head:*) Bash(tail:*) Bash(wc:*) Bash(sort:*) Bash(uniq:*)"'

      ---@diagnostic disable: missing-fields
      require('claudecode').setup({
        terminal = {
          provider = 'external',
          provider_opts = {
            -- external_terminal_cmd = "tmux-run --width 30 %s" .. claude_options, -- Managed tmux horizontal split (30% width)
            -- external_terminal_cmd = "tmux-run --height 40 %s" .. claude_options, -- Managed tmux vertical split (40% height)
            -- external_terminal_cmd = "tmux-run --popup --size 150x50 %s" .. claude_options, -- Managed tmux popup (100x50)
            -- external_terminal_cmd = "tmux-run --popup %s" .. claude_options, -- Managed tmux popup (default 90x40)
            -- external_terminal_cmd = "kitty -e %s",
            -- external_terminal_cmd = "ghostty-run %s",
            external_terminal_cmd = function(cmd)
              -- Get current Neovim window dimensions
              local width = vim.api.nvim_win_get_width(0)
              local height = vim.api.nvim_win_get_height(0)

              -- Debug: Show dimensions and aspect ratio
              local aspect_ratio = width / height
              vim.notify(string.format("Neovim window: %d cols × %d rows (ratio: %.2f)", width, height, aspect_ratio), vim.log.levels.DEBUG)

              -- Choose split direction based on window aspect ratio
              -- Typical terminal is ~2:1 aspect ratio (80 cols × 40 rows)
              if aspect_ratio > 2.4 then
                return "tmux-run --width 30 " .. cmd .. claude_options -- Horizontal split for wider windows
              else
                return "tmux-run --height 40 " .. cmd .. claude_options -- Vertical split for taller windows
              end
            end
          },
        },

        diff_opts = {
          keep_terminal_focus = true,
        },
      })
      ---@diagnostic enable: missing-fields

      vim.api.nvim_create_autocmd('TermOpen', {
        pattern = '*',
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          local name = vim.api.nvim_buf_get_name(buffer)

          if name:match('claude') then
            -- -- Switch to normal mode when pressing Escape in terminal mode
            -- tnoremap('<Esc>', '<C-\\><C-n>', { buffer = buffer })
            --
            -- -- Send Escape when pressing Ctrl-X in terminal mode
            -- tnoremap('<C-x>', '<Esc>', { buffer = buffer })

            -- Map Ctrl+h/j/k/l to navigate between tmux panes
            map_ai_terminal_navigation(buffer)
          end
        end
      })
    end,
    keys = {
      { '<leader>a', nil, desc = 'AI/Agents' },
      { '<leader>aa', '<cmd>ClaudeCode<cr>', desc = 'claude: toggle' },

      -- Current external terminal setup is causing keybinding issues
      -- { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'claude: focus' },
      -- { '<leader>aR', '<cmd>ClaudeCode --resume<cr>', desc = 'claude: resume' },
      -- { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'claude: continue' },

      { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'claude: select model' },
      { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'claude: add current buffer' },
      {
        '<leader>as',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = 'Add file',
        ft = { 'NvimTree', 'neo-tree', 'oil' },
      },
      -- -- Diff management
      -- { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'claude: accept diff' },
      -- { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'claude: deny diff' },
    }
  },
  {
    'NickvanDyke/opencode.nvim',
    dependencies = {
      -- Recommended for better prompt input, and required to use opencode.nvim's embedded terminal — otherwise optional
      { 'folke/snacks.nvim', opts = { input = { enabled = true } } },
    },
    config = function()
      -- Required for `vim.g.opencode_opts.auto_reload`.
      vim.o.autoread = true

      vim.api.nvim_create_autocmd('TermOpen', {
        pattern = '*', -- Fire for all terminals
        callback = function(args)
          local buffer = args.buf

          -- Use pcall to safely check for the variable without erroring if it doesn't exist.
          local success, opencode_var = pcall(vim.api.nvim_buf_get_var, buffer, 'opencode_channel')

          -- Check if the pcall was successful and the variable is not nil
          if success and opencode_var ~= nil then
            -- We must exit Terminal Mode (t) to Normal Mode (n) before running window navigation (<C-w>...)
            -- This is done by sending the special sequence: <C-\><C-n>

            -- local opts = { noremap = true, silent = true, buffer = buffer }
            --
            -- -- Map Ctrl-H/J/K/L to exit terminal mode AND switch to the adjacent Neovim window
            -- -- NOTE: If you are using tmux, you may need a dedicated tmux integration plugin like `christoomey/vim-tmux-navigator`.
            --
            -- -- Move focus left: Exit Terminal Mode (<C-\><C-n>) then execute window move command (<C-w>h)
            -- tnoremap('<C-h>', '<C-\\><C-n><C-w>h', opts)
            --
            -- -- Move focus down: Exit Terminal Mode (<C-\><C-n>) then execute window move command (<C-w>j)
            -- tnoremap('<C-j>', '<C-\\><C-n><C-w>j', opts)
            --
            -- -- Move focus up: Exit Terminal Mode (<C-\><C-n>) then execute window move command (<C-w>k)
            -- tnoremap('<C-k>', '<C-\\><C-n><C-w>k', opts)
            --
            -- -- Move focus right: Exit Terminal Mode (<C-\><C-n>) then execute window move command (<C-w>l', opts)
            -- tnoremap('<C-l>', '<C-\\><C-n><C-w>l', opts)

            -- Map Ctrl+h/j/k/l to navigate between tmux panes
            tnoremap('<C-h>', '<cmd>lua require("tmux").move_left()<cr>', { buffer = buffer })
            tnoremap('<C-j>', '<cmd>lua require("tmux").move_bottom()<cr>', { buffer = buffer })
            tnoremap('<C-k>', '<cmd>lua require("tmux").move_top()<cr>', { buffer = buffer })
            tnoremap('<C-l>', '<cmd>lua require("tmux").move_right()<cr>', { buffer = buffer })
          end
        end
      })
    end,
    ---@type opencode.Opts
    opts = {
      -- Your configuration, if any — see lua/opencode/config.lua
    },
    keys = {
      -- Recommended keymaps
      { '<leader>Ac', function() require('opencode').ask() end, desc = 'Ask opencode', },
      { '<leader>As', function() require('opencode').ask('@cursor: ') end, desc = 'Ask opencode about this', mode = 'n', },
      { '<leader>As', function() require('opencode').ask('@selection: ') end, desc = 'Ask opencode about selection', mode = 'v', },
      { '<leader>Aa', function() require('opencode').toggle() end, desc = 'Toggle embedded opencode', mode = 'n' },
      { '<leader>An', function() require('opencode').command('session_new') end, desc = 'New session', },
      { '<leader>Ay', function() require('opencode').command('messages_copy') end, desc = 'Copy last message', },
      { '<S-C-u>',    function() require('opencode').command('messages_half_page_up') end, desc = 'Scroll messages up', },
      { '<S-C-d>',    function() require('opencode').command('messages_half_page_down') end, desc = 'Scroll messages down', },
      { '<leader>Ap', function() require('opencode').select_prompt() end, desc = 'Select prompt', mode = { 'n', 'v', }, },
      -- Example: keymap for custom prompt
      { '<leader>Ae', function() require('opencode').prompt("Explain @cursor and its context") end, desc = "Explain code near cursor", },
      { '<leader>aA', function() require('opencode').toggle() end, desc = 'Toggle embedded opencode', mode = 'n' },
    },
  }
}
