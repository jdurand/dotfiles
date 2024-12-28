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

      require('which-key').add {
        {
          -- VISUAL mode mappings
          mode = { "v" },

          { "<C-g>r", ":<C-u>'<,'>GpRewrite<cr>", desc = "Visual Rewrite", nowait = true, remap = false },
          { "<C-g>a", ":<C-u>'<,'>GpAppend<cr>", desc = "Visual Append (after)", nowait = true, remap = false },
          { "<C-g>b", ":<C-u>'<,'>GpPrepend<cr>", desc = "Visual Prepend (before)", nowait = true, remap = false },
          { "<C-g>i", ":<C-u>'<,'>GpImplement<cr>", desc = "Implement selection", nowait = true, remap = false },

          { "<C-g>c", ":<C-u>'<,'>GpChatNew<cr>", desc = "Visual Chat New", nowait = true, remap = false },
          { "<C-g>p", ":<C-u>'<,'>GpChatPaste split<cr>", desc = "Visual Chat Paste", nowait = true, remap = false },
          { "<C-g>t", ":<C-u>'<,'>GpChatToggle<cr>", desc = "Visual Toggle Chat", nowait = true, remap = false },

          { "<C-g>s", "<cmd>GpStop<cr>", desc = "GpStop", nowait = true, remap = false },
          { "<C-g>x", ":<C-u>'<,'>GpContext<cr>", desc = "Visual GpContext", nowait = true, remap = false },
          { "<C-g>n", "<cmd>GpNextAgent<cr>", desc = "Next Agent", nowait = true, remap = false },

          { "<C-g><C-x>", ":<C-u>'<,'>GpChatNew split<cr>", desc = "Visual Chat New split", nowait = true, remap = false },
          { "<C-g><C-v>", ":<C-u>'<,'>GpChatNew vsplit<cr>", desc = "Visual Chat New vsplit", nowait = true, remap = false },
          { "<C-g><C-t>", ":<C-u>'<,'>GpChatNew tabnew<cr>", desc = "Visual Chat New tabnew", nowait = true, remap = false },

          { "<C-g>g", group = "generate into new ..", nowait = true, remap = false },
          { "<C-g>ge", ":<C-u>'<,'>GpEnew<cr>", desc = "Visual GpEnew", nowait = true, remap = false },
          { "<C-g>gn", ":<C-u>'<,'>GpNew<cr>", desc = "Visual GpNew", nowait = true, remap = false },
          { "<C-g>gp", ":<C-u>'<,'>GpPopup<cr>", desc = "Visual Popup", nowait = true, remap = false },
          { "<C-g>gt", ":<C-u>'<,'>GpTabnew<cr>", desc = "Visual GpTabnew", nowait = true, remap = false },
          { "<C-g>gv", ":<C-u>'<,'>GpVnew<cr>", desc = "Visual GpVnew", nowait = true, remap = false },

          { "<C-g>w", group = "Whisper", nowait = true, remap = false },
          { "<C-g>wa", ":<C-u>'<,'>GpWhisperAppend<cr>", desc = "Whisper Append (after)", nowait = true, remap = false },
          { "<C-g>wb", ":<C-u>'<,'>GpWhisperPrepend<cr>", desc = "Whisper Prepend (before)", nowait = true, remap = false },
          { "<C-g>we", ":<C-u>'<,'>GpWhisperEnew<cr>", desc = "Whisper Enew", nowait = true, remap = false },
          { "<C-g>wn", ":<C-u>'<,'>GpWhisperNew<cr>", desc = "Whisper New", nowait = true, remap = false },
          { "<C-g>wp", ":<C-u>'<,'>GpWhisperPopup<cr>", desc = "Whisper Popup", nowait = true, remap = false },
          { "<C-g>wr", ":<C-u>'<,'>GpWhisperRewrite<cr>", desc = "Whisper Rewrite", nowait = true, remap = false },
          { "<C-g>wt", ":<C-u>'<,'>GpWhisperTabnew<cr>", desc = "Whisper Tabnew", nowait = true, remap = false },
          { "<C-g>wv", ":<C-u>'<,'>GpWhisperVnew<cr>", desc = "Whisper Vnew", nowait = true, remap = false },
          { "<C-g>ww", ":<C-u>'<,'>GpWhisper<cr>", desc = "Whisper", nowait = true, remap = false },
        },
        {
          -- NORMAL mode mappings
          mode = { 'n' },
          { '<C-g>r', '<cmd>GpRewrite<cr>', desc = 'Inline Rewrite', nowait = true, remap = false },
          { '<C-g>a', '<cmd>GpAppend<cr>', desc = 'Append (after)', nowait = true, remap = false },
          { '<C-g>b', '<cmd>GpPrepend<cr>', desc = 'Prepend (before)', nowait = true, remap = false },

          { '<C-g>c', '<cmd>GpChatNew<cr>', desc = 'New Chat', nowait = true, remap = false },
          { '<C-g>t', '<cmd>GpChatToggle<cr>', desc = 'Toggle Chat', nowait = true, remap = false },

          { '<C-g>s', '<cmd>GpStop<cr>', desc = 'GpStop', nowait = true, remap = false },
          { '<C-g>x', '<cmd>GpContext<cr>', desc = 'Toggle GpContext', nowait = true, remap = false },
          { '<C-g>n', '<cmd>GpNextAgent<cr>', desc = 'Next Agent', nowait = true, remap = false },
          { '<C-g>f', '<cmd>GpChatFinder<cr>', desc = 'Chat Finder', nowait = true, remap = false },

          { '<C-g><C-x>', '<cmd>GpChatNew split<cr>', desc = 'New Chat split', nowait = true, remap = false },
          { '<C-g><C-v>', '<cmd>GpChatNew vsplit<cr>', desc = 'New Chat vsplit', nowait = true, remap = false },
          { '<C-g><C-t>', '<cmd>GpChatNew tabnew<cr>', desc = 'New Chat tabnew', nowait = true, remap = false },

          { '<C-g>g', group = 'generate into new ..', nowait = true, remap = false },
          { '<C-g>ge', '<cmd>GpEnew<cr>', desc = 'GpEnew', nowait = true, remap = false },
          { '<C-g>gn', '<cmd>GpNew<cr>', desc = 'GpNew', nowait = true, remap = false },
          { '<C-g>gp', '<cmd>GpPopup<cr>', desc = 'Popup', nowait = true, remap = false },
          { '<C-g>gt', '<cmd>GpTabnew<cr>', desc = 'GpTabnew', nowait = true, remap = false },
          { '<C-g>gv', '<cmd>GpVnew<cr>', desc = 'GpVnew', nowait = true, remap = false },

          { '<C-g>w', group = 'Whisper', nowait = true, remap = false },
          { '<C-g>wa', '<cmd>GpWhisperAppend<cr>', desc = 'Whisper Append (after)', nowait = true, remap = false },
          { '<C-g>wb', '<cmd>GpWhisperPrepend<cr>', desc = 'Whisper Prepend (before)', nowait = true, remap = false },
          { '<C-g>we', '<cmd>GpWhisperEnew<cr>', desc = 'Whisper Enew', nowait = true, remap = false },
          { '<C-g>wn', '<cmd>GpWhisperNew<cr>', desc = 'Whisper New', nowait = true, remap = false },
          { '<C-g>wp', '<cmd>GpWhisperPopup<cr>', desc = 'Whisper Popup', nowait = true, remap = false },
          { '<C-g>wr', '<cmd>GpWhisperRewrite<cr>', desc = 'Whisper Inline Rewrite', nowait = true, remap = false },
          { '<C-g>wt', '<cmd>GpWhisperTabnew<cr>', desc = 'Whisper Tabnew', nowait = true, remap = false },
          { '<C-g>wv', '<cmd>GpWhisperVnew<cr>', desc = 'Whisper Vnew', nowait = true, remap = false },
          { '<C-g>ww', '<cmd>GpWhisper<cr>', desc = 'Whisper', nowait = true, remap = false },
        },
        {
          -- INSERT mode mappings
          mode = { 'i' },
          { '<C-g>r', '<cmd>GpRewrite<cr>', desc = 'Inline Rewrite', nowait = true, remap = false },
          { '<C-g>a', '<cmd>GpAppend<cr>', desc = 'Append (after)', nowait = true, remap = false },
          { '<C-g>b', '<cmd>GpPrepend<cr>', desc = 'Prepend (before)', nowait = true, remap = false },

          { '<C-g>s', '<cmd>GpStop<cr>', desc = 'GpStop', nowait = true, remap = false },
          { '<C-g>x', '<cmd>GpContext<cr>', desc = 'Toggle GpContext', nowait = true, remap = false },
          { '<C-g>n', '<cmd>GpNextAgent<cr>', desc = 'Next Agent', nowait = true, remap = false },
          { '<C-g>f', '<cmd>GpChatFinder<cr>', desc = 'Chat Finder', nowait = true, remap = false },

          { '<C-g><C-x>', '<cmd>GpChatNew split<cr>', desc = 'New Chat split', nowait = true, remap = false },
          { '<C-g><C-v>', '<cmd>GpChatNew vsplit<cr>', desc = 'New Chat vsplit', nowait = true, remap = false },
          { '<C-g><C-t>', '<cmd>GpChatNew tabnew<cr>', desc = 'New Chat tabnew', nowait = true, remap = false },

          { '<C-g>g', group = 'generate into new ..', nowait = true, remap = false },
          { '<C-g>ge', '<cmd>GpEnew<cr>', desc = 'GpEnew', nowait = true, remap = false },
          { '<C-g>gn', '<cmd>GpNew<cr>', desc = 'GpNew', nowait = true, remap = false },
          { '<C-g>gp', '<cmd>GpPopup<cr>', desc = 'Popup', nowait = true, remap = false },
          { '<C-g>gt', '<cmd>GpTabnew<cr>', desc = 'GpTabnew', nowait = true, remap = false },
          { '<C-g>gv', '<cmd>GpVnew<cr>', desc = 'GpVnew', nowait = true, remap = false },

          { '<C-g>w', group = 'Whisper', nowait = true, remap = false },
          { '<C-g>wa', '<cmd>GpWhisperAppend<cr>', desc = 'Whisper Append (after)', nowait = true, remap = false },
          { '<C-g>wb', '<cmd>GpWhisperPrepend<cr>', desc = 'Whisper Prepend (before)', nowait = true, remap = false },
          { '<C-g>we', '<cmd>GpWhisperEnew<cr>', desc = 'Whisper Enew', nowait = true, remap = false },
          { '<C-g>wn', '<cmd>GpWhisperNew<cr>', desc = 'Whisper New', nowait = true, remap = false },
          { '<C-g>wp', '<cmd>GpWhisperPopup<cr>', desc = 'Whisper Popup', nowait = true, remap = false },
          { '<C-g>wr', '<cmd>GpWhisperRewrite<cr>', desc = 'Whisper Inline Rewrite', nowait = true, remap = false },
          { '<C-g>wt', '<cmd>GpWhisperTabnew<cr>', desc = 'Whisper Tabnew', nowait = true, remap = false },
          { '<C-g>wv', '<cmd>GpWhisperVnew<cr>', desc = 'Whisper Vnew', nowait = true, remap = false },
          { '<C-g>ww', '<cmd>GpWhisper<cr>', desc = 'Whisper', nowait = true, remap = false },
        }
      }
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
