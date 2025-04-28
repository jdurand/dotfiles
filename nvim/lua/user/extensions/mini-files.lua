local nmap = require('user.keymaps.bind').nmap

local show_hidden = false
local ignored_cache = {}

-- Asynchronously reload .gitignored files and directories
local function load_git_ignored_cache(callback)
  local handle
  local stdout = vim.loop.new_pipe(false)
  local result = {}
  local ignored_files = {}
  local potential_dirs = {}

  handle = vim.loop.spawn('git', {
    args = { 'ls-files', '--others', '--ignored', '--exclude-standard' },
    stdio = { nil, stdout, nil },
    cwd = vim.fn.getcwd(),
  }, function()
    stdout:close()
    handle:close()

    -- Normalize and collect ignored files
    for _, path in ipairs(result) do
      local abs = vim.fn.fnamemodify(path, ':p'):gsub('/*$', '')
      ignored_files[abs] = true

      local parent = vim.fn.fnamemodify(abs, ':h')
      while parent and parent ~= '/' do
        parent = parent:gsub('/*$', '')
        potential_dirs[parent] = true
        parent = vim.fn.fnamemodify(parent, ':h')
      end
    end

    local ignored_dirs = {}
    local memo = {}

    local function is_dir_fully_ignored(dir)
      dir = dir:gsub('/*$', '')
      if memo[dir] ~= nil then return memo[dir] end

      local fs = vim.loop.fs_scandir(dir)
      if not fs then
        memo[dir] = true
        return true
      end

      local all_ignored = true
      while true do
        local name, type = vim.loop.fs_scandir_next(fs)
        if not name then break end

        local full_path = vim.fn.fnamemodify(dir .. '/' .. name, ':p'):gsub('/*$', '')

        if not vim.startswith(name, '.') then
          if type == 'file' then
            if not ignored_files[full_path] then
              all_ignored = false
              break
            end
          elseif type == 'directory' then
            if not is_dir_fully_ignored(full_path) then
              all_ignored = false
              break
            end
          end
        end
      end

      memo[dir] = all_ignored
      return all_ignored
    end

    -- Evaluate all potential directories
    for dir, _ in pairs(potential_dirs) do
      if is_dir_fully_ignored(dir) then
        ignored_dirs[dir] = true
      end
    end

    if callback then
      vim.schedule(function()
        callback({
          files = ignored_files,
          dirs = ignored_dirs,
        })
      end)
    end
  end)

  stdout:read_start(function(err, data)
    assert(not err, err)
    if data then
      for line in data:gmatch('[^\r\n]+') do
        table.insert(result, line)
      end
    end
  end)
end

-- Filter function used by mini.files
local function filter_hidden_files(entry, ignored)
  local abs_path = vim.fn.fnamemodify(entry.path, ':p')
  abs_path = abs_path:gsub('/*$', '') -- normalize to no trailing slash

  -- Always hide dotfiles unless explicitly toggled
  if vim.startswith(entry.name, '.') then
    return false
  end

  if entry.fs_type == 'file' and ignored.files then
    return not ignored.files[abs_path]
  end

  if entry.fs_type == 'directory' and ignored.dirs then
    return not ignored.dirs[abs_path]
  end

  return true
end

local function refresh_files()
  vim.defer_fn(function()
    require('mini.files').refresh({
      content = {
        filter = function(entry)
          return show_hidden or filter_hidden_files(entry, ignored_cache)
        end
      }
    })
  end, 10)
end

local function on_buffer_create(args)
  -- keybinding to toggle hidden files
  nmap('H', function()
    show_hidden = not show_hidden
    refresh_files()
  end, { buffer = args.data.buf_id, desc = 'Toggle hidden files in mini.files' })

  refresh_files()

  if not ignored_cache or next(ignored_cache) == nil then
    load_git_ignored_cache(function(ignored)
      ignored_cache = ignored
      refresh_files()
    end)
  end
end

local function content_prefix(fs_entry)
  local icon, hl = require('mini.files').default_prefix(fs_entry)
  local is_hidden = fs_entry.name:match('^%.')
  local abs_path = vim.fn.fnamemodify(fs_entry.path, ':p')
  abs_path = abs_path:gsub('/*$', '') -- normalize to no trailing slash

  -- show hidden and ignored files & directories in dark grey
  -- local dark_grey = 'Comment' -- dark grey
  local dark_grey = 'LineNr' -- darker grey
  --
  if is_hidden then
    hl = dark_grey
  elseif fs_entry.fs_type == 'file' and ignored_cache.files then
    if ignored_cache.files[abs_path] then
      hl = dark_grey
    end
  elseif fs_entry.fs_type == 'directory' and ignored_cache.dirs then
    if ignored_cache.dirs[abs_path] then
      hl = dark_grey
    end
  end

  -- show normal directories with a different icon
  if fs_entry.fs_type == 'directory' then
    if not is_hidden then
      icon = ' '
    end
  end

  return icon, hl
end

return {
  on_files_buffer_create = on_buffer_create,
  files_content_prefix = content_prefix
}
