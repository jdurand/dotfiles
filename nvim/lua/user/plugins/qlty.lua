local M = {}

function M.run_qlty()
  local overseer = require('overseer')

  for _, task in ipairs(overseer.list_tasks()) do
    if task.name == 'Qlty Check' and not task:is_complete() then
      vim.notify('Qlty Check is already running', vim.log.levels.INFO)
      return
    end
  end

  local qlty_path = vim.fn.exepath('qlty')
  if qlty_path == '' then
    vim.notify('qlty command not found in $PATH', vim.log.levels.ERROR)
    return
  end

  local jq_filter = [[
    .runs[].results[] |
      select(.locations and .locations[0].physicalLocation.region) |
      "\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.startLine):\(.locations[0].physicalLocation.region.startColumn): \(.message.text)"
  ]]

  local cmd = qlty_path
    .. " check --no-progress --no-formatters --no-fix --no-fail --no-error --sarif"
    .. " | jq -r " .. vim.fn.shellescape(jq_filter)
    -- .. " | grep -E '\\.rb:[0-9]+:[0-9]+' "

  local task = overseer.new_task({
    name = 'Qlty Check',
    cmd = cmd,
    components = {
      'default',
      { 'on_output_quickfix', open = true },
      { 'on_exit_set_status', success_codes = { 0 } },
      { 'on_complete_dispose', statuses = { 'SUCCESS' } },
    },
  })

  -- Subscribe to completion to close Overseer if quickfix is open
  task:subscribe('on_complete', function()
    if task.status == 'SUCCESS' then
      overseer.close()
    end
  end)

  task:start()
  overseer.open()
end

vim.api.nvim_create_user_command('QltyCheck', M.run_qlty, {})

return M
