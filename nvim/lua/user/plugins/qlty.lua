-- Minimal Qlty integration for Neovim
-- Shows Qlty CLI output in the quickfix list

local M = {}

-- Runs `qlty analyze` in the current project and loads results into quickfix
function M.run_qlty()
  local Job = require('plenary.job')

  Job:new({
    command = 'qlty',
    args = { 'check' },
    cwd = vim.fn.getcwd(),
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        vim.schedule(function()
          vim.notify('Qlty analysis failed', vim.log.levels.ERROR)
        end)
        return
      end

      local results = {}
      for _, line in ipairs(j:result()) do
        -- Qlty outputs: path/to/file.rb:10: Error message
        local file, lnum, text = line:match('([^:]+):(%d+):%s+(.*)')
        if file and lnum and text then
          table.insert(results, {
            filename = file,
            lnum = tonumber(lnum),
            col = 1,
            text = text,
          })
        end
      end

      vim.schedule(function()
        vim.fn.setqflist({}, ' ', { title = 'Qlty', items = results })
        vim.cmd('copen')
      end)
    end,
  }):start()
end

-- Map command
vim.api.nvim_create_user_command('QltyCheck', M.run_qlty, {})

return M
