local utils = require("user.utils")
local nnoremap = require("user.keymaps.bind").nnoremap

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local scope = require('telescope.builtin')

      nnoremap('<leader>ff', scope.find_files, { desc = "[F]ind [F]iles" })
      nnoremap('<leader>fg', scope.live_grep, { desc = "[F]ind Live [G]rep" })
      nnoremap('<leader>;', scope.buffers, { desc = "Find Buffers" })
      nnoremap('<leader>fh', scope.help_tags, { desc = "Find [H]elp" })

      nnoremap('<leader>gg', function()
        local cmd = {
          "sort",
          "-u",
          "<(git diff --name-only --cached)",
          "<(git diff --name-only)",
          "<(git diff --name-only --diff-filter=U)",
        }

        if not utils.is_git_directory() then
          vim.notify(
            "Current project is not a git directory",
            vim.log.levels.WARN,
            { title = "Telescope Git Files", git_command = cmd }
          )
        else
          scope.git_files()
        end
      end, { desc = "Find [G]it Files" })
    end,
  }
}
