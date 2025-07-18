local function truncate_branch_name(branch)
  if not branch or branch == "" then
    return ''
  end

  -- Match the branch name to the specified format
  local _, _, tracker, ticket = string.find(branch, "(.+)/(%D+%-%d+)%-")

  -- If the branch name matches the format, display {tracker}/{project}-{ticket_number}, otherwise display the full branch name
  if ticket then
    return string.lower(tracker) .. ': ' ..string.upper(ticket)
  else
    return branch
  end
end

local function harpoon_component()
  local harpoon = require('harpoon')

  local mark_count = harpoon:list():length()
  local mark_list = harpoon:list().items

  if mark_count == 0 then
    return ''
  end

  local current_mark = "—"
  local current_buffer = vim.api.nvim_get_current_buf()

  local mark_index = nil

  for i, item in ipairs(mark_list) do
    local bufnr = vim.fn.bufnr(item.value, true)

    if bufnr == current_buffer then
      mark_index = i
      break
    end
  end

  if mark_index ~= nil then
    current_mark = tostring(mark_index)
  end

  return string.format("󱡅 %s/%d", current_mark, mark_count)
end

local function macro_recording()
  local reg = vim.fn.reg_recording()
  if reg == "" then return "" end -- not recording
  return " @" .. reg
end

local function neotest_status()
  local neotest = require("neotest")
  local file_path = vim.fn.expand("%:p") -- Current file path
  local buf = vim.api.nvim_get_current_buf()

  -- Retrieve adapter IDs
  local adapters = neotest.state.adapter_ids()
  if not adapters or #adapters == 0 then
    return "" -- No adapters available
  end

  -- Assume the first adapter (for simplicity)
  local adapter_id = adapters[1]

  -- Check test status counts for the current buffer
  local status_counts = neotest.state.status_counts(adapter_id, { buffer = buf })
  if status_counts then
    if status_counts.failed and status_counts.failed > 0 then
      return "%#NeotestFailed# Failed"
    end
    if status_counts.running and status_counts.running > 0 then
      return "%#NeotestRunning# Running"
    end
  end

  -- Check if the whole file is being watched
  if neotest.watch.is_watching(file_path) then
    return "%#NeotestWatching# Watching"
  end

  -- Check for line-level test watching
  local cursor_line = vim.fn.line(".") - 1 -- Adjust for zero-indexed line numbers
  local positions = neotest.state.positions(adapter_id, { buffer = buf })
  if positions then
    local nearest_test = neotest.lib.positions.nearest(positions, cursor_line)
    if nearest_test and neotest.watch.is_watching(nearest_test.id) then
      return "%#NeotestWatching# Watching (L" .. cursor_line + 1 .. ")"
    end
  end

  return "" -- Default when no special state
end

return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = {
      'stevearc/overseer.nvim'
    },
    config = function()
      local overseer = require('overseer')
      local neon_theme = require('user/themes/lualine/electric-neon')

      vim.api.nvim_set_hl(0, "NeotestWatching", { fg = "#CC8400", bg = neon_theme.normal.b.bg }) -- Orange for watching
      vim.api.nvim_set_hl(0, "NeotestFailed", { fg = "#B22222", bg = neon_theme.normal.b.bg })   -- Red for failed
      vim.api.nvim_set_hl(0, "NeotestRunning", { fg = "#7A8C9A", bg = neon_theme.normal.b.bg })  -- Gray for running

      local trouble = require('trouble').statusline({
        mode = 'lsp_document_symbols',
        groups = {},
        title = false,
        filter = { range = true },
        format = '{kind_icon}{symbol.name:Normal}',
        -- The following line is needed to fix the background color
        -- Set it to the lualine section you want to use
        hl_group = 'lualine_c_normal',
      })

      require('lualine').setup({
        options = {
          -- theme = 'auto',
          -- theme = 'molokai',
          -- theme = 'onedark',
          theme = neon_theme,

          -- component_separators = { left = "█", right = "█" },
          -- component_separators = { left = "", right = "" },
          component_separators = '',
          -- section_separators = { left = "█", right = "█" },
          section_separators = { left = "", right = "" },

          -- section_separators = { left = '', right = '' },
          -- disabled_filetypes = {
          -- },
          ignore_focus = {
            'dapui_watches', 'dapui_breakpoints', 'dapui_scopes',
            'dapui_console', 'dapui_stacks', 'dap-repl'
          },
        },
        sections = {
          -- lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
          lualine_b = {
            { 'branch', icon = "", fmt = truncate_branch_name },
            'diff',
            harpoon_component,
          },
          -- lualine_c = {
          --   'diagnostics',
          --   { 'filename', path = 1 },
          -- },
          lualine_c = {
            {
              trouble.get,
              cond = trouble.has,
            },
          },
          lualine_x = {
            {
              'overseer',
              label = '', -- Prefix for task counts
              colored = true, -- Color the task icons and counts
              symbols = {
                [overseer.STATUS.FAILURE] = 'F:',
                [overseer.STATUS.CANCELED] = 'C:',
                [overseer.STATUS.SUCCESS] = 'S:',
                [overseer.STATUS.RUNNING] = 'R:',
              },
              unique = false, -- Unique-ify non-running task count by name
              name = nil, -- List of task names to search for
              name_not = false, -- When true, invert the name search
              status = nil, -- List of task statuses to display
              status_not = false, -- When true, invert the status search
            },
          },
          lualine_y = {
            macro_recording,
            neotest_status,
            'filetype',
            'encoding',
            -- 'fileformat',
            'progress'
          },
          -- lualine_z = { { 'location', separator = { right = '' }, left_padding = 2 } },
        },
      })
    end,
  },
}
