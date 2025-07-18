local nmap = require('user.keymaps.bind').nmap

local show_hidden = false
local ignored_cache = {}
local cache_loading = false
local cache_last_updated = 0
local cache_debounce_timer = nil

-- Common dependency patterns to exclude
local DEPENDENCY_PATTERNS = {
  'node_modules',
  'bower_components',
  'vendor',
  '.git',
  '.svn',
  '.hg',
  '.bzr',
  '__pycache__',
  '.pytest_cache',
  '.mypy_cache',
  '.tox',
  '.venv',
  'venv',
  'env',
  'virtualenv',
  '.virtualenv',
  'target', -- Rust/Java
  'build',
  'dist',
  'out',
  '.next',
  '.nuxt',
  '.output',
  'coverage',
  '.nyc_output',
  'tmp',
  'temp',
  '.tmp',
  '.DS_Store',
  'Thumbs.db',
  '.gradle',
  '.idea',
  '.vscode',
  '.metals',
  '.bloop',
  'elm-stuff',
  '.elixir_ls',
  '_build',
  'deps',
  '.mix',
  'pkg',
  'bin',
  'obj',
  '.sass-cache',
  'log',
  'logs',
  '*.log',
  'pids',
  '*.pid',
  '*.seed',
  '*.pid.lock',
  '.lock-wscript',
  'lib-cov',
  'coverage',
  '.grunt',
  '.eslintcache',
  '.cache',
  '.parcel-cache',
  '.webpack'
}

-- Fast pattern matching for dependencies
local function is_dependency_path(path)
  local name = vim.fn.fnamemodify(path, ':t')
  for _, pattern in ipairs(DEPENDENCY_PATTERNS) do
    if name == pattern or name:match(pattern:gsub('%*', '.*')) then
      return true
    end
  end
  return false
end

-- Debounced cache invalidation
local function invalidate_cache_debounced()
  if cache_debounce_timer then
    vim.loop.timer_stop(cache_debounce_timer)
    cache_debounce_timer = nil
  end

  cache_debounce_timer = vim.loop.new_timer()
  cache_debounce_timer:start(500, 0, function()
    vim.schedule(function()
      ignored_cache = {}
      cache_last_updated = 0
      cache_loading = false
      if cache_debounce_timer then
        vim.loop.timer_stop(cache_debounce_timer)
        cache_debounce_timer = nil
      end
    end)
  end)
end

-- Optimized async git ignore scanning
local function load_git_ignored_cache(callback)
  if cache_loading then
    return
  end

  cache_loading = true
  local current_time = vim.loop.now()

  -- Skip if cache is recent (within 5 seconds)
  if current_time - cache_last_updated < 5000 and next(ignored_cache) then
    cache_loading = false
    if callback then
      callback(ignored_cache)
    end
    return
  end

  local handle
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local result = {}
  local ignored_files = {}
  local ignored_dirs = {}

  handle = vim.loop.spawn('git', {
    args = { 'ls-files', '--others', '--ignored', '--exclude-standard', '--directory' },
    stdio = { nil, stdout, stderr },
    cwd = vim.fn.getcwd(),
  }, function(code)
    stdout:close()
    stderr:close()
    handle:close()
    cache_loading = false

    if code ~= 0 then
      -- Not a git repository or git command failed
      if callback then
        vim.schedule(function()
          callback({
            files = {},
            dirs = {},
          })
        end)
      end
      return
    end

    -- Process results in chunks to avoid blocking
    local function process_chunk(start_idx, chunk_size)
      local end_idx = math.min(start_idx + chunk_size - 1, #result)

      for i = start_idx, end_idx do
        local path = result[i]
        if path and path ~= '' then
          local abs = vim.fn.fnamemodify(path, ':p'):gsub('/*$', '')

          -- Check if it's a directory (git ls-files --directory adds trailing slash)
          if path:sub(-1) == '/' then
            ignored_dirs[abs] = true
          else
            ignored_files[abs] = true
          end
        end
      end

      if end_idx < #result then
        -- Process next chunk
        vim.schedule(function()
          process_chunk(end_idx + 1, chunk_size)
        end)
      else
        -- Processing complete
        cache_last_updated = vim.loop.now()
        ignored_cache = {
          files = ignored_files,
          dirs = ignored_dirs,
        }

        if callback then
          vim.schedule(function()
            callback(ignored_cache)
          end)
        end
      end
    end

    if #result > 0 then
      vim.schedule(function()
        process_chunk(1, 100) -- Process in chunks of 100
      end)
    else
      cache_last_updated = vim.loop.now()
      ignored_cache = {
        files = ignored_files,
        dirs = ignored_dirs,
      }

      if callback then
        vim.schedule(function()
          callback(ignored_cache)
        end)
      end
    end
  end)

  stdout:read_start(function(err, data)
    if err then
      cache_loading = false
      return
    end
    if data then
      for line in data:gmatch('[^\r\n]+') do
        if line ~= '' then
          table.insert(result, line)
        end
      end
    end
  end)

  stderr:read_start(function(err, data)
    if err then
      cache_loading = false
    end
    -- Ignore stderr for now
  end)
end

-- Enhanced filter function with dependency exclusion
local function filter_hidden_files(entry, ignored)
  local abs_path = vim.fn.fnamemodify(entry.path, ':p')
  abs_path = abs_path:gsub('/*$', '') -- normalize to no trailing slash

  -- Always hide dotfiles unless explicitly toggled
  if vim.startswith(entry.name, '.') then
    return false
  end

  -- Fast dependency filtering
  if is_dependency_path(abs_path) then
    return false
  end

  -- Git ignore filtering (async loaded)
  if entry.fs_type == 'file' and ignored.files then
    return not ignored.files[abs_path]
  end

  if entry.fs_type == 'directory' and ignored.dirs then
    return not ignored.dirs[abs_path]
  end

  return true
end

-- Optimized refresh with debouncing
local refresh_timer = nil
local function refresh_files()
  if refresh_timer then
    vim.loop.timer_stop(refresh_timer)
    refresh_timer = nil
  end

  refresh_timer = vim.loop.new_timer()
  refresh_timer:start(10, 0, function()
    vim.schedule(function()
      require('mini.files').refresh({
        content = {
          filter = function(entry)
            return show_hidden or filter_hidden_files(entry, ignored_cache)
          end
        }
      })
      if refresh_timer then
        vim.loop.timer_stop(refresh_timer)
        refresh_timer = nil
      end
    end)
  end)
end

-- File system watcher for auto-refresh
local fs_watcher = nil
local function setup_fs_watcher()
  if fs_watcher then
    return
  end

  local cwd = vim.fn.getcwd()
  fs_watcher = vim.loop.new_fs_event()

  fs_watcher:start(cwd, { recursive = false }, function(err, filename, events)
    if err then
      return
    end

    -- Only invalidate cache for relevant changes
    if filename and (filename == '.gitignore' or filename == '.git') then
      vim.schedule(function()
        invalidate_cache_debounced()
      end)
    end
  end)
end

local function cleanup_watchers()
  if fs_watcher then
    fs_watcher:stop()
    fs_watcher = nil
  end
  if refresh_timer then
    vim.loop.timer_stop(refresh_timer)
    refresh_timer = nil
  end
  if cache_debounce_timer then
    vim.loop.timer_stop(cache_debounce_timer)
    cache_debounce_timer = nil
  end
end

local function on_buffer_create(args)
  -- Setup file system watcher
  setup_fs_watcher()

  -- keybinding to toggle hidden files
  nmap('H', function()
    show_hidden = not show_hidden
    refresh_files()
  end, { buffer = args.data.buf_id, desc = 'Toggle hidden files in mini.files' })

  -- keybinding to refresh cache manually
  nmap('R', function()
    invalidate_cache_debounced()
    load_git_ignored_cache(function(ignored)
      ignored_cache = ignored
      refresh_files()
    end)
  end, { buffer = args.data.buf_id, desc = 'Refresh git ignore cache' })

  refresh_files()

  -- Load git ignore cache asynchronously
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
  elseif is_dependency_path(abs_path) then
    hl = 'Comment'
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

-- Auto-cleanup on exit
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = cleanup_watchers,
  desc = 'Cleanup mini.files watchers on exit'
})

return {
  on_files_buffer_create = on_buffer_create,
  files_content_prefix = content_prefix,
  cleanup_watchers = cleanup_watchers
}
