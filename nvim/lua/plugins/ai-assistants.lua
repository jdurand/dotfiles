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
    'robitx/gp.nvim',
    config = function()
      require('gp').setup({
        providers = {
          openai = {
            endpoint = "https://api.openai.com/v1/chat/completions",
            secret = os.getenv("OPENAI_API_KEY"),
          },
          -- googleai = {
          --   endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{{model}}:streamGenerateContent?key={{secret}}",
          --   secret = os.getenv("GOOGLEAI_API_KEY"),
          -- },
          anthropic = {
            endpoint = "https://api.anthropic.com/v1/messages",
            secret = os.getenv("ANTHROPIC_API_KEY"),
          },
        },
        agents = {
          -- {
          --   provider = 'openai',
          --   name = 'CodeGPT5',
          --   chat = false,
          --   command = true,
          --   model = { model = 'gpt-5', temperature = 1.0 },
          --   system_prompt = require('gp.defaults').code_system_prompt,
          -- },
          {
            provider = 'openai',
            name = 'CodeGPT5-mini',
            chat = false,
            command = true,
            model = { model = 'gpt-5-mini', temperature = 1.0 },
            system_prompt = table.concat({
              "Always remove any trailing spaces or tabs at the ends of lines.",
              "Preserve necessary indentation but ensure no trailing whitespace.",
              require("gp.defaults").code_system_prompt,
            }, "\n"),
          },
          {
            provider = 'openai',
            name = 'CodeGPT5-nano',
            chat = false,
            command = true,
            model = { model = 'gpt-5-nano', temperature = 1.0 },
            system_prompt = table.concat({
              "Always remove any trailing spaces or tabs at the ends of lines.",
              "Preserve necessary indentation but ensure no trailing whitespace.",
              require("gp.defaults").code_system_prompt,
            }, "\n"),
          },
          {
            provider = "anthropic",
            name = "CodeClaude-4-0-Sonnet",
            chat = false,
            command = true,
            -- string with model name or table with model name and parameters
            model = { model = "claude-4-0-sonnet-latest", temperature = 0.8, top_p = 1 },
            system_prompt = require("gp.defaults").code_system_prompt,
          },
          -- {
          --   provider = "anthropic",
          --   name = "CodeClaude-4-1-Opus",
          --   chat = false,
          --   command = true,
          --   -- string with model name or table with model name and parameters
          --   model = { model = "claude-4-1-opus-latest", temperature = 0.8, top_p = 1 },
          --   system_prompt = require("gp.defaults").code_system_prompt,
          -- },
          {
            name = 'CodeGPT4o',
            disable = true,
          },
          {
            name = 'CodeGPT4o-mini',
            disable = true,
          },
          {
            name = 'CodeGPT-o3-mini',
            disable = true,
          },
          {
            name = 'CodeClaude-3-7-Sonnet',
            disable = true,
          },
          {
            name = 'CodeClaude-3-5-Haiku',
            disable = true,
          },
        }
      })

      -- Visual mode mappings
      vim.keymap.set('v', '<leader>ar', ":<C-u>'<,'>GpRewrite<cr>", { desc = 'gp: rewrite selection' })
      vim.keymap.set('v', '<leader>aa', ":<C-u>'<,'>GpAppend<cr>", { desc = 'gp: append after selection' })
      vim.keymap.set('v', '<leader>ab', ":<C-u>'<,'>GpPrepend<cr>", { desc = 'gp: prepend before selection' })
      vim.keymap.set('v', '<leader>ai', ":<C-u>'<,'>GpImplement<cr>", { desc = 'gp: implement from selection' })
      vim.keymap.set('v', '<leader>ax', ":<C-u>'<,'>GpContext<cr>", { desc = 'gp: show context' })
      vim.keymap.set('v', '<leader>ac', '<cmd>GpStop<cr>', { desc = 'gp: stop current process' })
      vim.keymap.set('v', '<leader>an', '<cmd>GpNextAgent<cr>', { desc = 'gp: next AI agent' })

      -- Normal and Insert mode mappings
      vim.keymap.set({ 'n', 'i' }, '<leader>aa', '<cmd>GpAppend<cr>', { desc = 'gp: append after' })
      vim.keymap.set({ 'n', 'i' }, '<leader>an', '<cmd>GpNextAgent<cr>', { desc = 'gp: next AI agent' })
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
      -- Get the native terminal provider and extend it
      local provider = require('claudecode.terminal.native')

      ---@diagnostic disable: missing-fields
      require('claudecode').setup({
        -- prevents opening a new pane in the terminal if a Claude instance is already connected (e.g., from an external terminal)
        terminal = {
          provider = setmetatable({
            ensure_visible = function()
              local active_bufnr = provider.get_active_bufnr()

              if active_bufnr and vim.api.nvim_buf_is_valid(active_bufnr) then
                -- Check if buffer is visible in any window
                local windows = vim.api.nvim_list_wins()

                for _, win in ipairs(windows) do
                  if vim.api.nvim_win_get_buf(win) == active_bufnr then
                    -- Already visible
                    return
                  end
                end

                -- Buffer exists but not visible, open it without focus
                provider.open('claude',
                  { ENABLE_IDE_INTEGRATION = 'true' },
                  { split_side = 'right', split_width_percentage = 0.30 },
                  false
                )
              else
                -- No active buffer
                -- Prevent opening a new window, as the default behavior does
              end
            end,
          }, {
            -- Delegate all other methods to native provider
            __index = provider
          }),
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
      { '<leader>ac', '<cmd>ClaudeCode<cr>', desc = 'claude: toggle' },
      { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'claude: focus' },
      { '<leader>aR', '<cmd>ClaudeCode --resume<cr>', desc = 'claude: resume' },
      { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'claude: continue' },
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
    },
  }
}
