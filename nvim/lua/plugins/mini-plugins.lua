return {
  { 'echasnovski/mini.ai', config = function() require('mini.ai').setup() end },
  { 'echasnovski/mini.surround', config = function() require('mini.surround').setup() end },
  { 'echasnovski/mini.operators', config = function() require('mini.operators').setup() end },
  { 'echasnovski/mini.pairs', config = function() require('mini.pairs').setup() end },
  { 'echasnovski/mini.bracketed', config = function() require('mini.bracketed').setup() end },
  { 'echasnovski/mini.icons' },
  {
    'echasnovski/mini.move',
    version = '*',
    config = function()
      require('mini.move').setup({
        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
          -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
          left = '<M-h>',
          right = '<M-l>',
          down = '<M-j>',
          up = '<M-k>',

          -- Disable current line moving in Normal mode
          line_left = '',
          line_right = '',
          line_down = '',
          line_up = '',
        },

        -- Options which control moving behavior
        options = {
          -- Automatically reindent selection during linewise vertical move
          reindent_linewise = true,
        },
      })
    end
  },
}
