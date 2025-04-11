local M = {}

local function long_press_aware_keybinding(mode, keys, actions, delay, opts)
  local is_key_pressed = false
  local execute;

  local binding = function()
    if not is_key_pressed then
      is_key_pressed = true
      local timer = vim.loop.new_timer()

      timer:start(delay, 0, function()
        if is_key_pressed then
          require('noice').notify(type(actions), 'info')

          if type(actions) == 'table' and type(actions.press) == 'function' then
            execute(actions.press) -- Execute long press action
          elseif type(actions) == 'function' then
            execute(actions)
          end
        end
        timer:stop()
      end)

      vim.defer_fn(function()
        if is_key_pressed then
          if type(actions) == 'table' and type(actions.tap) == 'function' then
            execute(actions.tap) -- Execute tap action
          else
            execute(function()
              vim.api.nvim_input(keys) -- Send keys through
            end)
          end
        end
      end, 50)
    else
      is_key_pressed = false -- Reset flag on key release
    end
  end

  execute = function(fn)
    vim.schedule(function()
      vim.keymap.del(mode, keys, opts)
      is_key_pressed = false

      fn()

      vim.schedule(function()
        vim.keymap.set(mode, keys, binding, opts)
      end)
    end)
  end

  vim.keymap.set(mode, keys, binding, opts)
end

M.long_press_aware_keybinding = long_press_aware_keybinding

-- Example usage
--
-- long_press_aware_keybinding('n', 'x', function() vim.api.nvim_input('X!') end, 500, { noremap = true, silent = true })
--
-- long_press_aware_keybinding('n', 'x', {
--   press = function()
--     vim.api.nvim_input('X!')
--   end,
--   tap = function()
--     vim.api.nvim_input('x')
--   end
-- }, 500, { noremap = true, silent = true })

return M
