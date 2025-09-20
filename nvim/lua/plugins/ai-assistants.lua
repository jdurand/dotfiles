local tnoremap = require('user.keymaps.bind').tnoremap
local long_press_aware_keybinding = require('user.keymaps.long_press').long_press_aware_keybinding

local function get_project_root()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  for _, client in ipairs(clients) do
    local root_dir = client.config.root_dir
    if root_dir then return root_dir end
  end

  return vim.fn.getcwd()
end

return {
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
  -- {
  --   'yetone/avante.nvim',
  --   event = 'VeryLazy',
  --   version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  --   opts = {
  --     -- add any opts here
  --     -- for example
  --     provider = 'claude',
  --     providers = {
  --       claude = {
  --         endpoint = "https://api.anthropic.com",
  --         model = "claude-sonnet-4-20250514",
  --         timeout = 30000, -- Timeout in milliseconds
  --           extra_request_body = {
  --             temperature = 0.75,
  --             max_tokens = 20480,
  --           },
  --       },
  --       openai = {
  --         endpoint = 'https://api.openai.com/v1',
  --         model = 'gpt-5-mini', -- your desired model (or use gpt-4o, etc.)
  --         timeout = 30000, -- timeout in milliseconds
  --         -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
  --         extra_request_body = {
  --           temperature = 1.0, -- adjust if needed
  --         },
  --       },
  --     },
  --     -- behaviour = {
  --     --   enable_cursor_planning_mode = true, -- enable cursor planning mode!
  --     -- },
  --   },
  --   -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  --   build = vim.fn.has("win32") ~= 0
  --     and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
  --     or "make",
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     'MunifTanjim/nui.nvim',
  --     --- The below dependencies are optional,
  --     'echasnovski/mini.pick', -- for file_selector provider mini.pick
  --     'nvim-telescope/telescope.nvim', -- for file_selector provider telescope
  --     'hrsh7th/nvim-cmp', -- autocompletion for avante commands and mentions
  --     'ibhagwan/fzf-lua', -- for file_selector provider fzf
  --     'stevearc/dressing.nvim', -- for input provider dressing
  --     'folke/snacks.nvim', -- for input provider snacks
  --     'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
  --     'zbirenbaum/copilot.lua', -- for providers='copilot'
  --     {
  --       -- support for image pasting
  --       'HakonHarnes/img-clip.nvim',
  --       event = 'VeryLazy',
  --       opts = {
  --         -- recommended settings
  --         default = {
  --           embed_image_as_base64 = false,
  --           prompt_for_file_name = false,
  --           drag_and_drop = {
  --             insert_mode = true,
  --           },
  --           -- required for Windows users
  --           use_absolute_path = true,
  --         },
  --       },
  --     },
  --     {
  --       -- Make sure to set this up properly if you have lazy=true
  --       'MeanderingProgrammer/render-markdown.nvim',
  --       opts = {
  --         file_types = { 'markdown', 'Avante' },
  --       },
  --       ft = { 'markdown', 'Avante' },
  --     },
  --   },
  -- },
  {
    'monkoose/neocodeium',
    event = 'VeryLazy',
    dependencies = {
      'hrsh7th/nvim-cmp',
    },
    enabled = function()
      return vim.fn.filereadable(get_project_root() .. '/.windsurf_enabled') == 1
    end,
    config = function()
      local neocodeium = require('neocodeium')
      local cmp = require('cmp')

      vim.keymap.set('i', '<C-j>', neocodeium.cycle_or_complete)
      vim.keymap.set('i', '<C-k>', function() neocodeium.cycle_or_complete(-1) end)
      vim.keymap.set('i', '<C-c>', neocodeium.clear)
      vim.keymap.set('i', '<C-p>', neocodeium.accept)
      vim.keymap.set('i', '<C-f>', neocodeium.accept_word)
      -- vim.keymap.set('i', '<C-l>', neocodeium.accept_line)
      vim.keymap.set('i', '<C-l>', function()
        cmp.close()
        neocodeium.cycle_or_complete()
      end)

      long_press_aware_keybinding('i', '<Tab>', {
        tap = function()
          if neocodeium.visible() then
            neocodeium.accept()
          else
            neocodeium.cycle_or_complete()
          end
        end,
        press = function()
          vim.api.nvim_input('<Tab>')
        end,
      }, 500, { noremap = true, silent = true })

      neocodeium.setup({
        manual = true,
      })

      -- create an autocommand which closes cmp when ai completions are displayed
      vim.api.nvim_create_autocmd('User', {
        pattern = 'NeoCodeiumCompletionDisplayed',
        callback = function() cmp.close() end
      })

      -- open codeium chat
      vim.keymap.set('n', '<C-g>c', neocodeium.chat)
      vim.keymap.set('v', '<C-g>c', function()
        vim.cmd('y') -- Yank visually selected text
        neocodeium.chat()
      end)
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

          if name:match('claude|opencode') then
            -- -- Switch to normal mode when pressing Escape in terminal mode
            -- tnoremap('<Esc>', '<C-\\><C-n>', { buffer = buffer })
            --
            -- -- Send Escape when pressing Ctrl-X in terminal mode
            -- tnoremap('<C-x>', '<Esc>', { buffer = buffer })

            -- Map Ctrl+h/j/k/l to navigate between tmux panes
            tnoremap('<C-h>', '<cmd>lua require("tmux").move_left()<cr>', { buffer = buffer })
            tnoremap('<C-j>', '<cmd>lua require("tmux").move_bottom()<cr>', { buffer = buffer })
            tnoremap('<C-k>', '<cmd>lua require("tmux").move_top()<cr>', { buffer = buffer })
            tnoremap('<C-l>', '<cmd>lua require("tmux").move_right()<cr>', { buffer = buffer })
          end
        end
      })
    end,
    keys = {
      { '<leader>a', nil, desc = 'AI/Claude Code' },
      { '<leader>aa', '<cmd>ClaudeCode<cr>', desc = 'claude: toggle' },
      { '<leader>ac', '<cmd>ClaudeCode<cr>', desc = 'claude: toggle' },

      -- Current external terminal setup is causing keybinding issues
      -- { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'claude: focus' },
      -- { '<leader>aR', '<cmd>ClaudeCode --resume<cr>', desc = 'claude: resume' },
      -- { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'claude: continue' },

      { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'claude: select model' },
      { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'claude: add current buffer' },
      { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'claude: send current selection' },
      {
        '<leader>as',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = 'Add file',
        ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles' },
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
    },
  }
}
