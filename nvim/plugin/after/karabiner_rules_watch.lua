local cwd = vim.fn.getcwd()
local dotfiles_dir = vim.fn.expand('~/.dotfiles')

if cwd == dotfiles_dir or cwd:find(dotfiles_dir .. '/') == 1 then
  local karabiner_rules_path = dotfiles_dir .. '/karabiner/rules'

  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = karabiner_rules_path .. '/*.json',
    callback = function()
      vim.notify('Rebuilding Karabiner config...', vim.log.levels.INFO, { title = 'Karabiner' })
      vim.fn.jobstart({ 'bash', dotfiles_dir .. '/karabiner/build' }, {
        on_exit = function(_, code)
          if code == 0 then
            vim.notify('✅ Karabiner config rebuilt', vim.log.levels.INFO, { title = 'Karabiner' })
          else
            vim.notify('❌ Karabiner build failed', vim.log.levels.ERROR, { title = 'Karabiner' })
          end
        end,
      })
    end,
  })
end
