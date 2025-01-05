local M = {}

local function temporarily_override_keybinding(mode, key, action, opts)
  -- Save the current binding
  local current_binding = vim.api.nvim_get_keymap(mode)
  local original_command = nil
  for _, map in ipairs(current_binding) do
    if map.lhs == key then
      original_command = map
      break
    end
  end

  opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})

  -- Set the new keybinding
  vim.keymap.set(mode, key, action, opts)

  -- Function to restore the original binding
  local function restore_original_binding()
    -- Clear the temporary binding
    vim.api.nvim_del_keymap(mode, key)

    -- Restore the original binding if it exists
    if original_command then
      vim.keymap.set(
        mode,
        original_command.lhs,
        original_command.rhs or '',
        { noremap = original_command.noremap, silent = original_command.silent }
      )
    end
  end

  -- Return the restore function to the caller
  return restore_original_binding
end

M.temporarily_override_keybinding = temporarily_override_keybinding

-- -- Example usage
-- local restore = temporarily_override_keybinding('n', 'x', ':echo ''Temporary binding''<CR>')

-- Call this function later to restore the original binding
-- restore()

return M
