local neon_theme = require('user/themes/lualine/electric-neon')

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

local function macro_recording ()
  local reg = vim.fn.reg_recording()
  if reg == "" then return "" end -- not recording
  return " @" .. reg
end

return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    config = function()
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
        },
        sections = {
          -- lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
          lualine_b = {
            { 'branch', icon = "", fmt = truncate_branch_name },
            'diff',
            harpoon_component,
            macro_recording,
            'diagnostics',
          },
          lualine_c = {
            { 'filename', path = 1 },
          },
          lualine_x = {},
          lualine_y = { 'filetype', 'progress' },
          -- lualine_z = { { 'location', separator = { right = '' }, left_padding = 2 } },
        },
      })
    end,
  },
}
