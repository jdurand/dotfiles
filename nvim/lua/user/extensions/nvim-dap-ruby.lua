local M = {}

local function load_module(module_name)
  local ok, module = pcall(require, module_name)
  assert(ok, string.format('Missing DAP dependency: %s', module_name))
  return module
end

local function find_executable_directory(cmd)
  local current_dir = vim.fn.getcwd()
  local original_dir = current_dir

  if vim.fn.executable(cmd) == 1 then
    return current_dir
  end

  while current_dir ~= '' and current_dir ~= '/' do
    if vim.fn.executable(current_dir .. '/' .. cmd) == 1 then
      return current_dir
    end
    current_dir = vim.fn.fnamemodify(current_dir, ':h')
  end

  error(string.format('Executable "%s" not found in %s or its ancestors', cmd, original_dir))
end

local function execute_command(cmd, args, fail_on_error)
  local handle
  local pid_or_err
  local stdout = vim.loop.new_pipe(false)
  local working_dir = find_executable_directory(cmd)

  handle, pid_or_err = vim.loop.spawn(cmd, {
    args = args or {},
    cwd = working_dir,
    stdio = { nil, stdout }
  }, function(code)
    if handle then
      handle:close()
    end
    if fail_on_error and code ~= 0 then
      error(string.format('Command "%s" in "%s" exited with code %d', cmd, working_dir, code))
    end
  end)

  assert(handle, 'Error executing command: ' .. cmd .. tostring(pid_or_err))

  stdout:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      vim.schedule(function()
        require('dap.repl').append(chunk)
      end)
    end
  end)
end

local function base_config(opts)
  return vim.tbl_extend('force', {
    type = 'ruby',
    request = 'attach',
    options = { source_filetype = 'ruby' },
    fail_on_error = true,
    localfs = true
  }, opts or {})
end

local function run_config(opts)
  return base_config(vim.tbl_extend('force', {
    waiting = 1000,
    random_port = true,
    fail_on_error = false
  }, opts or {}))
end

local function rspec_config(opts)
  return run_config(vim.tbl_extend('force', opts or {}, {
    command = 'bundle',
    args = vim.list_extend({ 'exec', 'rspec' }, opts.args or {}),
  }))
end

local function add_dap_configs(configs)
  local dap = require('dap')
  dap.configurations.ruby = vim.list_extend(dap.configurations.ruby or {}, configs)
end

local function prompt_for_port(callback)
  vim.ui.input(
    { prompt = 'Input port to connect to: ' },
    function(input)
      if input and input:match('^%d+$') then
        callback(tonumber(input))
      else
        print('Invalid port selected.')
        callback(nil)
      end
    end
  )
end

local function setup_ruby_adapter(setup_config)
  local dap = load_module('dap')

  setup_config = setup_config or {}

  dap.adapters.ruby = function(callback, config)
    if config.request == 'attach' then
      local waiting = config.waiting or 500
      local server = config.server or vim.env.RUBY_DEBUG_HOST or '127.0.0.1'

      local function start_on_port(port)
        if config.command then
          vim.env.RUBY_DEBUG_OPEN = true
          vim.env.RUBY_DEBUG_HOST = server
          vim.env.RUBY_DEBUG_PORT = port

          execute_command(config.command, config.args, config.fail_on_error)
        end

        vim.defer_fn(function()
          callback({ type = 'server', host = server, port = port })
        end, waiting)
      end

      config.port = config.port or (config.random_port and math.random(setup_config.debug_port_range[1], setup_config.debug_port_range[2]))

      if config.port then
        start_on_port(config.port)
      else
        prompt_for_port(start_on_port)
      end
    else
      callback({
        type = 'executable',
        command = config.command,
        args = { config.program },
        options = { source_filetype = 'ruby' }
      })
    end
  end
end

local function configure_ruby_debugger(opts)
  opts = opts or {}

  local file = vim.fn.expand('%:p')
  local line = string.format('%s:%d', file, vim.fn.line('.'))

  if opts.dap_configs then
    for _, config in ipairs(opts.dap_configs) do
      add_dap_configs({ run_config(config) })
    end
  else
    -- TODO: find a way to generate this list dynamically based on file type and project type (i.e. rails with rspec)
    --       provide default rails/rspec detection with manual override in setup
    add_dap_configs({
      rspec_config({ name = 'RSpec: run nearest test (line)', args = { line } }),
      rspec_config({ name = 'RSpec: run current spec (file)', args = { file } }),
      rspec_config({ name = 'RSpec: run entire suite' }),

      run_config({ name = 'Rails: execute `rails server`', command = 'bundle', args = { 'exec', 'rails', 'server' } }),
      run_config({ name = 'Rails: execute `bin/dev`', command = 'bin/dev' }),

      run_config({ name = 'Ruby: debug current file (rdbg)', command = 'rdbg', args = { file }, fail_on_error = true }),
      base_config({ name = 'Ruby: attach to existing session (port)', waiting = 0 }),
    })
  end
end

function M.setup(opts)
  opts = opts or {}

  setup_ruby_adapter({
    debug_port_range = opts.debug_port_range or { 49152, 65535 }
  })

  configure_ruby_debugger({
    dap_configs = opts.dap_configs
  })
end

function M.add_config(opts)
  add_dap_configs({ run_config(opts) })
end

function M.debug_nearest_test()
  local dap = load_module('dap')
  local line = string.format('%s:%d', vim.fn.expand('%:p'), vim.fn.line('.'))

  local config = rspec_config({
    name = 'RSpec: run nearest test (line)',
    args = { line }
  })

  print(vim.inspect(config))

  vim.notify(string.format('Starting debug session "%s"...', config.name))
  return dap.run(config)
end

function M.debug_current_file()
  local dap = load_module('dap')
  local file = vim.fn.expand('%:p')

  local config = run_config({
    name = 'Ruby: debug current file',
    command = 'rdbg',
    args = { file },
    fail_on_error = true
  })

  vim.notify(string.format('Starting debug session "%s"...', config.name))
  return dap.run(config)
end

function M.debug_test()
  local file_name = vim.fn.expand('%:t')
  local file_type = vim.fn.expand('%:e')

  -- Implement logic to dynamically select the appropriate debugging configuration
  -- based on the type of file being edited (e.g., Ruby script, Rails application).
  if file_type == 'rb' then
    if file_name:match('_spec%.rb$') then
      -- If it's an RSpec spec file, run the nearest test
      M.debug_nearest_test()
    elseif file_name:match('%.rb$') and vim.fn.isdirectory('app') == 1 then
      -- If it's a Ruby file and it exists within a Rails app context
      M.debug_current_file()
    else
      -- For any other ruby file run the entire file
      M.debug_current_file()

      -- TODO: Develop a method to accurately locate the corresponding test
      --       or spec file when working within a Rails project context.
    end
  else
    vim.notify('Unsupported file type for debugging.')
  end
end

return M
