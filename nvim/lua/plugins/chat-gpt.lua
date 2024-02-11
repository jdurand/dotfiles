return {
  {
    'jackMort/ChatGPT.nvim',
    event = 'VeryLazy',
    config = function()
      local chatgpt = require('chatgpt')

      chatgpt.setup()

      vim.keymap.set('n', '<leader>gt', chatgpt.openChat, {})
      vim.keymap.set('n', '<leader>gp', chatgpt.selectAwesomePrompt, {})
      vim.keymap.set('n', '<leader>ge', chatgpt.edit_with_instructions, {})
    end,
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'folke/trouble.nvim',
      'nvim-telescope/telescope.nvim'
    }
  },
  {
    "dpayne/CodeGPT.nvim",
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    config = function()
      require("codegpt.config")

      vim.g["codegpt_commands"] = {
        ["modernize"] = {
          -- model = "gpt-3.5-turbo",
          model = "gpt-3.5-turbo-16k",
          -- model = "gpt-4-turbo-preview",
          -- max_tokens = 4096,
          max_tokens = 16384,
          user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nModernize the above code. Use current best practices. Only return the code snippet and comments. {{language_instructions}}",
          language_instructions = {
            cpp = "Refactor the code to use trailing return type, and the auto keyword where applicable.",
          },
        }
      }
    end
  }
}
