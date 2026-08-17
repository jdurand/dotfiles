return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local dashboard_cache = vim.fn.stdpath('cache') .. '/dashboard/cache'
    if vim.fn.filereadable(dashboard_cache) == 1 then
      local data = table.concat(vim.fn.readfile(dashboard_cache, 'b'), '\n')
      local chunk = loadstring(data, '@' .. dashboard_cache)
      local ok, projects = chunk and pcall(chunk)

      -- dashboard-nvim writes this cache asynchronously on exit. If Neovim is
      -- interrupted before the write is truncated, the trailing bytes make it
      -- invalid Lua and the dashboard fails to open on the next startup.
      if not ok or type(projects) ~= 'table' then
        vim.fn.writefile({ 'return {}' }, dashboard_cache)
      end
    end

    local nvim_version = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
    local update_dotfiles = function()
      local o = require('overseer')
      local task = o.new_task({
        name = 'Update dotfiles',
        cmd = { vim.fn.expand('~/.dotfiles/setup') },
        cwd = vim.fn.expand('~/.dotfiles/'),
        components = {
          -- { 'on_complete_dispose', timeout = 5 },
          'default'
        },
      })
      task:start()
      o.open()
      -- o.run_action(task, 'open float')
    end

    -- overseer.run_template({ name = "make" }, function(task)
    --   if task then
    --     overseer.run_action(task, 'open float')
    --   end
    -- end)

    require('dashboard').setup {
      theme = 'hyper',  -- 'doom', 'hyper', 'classic', etc.
      config = {
        header = {
          "                                      ",
          "               ########               ",
          "         #####################        ",
          "       #########################      ",
          "    ##############################    ",
          "  ############+----------++#########  ",
          " #########+-----------------+#######  ",
          "  ########-------------------#######  ",
          "  #######---------------------######  ",
          "    #####+++--+++----+++++++++####    ",
          "     #++#+-------------------++--#    ",
          "     #--+---++++-------++++-----+     ",
          "     +----------------+--------+#     ",
          "      #+---------------------+##      ",
          "         +------------------+#        ",
          "          #+---------------+          ",
          "            #+----------++#           ",
          "                ##+++#                ",
          "                                      ",
          "Jim’s Neovim v" .. nvim_version .. "  ",
          "                                      ",
        },
        shortcut = {
          { icon = ' ', desc = 'New', key = 'n', action = 'enew' },
          { icon = ' ', desc = 'Files', key = 'f', action = 'Telescope find_files' },
          { icon = '󰦗 ', desc = 'Update', key = 'u', action = update_dotfiles },
          { icon = '󰏗 ', desc = 'dotfiles', key = 'd', action = function() require('user.utils').web_browser({ url = 'https://github.com/jdurand/dotfiles' }) end },
        },
        packages = { enable = true }, -- show how many plugins neovim loaded
        project = { enable = true, limit = 5 },
        mru = { enable = false },
        footer = {
          "                                                   ",
          "The only way to discover the limits of the possible",
          "     is to go beyond them into the impossible.     ",
          "                                                   ",
        }
      }
    }
  end,
}
