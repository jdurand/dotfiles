local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    -- lazy = false,
    branch = 'v3.x',
    keys = {
      { '<leader><C-f>', '<cmd>Neotree toggle<cr>', desc = 'NeoTree' },
    },
    config = function()
      local function open_and_focus_in(state)
        local node = state.tree:get_node()
        if node.type == "directory" then
          require("neo-tree.sources.filesystem.commands").toggle_node(state)
          vim.defer_fn(function()
            require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
          end, 50)
        else
          require('neo-tree.sources.common.commands').open(state)
        end
      end

      require('neo-tree').setup({
        window = {
          mappings = {
            ['<space>'] = {
              'toggle_preview', config = { use_float = true, use_image_nvim = false }
            },
            ['h'] = 'close_node',
            ['l'] = open_and_focus_in,
            ['<C-f>'] = 'close_window',
            ['<C-l>'] = 'focus_preview',
            ['<C-d>'] = { 'scroll_preview', config = { direction = -5 } },
            ['<C-u>'] = { 'scroll_preview', config = { direction = 5 } },
          }
        }
      })
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      '3rd/image.nvim',              -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  },
  {
    '3rd/image.nvim',
    dependencies = { 'luarocks.nvim' },
    opts = {
      rocks = {
        hererocks = true,
        enabled = false
      }
    }
  },
  {
    'vhyrro/luarocks.nvim',
    priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    config = true,
    opts = {
      rocks = { 'magick' },
    },
  },
  {
    'echasnovski/mini.files',
    config = function()
      local files = require('mini.files')
      local ext = require('user.extensions.mini-files')

      files.setup({
        options = {
          use_as_default_explorer = true,
        },
        mappings = {
          close       = 'q',
          go_in       = 'l',
          go_in_plus  = '<CR>',
          -- go_out      = 'H',
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
        content = { prefix = ext.files_content_prefix }
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          ext.on_files_buffer_create(args)

          -- Add project root keymap
          nnoremap('<Esc>', function()
            local root = vim.fn.getcwd()
            files.close()
            files.open(root, true)
          end, { buffer = args.data.buf_id, desc = 'Go to project root' })
        end
      })

      local open_file_explorer = function()
        -- open to the cwd with file preview
        files.open(vim.uv.cwd(), true, {
          windows = {
            preview = true,
            width_preview = 100,
          }
        })
      end

      -- Open the directory of the current file, or the working directory if the file is absent (e.g., after switching branches).
      nnoremap('<C-f>', function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")

        if vim.fn.filereadable(buf_name) == 1 then
          -- Pass the full file path to highlight the file
          files.open(buf_name, true)
        elseif vim.fn.isdirectory(dir_name) == 1 then
          -- If the directory exists but the file doesn't, open the directory
          files.open(dir_name, true)
        else
          -- If neither exists
          -- open file explorer
          -- open_file_explorer()
          --
          -- fallback to Neotree
          files.close()
          require('neo-tree.command').execute({ action = 'focus' })
        end
      end, { desc = 'Open mini.files (directory of current file)' })

      -- Open the current working directory
      nnoremap('<leader><C-d>', open_file_explorer, { desc = 'Open mini.files (working directory)' })
    end
  },
}
