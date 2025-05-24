local M = {}

function M.run_qlty(opts)
  local overseer = require('overseer')
  local scope = opts.args == 'all' and 'all' or 'changed'

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
    .. (scope == 'all' and " --all" or "")
    .. " | jq -r " .. vim.fn.shellescape(jq_filter)

  local output_lines = {}

  local task = overseer.new_task({
    name = 'Qlty Check',
    cmd = cmd,
    components = {
      'default',
      { 'on_exit_set_status', success_codes = { 0 } },
      { 'on_complete_dispose', statuses = { 'SUCCESS' } },
    },
  })

  task:subscribe('on_output', function(_, output)
    for _, line in ipairs(output) do
      if line:match(':') then
        table.insert(output_lines, line)
      end
    end
  end)

  task:subscribe('on_complete', function()
    local pickers = require('telescope.pickers')
    local themes = require('telescope.themes')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    local entries = {}

    for _, line in ipairs(output_lines) do
      local file, lnum, col, msg = line:match('^([^:]+):(%d+):(%d+):%s(.+)$')

      if file and lnum and col and msg then
        table.insert(entries, {
          value = { file = file, lnum = tonumber(lnum), col = tonumber(col) },
          display = string.format('%s:%s:%s: %s', file, lnum, col, msg:gsub('\r$', '')),
          ordinal = file .. msg,
        })
      end
    end

    if #entries > 0 then
      local opts = themes.get_ivy({
        layout_strategy = 'vertical',
        layout_config = {
          prompt_position = 'top',
          height = 0.95,
          width = 0.99,
          preview_height = 0.5,
          mirror = true, -- show preview below
        },
        prompt_title = 'Qlty Check Results',
        results_title = false,
        preview_title = false,
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            return vim.tbl_extend('keep', entry, {
              filename = entry.value.file,
              lnum = entry.value.lnum,
            })
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = conf.qflist_previewer({}),
        attach_mappings = function(prompt_bufnr, _)
          -- Immediately leave insert mode
          vim.schedule(function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
          end)

          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            local picker = action_state.get_current_picker(prompt_bufnr)
            if picker and picker.close then
              picker:close()
            end
            vim.cmd(string.format('edit! +%d %s', entry.value.lnum, entry.value.file))
            vim.api.nvim_win_set_cursor(0, { entry.value.lnum, entry.value.col - 1 })
          end)

          return true
        end,
      })

      pickers.new({}, opts):find()
    else
      vim.notify('Qlty Check passed — no issues found.', vim.log.levels.INFO)
    end

    if task.status == 'SUCCESS' then
      overseer.close()
    end
  end)

  task:start()
  overseer.open()
end

vim.api.nvim_create_user_command('QltyCheck', M.run_qlty, {
  nargs = '?',
  complete = function()
    return { 'changed', 'all' }
  end,
})

return M
