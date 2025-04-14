local nnoremap = require('user.keymaps.bind').nnoremap

return {
  { 'echasnovski/mini.ai', config = function() require('mini.ai').setup() end },
  { 'echasnovski/mini.surround', config = function() require('mini.surround').setup() end },
  { 'echasnovski/mini.operators', config = function() require('mini.operators').setup() end },
  { 'echasnovski/mini.pairs', config = function() require('mini.pairs').setup() end },
  { 'echasnovski/mini.bracketed', config = function() require('mini.bracketed').setup() end },
  { 'echasnovski/mini.icons' },
  {
    'echasnovski/mini.files',
    config = function()
      local files = require('mini.files')

      files.setup({
        mappings = {
          close       = 'q',
          go_in       = 'l',
          go_in_plus  = '<CR>',
          go_out      = 'H',
          go_out_plus = 'h',
          mark_goto   = "'",
          mark_set    = 'm',
          reset       = '<BS>',
          reveal_cwd  = '.',
          synchronize = '<C-s>',
          trim_left   = '<',
          trim_right  = '>',
          show_help   = '?',
        },
      })

      -- Open the directory of the current file, or the working directory if the file is absent (e.g., after switching branches).
      nnoremap('<leader><C-f>', function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")

        if vim.fn.filereadable(buf_name) == 1 then
          -- Pass the full file path to highlight the file
          files.open(buf_name, true)
        elseif vim.fn.isdirectory(dir_name) == 1 then
          -- If the directory exists but the file doesn't, open the directory
          files.open(dir_name, true)
        else
          -- If neither exists, fallback to the current working directory
          files.open(vim.uv.cwd(), true)
        end
      end, { desc = 'Open mini.files (directory of current file)' })

      -- Open the current working directory
      nnoremap('<leader><C-d>', function()
        files.open(vim.uv.cwd(), true)
      end, { desc = 'Open mini.files (working directory)' })
    end
  },
}
