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

      -- use telescope as Harpoon mark picker
      local conf = require('telescope.config').values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require('telescope.pickers').new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table({
            results = file_paths,
          }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
        }):find()
      end

      -- nnoremap('<leader>hh', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'List [H]arpoon Marks' })
      nnoremap('<leader>hh', function() toggle_telescope(harpoon:list()) end, { desc = 'List [H]arpoon Marks' })
      nnoremap('<leader>ha', function() harpoon:list():append() end, { desc = '[A]dd to Harpoon Marks' })
      -- nnoremap('<leader>hd', function() harpoon:list():remove() end, { desc = '[D]iscard from Harpoon Marks' })

      nnoremap('<leader>h1', function() harpoon:list():select(1) end, { desc = 'Goto Harpoon Mark [1]' })
      nnoremap('<leader>h2', function() harpoon:list():select(2) end, { desc = 'Goto Harpoon Mark [2]' })
      nnoremap('<leader>h3', function() harpoon:list():select(3) end, { desc = 'Goto Harpoon Mark [3]' })
      nnoremap('<leader>h4', function() harpoon:list():select(4) end, { desc = 'Goto Harpoon Mark [4]' })

      -- Toggle previous & next buffers stored within Harpoon list
      nnoremap('>>', function() harpoon:list():prev() end, { desc = 'Goto [N]ext Mark' })
      nnoremap('<<', function() harpoon:list():next() end, { desc = 'Goto [P]revious Mark' })
    end
  },
}
