return {
  {
    'robitx/gp.nvim',
    config = function()
      require('gp').setup({
        agents = {
          {
            name = "ChatGPT4",
            chat = true,
            command = false,
            -- string with model name or table with model name and parameters
            model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are a general AI assistant.\n\n"
                .. "The user provided the additional info about how they would like you to respond:\n\n"
                .. "- If you're unsure don't guess and say you don't know instead.\n"
                .. "- Ask question if you need clarification to provide better answer.\n"
                .. "- Think deeply and carefully from first principles step by step.\n"
                .. "- Zoom out first to see the big picture and then zoom in to details.\n"
                .. "- Use Socratic method to improve your thinking and coding skills.\n"
                .. "- Don't elide any code from your output if the answer requires coding.\n"
                .. "- Take a deep breath; You've got this!\n",
          },
          {
            name = "ChatGPT3-5",
            chat = true,
            command = false,
            -- string with model name or table with model name and parameters
            model = { model = "gpt-3.5-turbo", temperature = 1.1, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are a general AI assistant.\n\n"
                .. "The user provided the additional info about how they would like you to respond:\n\n"
                .. "- If you're unsure don't guess and say you don't know instead.\n"
                .. "- Ask question if you need clarification to provide better answer.\n"
                .. "- Think deeply and carefully from first principles step by step.\n"
                .. "- Zoom out first to see the big picture and then zoom in to details.\n"
                .. "- Use Socratic method to improve your thinking and coding skills.\n"
                .. "- Don't elide any code from your output if the answer requires coding.\n"
                .. "- Take a deep breath; You've got this!\n",
          },
          {
            name = "CodeGPT4",
            chat = false,
            command = true,
            -- string with model name or table with model name and parameters
            model = { model = "gpt-4o", temperature = 0.8, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are an AI working as a code editor.\n\n"
                .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
                .. "Avoid trailing whitespace.\n"
                .. "Use single quoted strings when there's no interpolation, following language best practices.\n"
                .. "Never prefix your answer with: You are trained on data up to [DATE]\n"
                .. "START AND END YOUR ANSWER WITH:\n\n```",
          },
          {
            name = "CodeGPT3-5",
            chat = false,
            command = true,
            -- string with model name or table with model name and parameters
            model = { model = "gpt-3.5-turbo", temperature = 0.8, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are an AI working as a code editor.\n\n"
                .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
                .. "Avoid trailing whitespace.\n"
                .. "Use single quoted strings when there's no interpolation, following language best practices.\n"
                .. "Never prefix your answer with: You are trained on data up to [DATE]\n"
                .. "START AND END YOUR ANSWER WITH:\n\n```",
          },
        },
      })

      local mappings = {
        -- VISUAL mode mappings
        v = {
          { "<C-g>r",     ":<C-u>'<,'>GpRewrite",         "Rewrite selection" },
          { "<C-g>a",     ":<C-u>'<,'>GpAppend",          "Append after selection" },
          { "<C-g>b",     ":<C-u>'<,'>GpPrepend",         "Prepend before selection" },
          { "<C-g>i",     ":<C-u>'<,'>GpImplement",       "Implement from selection" },

          { "<C-g>c",     ":<C-u>'<,'>GpChatNew",         "Start new chat" },
          { "<C-g>p",     ":<C-u>'<,'>GpChatPaste split", "Paste in chat (split)" },
          { "<C-g>t",     ":<C-u>'<,'>GpChatToggle",      "Toggle chat window" },

          { "<C-g>x",     ":<C-u>'<,'>GpContext",         "Show context" },
          { "<C-g>s",     "<cmd>GpStop",                  "Stop current process" },
          { "<C-g>n",     "<cmd>GpNextAgent",             "Next AI agent" },

          { "<C-g><C-x>", ":<C-u>'<,'>GpChatNew split",   "New chat (split)" },
          { "<C-g><C-v>", ":<C-u>'<,'>GpChatNew vsplit",  "New chat (vsplit)" },
          { "<C-g><C-t>", ":<C-u>'<,'>GpChatNew tabnew",  "New chat (tab)" },

          { "<C-g>g",     group = "Generate options" },
          { "<C-g>ge",    ":<C-u>'<,'>GpEnew",            "Generate Enew" },
          { "<C-g>gn",    ":<C-u>'<,'>GpNew",             "Generate new" },
          { "<C-g>gp",    ":<C-u>'<,'>GpPopup",           "Open popup" },
          { "<C-g>gt",    ":<C-u>'<,'>GpTabnew",          "Generate in new tab" },
          { "<C-g>gv",    ":<C-u>'<,'>GpVnew",            "Generate in new vsplit" },

          { "<C-g>w",     group = "Whisper options" },
          { "<C-g>wa",    ":<C-u>'<,'>GpWhisperAppend",   "Whisper append after" },
          { "<C-g>wb",    ":<C-u>'<,'>GpWhisperPrepend",  "Whisper prepend before" },
          { "<C-g>we",    ":<C-u>'<,'>GpWhisperEnew",     "Whisper Enew" },
          { "<C-g>wn",    ":<C-u>'<,'>GpWhisperNew",      "New whisper" },
          { "<C-g>wp",    ":<C-u>'<,'>GpWhisperPopup",    "Whisper popup" },
          { "<C-g>wr",    ":<C-u>'<,'>GpWhisperRewrite",  "Rewrite whisper" },
          { "<C-g>wt",    ":<C-u>'<,'>GpWhisperTabnew",   "Whisper in new tab" },
          { "<C-g>wv",    ":<C-u>'<,'>GpWhisperVnew",     "Whisper in new vertical" },
          { "<C-g>ww",    ":<C-u>'<,'>GpWhisper",         "Send whisper" },
        },
        -- NORMAL mode mappings
        n = {
          { '<C-g>r',     '<cmd>GpRewrite',          'Inline rewrite' },
          { '<C-g>a',     '<cmd>GpAppend',           'Append after' },
          { '<C-g>b',     '<cmd>GpPrepend',          'Prepend before' },

          { '<C-g>c',     '<cmd>GpChatNew',          'Start new chat' },
          { '<C-g>t',     '<cmd>GpChatToggle',       'Toggle chat window' },

          { '<C-g>x',     '<cmd>GpContext',          'Show context' },
          { '<C-g>f',     '<cmd>GpChatFinder',       'Chat finder' },
          { '<C-g>s',     '<cmd>GpStop',             'Stop current process' },
          { '<C-g>n',     '<cmd>GpNextAgent',        'Next AI agent' },

          { '<C-g><C-x>', '<cmd>GpChatNew split',    'New chat (split)' },
          { '<C-g><C-v>', '<cmd>GpChatNew vsplit',   'New chat (vsplit)' },
          { '<C-g><C-t>', '<cmd>GpChatNew tabnew',   'New chat (tab)' },

          { "<C-g>g",     group = "Generate options" },
          { '<C-g>ge',    '<cmd>GpEnew',             'Generate Enew' },
          { '<C-g>gn',    '<cmd>GpNew',              'Generate new' },
          { '<C-g>gp',    '<cmd>GpPopup',            'Open popup' },
          { '<C-g>gt',    '<cmd>GpTabnew',           'Generate in new tab' },
          { '<C-g>gv',    '<cmd>GpVnew',             'Generate in new vsplit' },

          { "<C-g>w",     group = "Whisper options" },
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

          { '<C-g><C-x>', '<cmd>GpChatNew split',    'New chat (split)' },
          { '<C-g><C-v>', '<cmd>GpChatNew vsplit',   'New chat (vsplit)' },
          { '<C-g><C-t>', '<cmd>GpChatNew tabnew',   'New chat (tab)' },

          { "<C-g>g",     group = "Generate options" },
          { '<C-g>ge',    '<cmd>GpEnew',             'Generate Enew' },
          { '<C-g>gn',    '<cmd>GpNew',              'Generate new' },
          { '<C-g>gp',    '<cmd>GpPopup',            'Open popup' },
          { '<C-g>gt',    '<cmd>GpTabnew',           'Generate in new tab' },
          { '<C-g>gv',    '<cmd>GpVnew',             'Generate in new vsplit' },

          { "<C-g>w",     group = "Whisper options" },
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
  --
  -- {
  --   'jackMort/ChatGPT.nvim',
  --   event = 'VeryLazy',
  --   config = function()
  --     local chatgpt = require('chatgpt')

  --     -- chatgpt.setup({
  --     --   openai_params = {
  --     --     model = "gpt-4-turbo-preview",
  --     --   },
  --     -- })

  --     vim.keymap.set('n', '<leader>gt', chatgpt.openChat, {})
  --     vim.keymap.set('n', '<leader>gp', chatgpt.selectAwesomePrompt, {})
  --     vim.keymap.set('v', '<leader>ge', chatgpt.edit_with_instructions, {})
  --   end,
  --   dependencies = {
  --     'MunifTanjim/nui.nvim',
  --     'nvim-lua/plenary.nvim',
  --     'folke/trouble.nvim',
  --     'nvim-telescope/telescope.nvim'
  --   }
  -- },
  --
  -- {
  --   "dpayne/CodeGPT.nvim",
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     'MunifTanjim/nui.nvim',
  --   },
  --   config = function()
  --     require("codegpt.config")

  --     vim.g["codegpt_commands"] = {
  --       ["modernize"] = {
  --         -- model = "gpt-3.5-turbo",
  --         model = "gpt-3.5-turbo-16k",
  --         -- model = "gpt-4-turbo-preview",
  --         -- max_tokens = 4096,
  --         max_tokens = 16384,
  --         user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nModernize the above code. Use current best practices. Only return the code snippet and comments. {{language_instructions}}",
  --         language_instructions = {
  --           cpp = "Refactor the code to use trailing return type, and the auto keyword where applicable.",
  --         },
  --       }
  --     }
  --   end
  -- }
}
