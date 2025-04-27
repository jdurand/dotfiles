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

    -- Fill ignored files
    for _, path in ipairs(result) do
      local abs = vim.fn.fnamemodify(path, ':p')
      ignored_files[abs] = true

      -- Mark parent directories as potentially fully ignored
      local parent = vim.fn.fnamemodify(abs, ':h')
      while parent and parent ~= '/' do
        parent = parent:gsub('/*$', '') -- normalize to no trailing slash
        potential_dirs[parent] = true
        parent = vim.fn.fnamemodify(parent, ':h')
      end
    end

    -- A folder is only ignored if **all** its contents are ignored
    local ignored_dirs = {}

    for dir, _ in pairs(potential_dirs) do
      dir = dir:gsub('/*$', '') -- normalize to no trailing slash
      local fs = vim.loop.fs_scandir(dir)
      if fs then
        local all_ignored = true
        while true do
          local name, type = vim.loop.fs_scandir_next(fs)
          if not name then break end

          local full_path = vim.fn.fnamemodify(dir .. '/' .. name, ':p')
          full_path = full_path:gsub('/*$', '') -- normalize to no trailing slash

          if not vim.startswith(name, '.') and type == 'file' and not ignored_files[full_path] then
            all_ignored = false
            break
          elseif type == 'directory' then
            if not potential_dirs[full_path] then
              all_ignored = false
              break
            end
          end
        end

        if all_ignored then
          ignored_dirs[dir] = true
        end
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

return {
  on_files_buffer_create = on_buffer_create
}
