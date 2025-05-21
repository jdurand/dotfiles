
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
      require('gp').setup()

      local mappings = {
        -- VISUAL mode mappings
        v = {
          { '<C-g>r',     ":<C-u>'<,'>GpRewrite",         'Rewrite selection' },
          { '<C-g>a',     ":<C-u>'<,'>GpAppend",          'Append after selection' },
          { '<C-g>b',     ":<C-u>'<,'>GpPrepend",         'Prepend before selection' },
          { '<C-g>i',     ":<C-u>'<,'>GpImplement",       'Implement from selection' },

          -- { '<C-g>c',     ":<C-u>'<,'>GpChatNew",         'Start new chat' },
          -- { '<C-g>p',     ":<C-u>'<,'>GpChatPaste split", 'Paste in chat (split)' },
          -- { '<C-g>t',     ":<C-u>'<,'>GpChatToggle",      'Toggle chat window' },

          { '<C-g>x',     ":<C-u>'<,'>GpContext",         'Show context' },
          { '<C-g>s',     "<cmd>GpStop",                  'Stop current process' },
          { '<C-g>n',     "<cmd>GpNextAgent",             'Next AI agent' },

          -- { '<C-g><C-x>', ":<C-u>'<,'>GpChatNew split",   'New chat (split)' },
          -- { '<C-g><C-v>', ":<C-u>'<,'>GpChatNew vsplit",  'New chat (vsplit)' },
          -- { '<C-g><C-t>', ":<C-u>'<,'>GpChatNew tabnew",  'New chat (tab)' },

          { '<C-g>g',     group = 'Generate options' },
          { '<C-g>ge',    ":<C-u>'<,'>GpEnew",            'Generate Enew' },
          { '<C-g>gn',    ":<C-u>'<,'>GpNew",             'Generate new' },
          { '<C-g>gp',    ":<C-u>'<,'>GpPopup",           'Open popup' },
          { '<C-g>gt',    ":<C-u>'<,'>GpTabnew",          'Generate in new tab' },
          { '<C-g>gv',    ":<C-u>'<,'>GpVnew",            'Generate in new vsplit' },

          { '<C-g>w',     group = 'Whisper options' },
          { '<C-g>wa',    ":<C-u>'<,'>GpWhisperAppend",   'Whisper append after' },
          { '<C-g>wb',    ":<C-u>'<,'>GpWhisperPrepend",  'Whisper prepend before' },
          { '<C-g>we',    ":<C-u>'<,'>GpWhisperEnew",     'Whisper Enew' },
          { '<C-g>wn',    ":<C-u>'<,'>GpWhisperNew",      'New whisper' },
          { '<C-g>wp',    ":<C-u>'<,'>GpWhisperPopup",    'Whisper popup' },
          { '<C-g>wr',    ":<C-u>'<,'>GpWhisperRewrite",  'Rewrite whisper' },
          { '<C-g>wt',    ":<C-u>'<,'>GpWhisperTabnew",   'Whisper in new tab' },
          { '<C-g>wv',    ":<C-u>'<,'>GpWhisperVnew",     'Whisper in new vertical' },
          { '<C-g>ww',    ":<C-u>'<,'>GpWhisper",         'Send whisper' },
        },
        -- NORMAL mode mappings
        n = {
          { '<C-g>r',     '<cmd>GpRewrite',          'Inline rewrite' },
          { '<C-g>a',     '<cmd>GpAppend',           'Append after' },
          { '<C-g>b',     '<cmd>GpPrepend',          'Prepend before' },

          -- { '<C-g>c',     '<cmd>GpChatNew',          'Start new chat' },
          -- { '<C-g>t',     '<cmd>GpChatToggle',       'Toggle chat window' },

          { '<C-g>x',     '<cmd>GpContext',          'Show context' },
          { '<C-g>f',     '<cmd>GpChatFinder',       'Chat finder' },
          { '<C-g>s',     '<cmd>GpStop',             'Stop current process' },
          { '<C-g>n',     '<cmd>GpNextAgent',        'Next AI agent' },

          -- { '<C-g><C-x>', '<cmd>GpChatNew split',    'New chat (split)' },
          -- { '<C-g><C-v>', '<cmd>GpChatNew vsplit',   'New chat (vsplit)' },
          -- { '<C-g><C-t>', '<cmd>GpChatNew tabnew',   'New chat (tab)' },

          { '<C-g>g',     group = 'Generate options' },
          { '<C-g>ge',    '<cmd>GpEnew',             'Generate Enew' },
          { '<C-g>gn',    '<cmd>GpNew',              'Generate new' },
          { '<C-g>gp',    '<cmd>GpPopup',            'Open popup' },
          { '<C-g>gt',    '<cmd>GpTabnew',           'Generate in new tab' },
          { '<C-g>gv',    '<cmd>GpVnew',             'Generate in new vsplit' },

          { '<C-g>w',     group = 'Whisper options' },
          { '<C-g>wa',    '<cmd>GpWhisperAppend',    'Whisper append after' },
          { '<C-g>wb',    '<cmd>GpWhisperPrepend',   'Whisper prepend before' },
          { '<C-g>we',    '<cmd>GpWhisperEnew',      'Whisper Enew' },
          { '<C-g>wn',    '<cmd>GpWhisperNew',       'New whisper' },
          { '<C-g>wp',    '<cmd>GpWhisperPopup',     'Whisper popup' },
          { '<C-g>wr',    '<cmd>GpWhisperRewrite',   'Inline rewrite' },
          { '<C-g>wt',    '<cmd>GpWhisperTabnew',    'Whisper in new tab' },
          { '<C-g>wv',    '<cmd>GpWhisperVnew',      'Whisper in new vertical' },
          { '<C-g>ww',    '<cmd>GpWhisper',          'Send whisper' },
        },
        -- INSERT mode mappings
        i = {
          { '<C-g>r',     '<cmd>GpRewrite',          'Inline rewrite' },
          { '<C-g>a',     '<cmd>GpAppend',           'Append after' },
          { '<C-g>b',     '<cmd>GpPrepend',          'Prepend before' },

          { '<C-g>x',     '<cmd>GpContext',          'Show context' },
          { '<C-g>f',     '<cmd>GpChatFinder',       'Chat finder' },
          { '<C-g>s',     '<cmd>GpStop',             'Stop current process' },
          { '<C-g>n',     '<cmd>GpNextAgent',        'Next AI agent' },

          -- { '<C-g><C-x>', '<cmd>GpChatNew split',    'New chat (split)' },
          -- { '<C-g><C-v>', '<cmd>GpChatNew vsplit',   'New chat (vsplit)' },
          -- { '<C-g><C-t>', '<cmd>GpChatNew tabnew',   'New chat (tab)' },

          { '<C-g>g',     group = 'Generate options' },
          { '<C-g>ge',    '<cmd>GpEnew',             'Generate Enew' },
          { '<C-g>gn',    '<cmd>GpNew',              'Generate new' },
          { '<C-g>gp',    '<cmd>GpPopup',            'Open popup' },
          { '<C-g>gt',    '<cmd>GpTabnew',           'Generate in new tab' },
          { '<C-g>gv',    '<cmd>GpVnew',             'Generate in new vsplit' },

          { '<C-g>w',     group = 'Whisper options' },
          { '<C-g>wa',    '<cmd>GpWhisperAppend',    'Whisper append after' },
          { '<C-g>wb',    '<cmd>GpWhisperPrepend',   'Whisper prepend before' },
          { '<C-g>we',    '<cmd>GpWhisperEnew',      'Whisper Enew' },
          { '<C-g>wn',    '<cmd>GpWhisperNew',       'New whisper' },
          { '<C-g>wp',    '<cmd>GpWhisperPopup',     'Whisper popup' },
          { '<C-g>wr',    '<cmd>GpWhisperRewrite',   'Inline rewrite' },
          { '<C-g>wt',    '<cmd>GpWhisperTabnew',    'Whisper in new tab' },
          { '<C-g>wv',    '<cmd>GpWhisperVnew',      'Whisper in new vertical' },
          { '<C-g>ww',    '<cmd>GpWhisper',          'Send whisper' },
        },
      }

      for mode, map in pairs(mappings) do
        local output_map = { mode = { mode } }

        for _, keymap in ipairs(map) do
          local entry = { keymap[1], nowait = true, remap = false }
          if keymap.group then
            entry.group = keymap.group
          else
            entry[2] = keymap[2] .. '<cr>'
            entry.desc = keymap[3]
          end

          table.insert(output_map, entry)
        end

        require('which-key').add(output_map)
      end
    end,
  },
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    lazy = false,
    version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
    opts = {
      -- add any opts here
      -- for example
      provider = 'openai',
      openai = {
        endpoint = 'https://api.openai.com/v1',
        model = 'gpt-4o', -- your desired model (or use gpt-4o, etc.)
        timeout = 30000, -- timeout in milliseconds
        temperature = 0, -- adjust if needed
        max_tokens = 4096,
        -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
      },
      -- behaviour = {
      --   enable_cursor_planning_mode = true, -- enable cursor planning mode!
      -- },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = 'make',
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      --- The below dependencies are optional,
      'echasnovski/mini.pick', -- for file_selector provider mini.pick
      'nvim-telescope/telescope.nvim', -- for file_selector provider telescope
      'hrsh7th/nvim-cmp', -- autocompletion for avante commands and mentions
      'ibhagwan/fzf-lua', -- for file_selector provider fzf
      'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
      'zbirenbaum/copilot.lua', -- for providers='copilot'
      {
        -- support for image pasting
        'HakonHarnes/img-clip.nvim',
        event = 'VeryLazy',
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { 'markdown', 'Avante' },
        },
        ft = { 'markdown', 'Avante' },
        config = function()
          require('render-markdown').setup({ latex = { enabled = false } })
        end
      },
    },
  },
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
  -- {
  --   'zbirenbaum/copilot.lua',
  --   dependencies = {
  --     'hrsh7th/nvim-cmp',
  --   },
  --   config = function()
  --     local copilot = require('copilot')
  --     local cmp = require('cmp')
  --
  --     copilot.setup({
  --       suggestion = {
  --         enabled = true,
  --         auto_trigger = true,
  --         debounce = 75,
  --         keymap = {
  --           accept = '<C-p>',
  --           accept_word = '<C-f>',
  --           accept_line = '<C-l>',
  --           next = '<C-j>',
  --           prev = '<C-k>',
  --           dismiss = '<C-c>',
  --         },
  --       },
  --       -- suggestion = { enabled = false },
  --       panel = { enabled = false },
  --     })
  --
  --     -- Clear Copilot suggestion when cmp menu opens
  --     cmp.event:on('menu_opened', function()
  --       vim.b.copilot_suggestion_hidden = true
  --     end)
  --     cmp.event:on('menu_closed', function()
  --       vim.b.copilot_suggestion_hidden = false
  --     end)
  --
  --     -- Trigger completion manually (same key as NeoCodeium fallback)
  --     vim.keymap.set('i', '<C-c>', cmp.complete, { desc = 'Trigger nvim-cmp' })
  --   end
  -- },
  -- {
  --   'zbirenbaum/copilot-cmp',
  --   config = function ()
  --     require('copilot_cmp').setup()
  --   end
  -- },
}
