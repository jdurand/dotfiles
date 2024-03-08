local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim'
    },
    config = function()
      local harpoon = require('harpoon')

      harpoon:setup({})

      -- require('telescope').load_extension('harpoon')

      -- nnoremap('<leader>hh', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'List [H]arpoon Marks' })
      nnoremap('<leader>hh', function()
        require('telescope').extensions.harpoon.marks({
          prompt_title = 'Harpoon Marks'
        })
        vim.api.nvim_input('<ESC>')
      end, { desc = 'List [H]arpoon Marks' })

      nnoremap('<leader>ha', function() harpoon:list():append() end, { desc = '[A]dd to Harpoon Marks' })
      -- nnoremap('<leader>hd', function() harpoon:list():remove() end, { desc = '[D]iscard from Harpoon Marks' })

      nnoremap('<leader>h1', function() harpoon:list():select(1) end, { desc = 'Goto Harpoon Mark [1]' })
      nnoremap('<leader>h2', function() harpoon:list():select(2) end, { desc = 'Goto Harpoon Mark [2]' })
      nnoremap('<leader>h3', function() harpoon:list():select(3) end, { desc = 'Goto Harpoon Mark [3]' })
      nnoremap('<leader>h4', function() harpoon:list():select(4) end, { desc = 'Goto Harpoon Mark [4]' })

      -- Toggle previous & next buffers stored within Harpoon list
      nnoremap('>>', function() harpoon:list():next() end, { desc = 'Goto [N]ext Mark' })
      nnoremap('<<', function() harpoon:list():prev() end, { desc = 'Goto [P]revious Mark' })
    end
  },
}
