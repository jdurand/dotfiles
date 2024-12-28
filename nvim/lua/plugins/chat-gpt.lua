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
          { "<C-g>r", ":<C-u>'<,'>GpRewrite", "Visual Rewrite" },
          { "<C-g>a", ":<C-u>'<,'>GpAppend", "Visual Append (after)" },
          { "<C-g>b", ":<C-u>'<,'>GpPrepend", "Visual Prepend (before)" },
          { "<C-g>i", ":<C-u>'<,'>GpImplement", "Implement selection" },

          { "<C-g>c", ":<C-u>'<,'>GpChatNew", "Visual Chat New" },
          { "<C-g>p", ":<C-u>'<,'>GpChatPaste split", "Visual Chat Paste" },
          { "<C-g>t", ":<C-u>'<,'>GpChatToggle", "Visual Toggle Chat" },

          { "<C-g>s", "<cmd>GpStop", "GpStop" },
          { "<C-g>x", ":<C-u>'<,'>GpContext", "Visual GpContext" },
          { "<C-g>n", "<cmd>GpNextAgent", "Next Agent" },

          { "<C-g><C-x>", ":<C-u>'<,'>GpChatNew split", "Visual Chat New split" },
          { "<C-g><C-v>", ":<C-u>'<,'>GpChatNew vsplit", "Visual Chat New vsplit" },
          { "<C-g><C-t>", ":<C-u>'<,'>GpChatNew tabnew", "Visual Chat New tabnew" },

          { "<C-g>g", group = "Generate into new..." },
          { "<C-g>ge", ":<C-u>'<,'>GpEnew", "Visual GpEnew" },
          { "<C-g>gn", ":<C-u>'<,'>GpNew", "Visual GpNew" },
          { "<C-g>gp", ":<C-u>'<,'>GpPopup", "Visual Popup" },
          { "<C-g>gt", ":<C-u>'<,'>GpTabnew", "Visual GpTabnew" },
          { "<C-g>gv", ":<C-u>'<,'>GpVnew", "Visual GpVnew" },

          { "<C-g>w", group = "Whisper" },
          { "<C-g>wa", ":<C-u>'<,'>GpWhisperAppend", "Whisper Append (after)" },
          { "<C-g>wb", ":<C-u>'<,'>GpWhisperPrepend", "Whisper Prepend (before)" },
          { "<C-g>we", ":<C-u>'<,'>GpWhisperEnew", "Whisper Enew" },
          { "<C-g>wn", ":<C-u>'<,'>GpWhisperNew", "Whisper New" },
          { "<C-g>wp", ":<C-u>'<,'>GpWhisperPopup", "Whisper Popup" },
          { "<C-g>wr", ":<C-u>'<,'>GpWhisperRewrite", "Whisper Rewrite" },
          { "<C-g>wt", ":<C-u>'<,'>GpWhisperTabnew", "Whisper Tabnew" },
          { "<C-g>wv", ":<C-u>'<,'>GpWhisperVnew", "Whisper Vnew" },
          { "<C-g>ww", ":<C-u>'<,'>GpWhisper", "Whisper" },
        },
        -- NORMAL mode mappings
        n = {
          { '<C-g>r', '<cmd>GpRewrite', 'Inline Rewrite' },
          { '<C-g>a', '<cmd>GpAppend', 'Append (after)' },
          { '<C-g>b', '<cmd>GpPrepend', 'Prepend (before)' },

          { '<C-g>c', '<cmd>GpChatNew', 'New Chat' },
          { '<C-g>t', '<cmd>GpChatToggle', 'Toggle Chat' },

          { '<C-g>s', '<cmd>GpStop', 'GpStop' },
          { '<C-g>x', '<cmd>GpContext', 'Toggle GpContext' },
          { '<C-g>n', '<cmd>GpNextAgent', 'Next Agent' },
          { '<C-g>f', '<cmd>GpChatFinder', 'Chat Finder' },

          { '<C-g><C-x>', '<cmd>GpChatNew split', 'New Chat split' },
          { '<C-g><C-v>', '<cmd>GpChatNew vsplit', 'New Chat vsplit' },
          { '<C-g><C-t>', '<cmd>GpChatNew tabnew', 'New Chat tabnew' },

          { "<C-g>g", group = "Generate into new..." },
          { '<C-g>ge', '<cmd>GpEnew', 'GpEnew' },
          { '<C-g>gn', '<cmd>GpNew', 'GpNew' },
          { '<C-g>gp', '<cmd>GpPopup', 'Popup' },
          { '<C-g>gt', '<cmd>GpTabnew', 'GpTabnew' },
          { '<C-g>gv', '<cmd>GpVnew', 'GpVnew' },

          { "<C-g>w", group = "Whisper" },
          { '<C-g>wa', '<cmd>GpWhisperAppend', 'Whisper Append (after)' },
          { '<C-g>wb', '<cmd>GpWhisperPrepend', 'Whisper Prepend (before)' },
          { '<C-g>we', '<cmd>GpWhisperEnew', 'Whisper Enew' },
          { '<C-g>wn', '<cmd>GpWhisperNew', 'Whisper New' },
          { '<C-g>wp', '<cmd>GpWhisperPopup', 'Whisper Popup' },
          { '<C-g>wr', '<cmd>GpWhisperRewrite', 'Whisper Inline Rewrite' },
          { '<C-g>wt', '<cmd>GpWhisperTabnew', 'Whisper Tabnew' },
          { '<C-g>wv', '<cmd>GpWhisperVnew', 'Whisper Vnew' },
          { '<C-g>ww', '<cmd>GpWhisper', 'Whisper' },
        },
        -- INSERT mode mappings
        i = {
          { '<C-g>r', '<cmd>GpRewrite', 'Inline Rewrite' },
          { '<C-g>a', '<cmd>GpAppend', 'Append (after)' },
          { '<C-g>b', '<cmd>GpPrepend', 'Prepend (before)' },

          { '<C-g>s', '<cmd>GpStop', 'GpStop' },
          { '<C-g>x', '<cmd>GpContext', 'Toggle GpContext' },
          { '<C-g>n', '<cmd>GpNextAgent', 'Next Agent' },
          { '<C-g>f', '<cmd>GpChatFinder', 'Chat Finder' },

          { '<C-g><C-x>', '<cmd>GpChatNew split', 'New Chat split' },
          { '<C-g><C-v>', '<cmd>GpChatNew vsplit', 'New Chat vsplit' },
          { '<C-g><C-t>', '<cmd>GpChatNew tabnew', 'New Chat tabnew' },

          { "<C-g>g", group = "Generate into new..." },
          { '<C-g>ge', '<cmd>GpEnew', 'GpEnew' },
          { '<C-g>gn', '<cmd>GpNew', 'GpNew' },
          { '<C-g>gp', '<cmd>GpPopup', 'Popup' },
          { '<C-g>gt', '<cmd>GpTabnew', 'GpTabnew' },
          { '<C-g>gv', '<cmd>GpVnew', 'GpVnew' },

          { "<C-g>w", group = "Whisper" },
          { '<C-g>wa', '<cmd>GpWhisperAppend', 'Whisper Append (after)' },
          { '<C-g>wb', '<cmd>GpWhisperPrepend', 'Whisper Prepend (before)' },
          { '<C-g>we', '<cmd>GpWhisperEnew', 'Whisper Enew' },
          { '<C-g>wn', '<cmd>GpWhisperNew', 'Whisper New' },
          { '<C-g>wp', '<cmd>GpWhisperPopup', 'Whisper Popup' },
          { '<C-g>wr', '<cmd>GpWhisperRewrite', 'Whisper Inline Rewrite' },
          { '<C-g>wt', '<cmd>GpWhisperTabnew', 'Whisper Tabnew' },
          { '<C-g>wv', '<cmd>GpWhisperVnew', 'Whisper Vnew' },
          { '<C-g>ww', '<cmd>GpWhisper', 'Whisper' },
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
