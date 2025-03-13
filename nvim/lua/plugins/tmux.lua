local nnoremap = require('user.keymaps.bind').nnoremap

return {
  {
    'aserowy/tmux.nvim',
    config = function()
      require('tmux').setup({
        navigation = {
          -- cycles to opposite pane while navigating into the border
          cycle_navigation = true,
          -- enables default keybindings (C-hjkl) for normal mode
          enable_default_keybindings = true,
          -- prevents unzoom tmux when navigating beyond vim border
          persist_zoom = true,
        },
        resize = {
          -- enables default keybindings (A-hjkl) for normal mode
          enable_default_keybindings = true,
          -- sets resize steps for x axis
          resize_step_x = 5,
          -- sets resize steps for y axis
          resize_step_y = 2,
        },
        swap = {
          -- cycles to opposite pane while navigating into the border
          cycle_navigation = false,
          -- enables default keybindings (C-A-hjkl) for normal mode
          enable_default_keybindings = true,
        }
      })

      -- nnoremap('<M-h>', "<cmd>lua require('tmux').resize_left(5)<cr>")
      -- nnoremap('<M-k>', "<cmd>lua require('tmux').resize_top(2)<cr>")
      -- nnoremap('<M-j>', "<cmd>lua require('tmux').resize_bottom(2)<cr>")
      -- nnoremap('<M-l>', "<cmd>lua require('tmux').resize_right(5)<cr>")

      nnoremap('<C-\\>', "<cmd>lua require('tmux').move_left()<cr>")
    end
  }
}
