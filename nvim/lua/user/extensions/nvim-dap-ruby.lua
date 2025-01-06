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

local function execute_command(cmd, args, line_context, file_context, fail_on_error)
  local handle
  local pid_or_err
  local stdout = vim.loop.new_pipe(false)
  local working_dir = find_executable_directory(cmd)

  args = args or {}

  if line_context then
    table.insert(args, string.format('%s:%d', vim.fn.expand('%:p'), vim.fn.line('.')))
  elseif file_context then
    table.insert(args, vim.fn.expand('%:p'))
  end

  local opts = { args = args, cwd = working_dir, stdio = { nil, stdout } }

  handle, pid_or_err = vim.loop.spawn(cmd, opts, function(code)
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
  return run_config(vim.tbl_extend('force', {
    command = 'bundle',
    args = { 'exec', 'rspec' }
  }, opts or {}))
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

local function setup_ruby_adapter()
  local dap = load_module('dap')

  dap.adapters.ruby = function(callback, config)
    if config.request == 'attach' then
      local waiting = config.waiting or 500
      local server = config.server or vim.env.RUBY_DEBUG_HOST or '127.0.0.1'

      local function start_on_port(port)
        if config.command then
          vim.env.RUBY_DEBUG_OPEN = true
          vim.env.RUBY_DEBUG_HOST = server
          vim.env.RUBY_DEBUG_PORT = port
          execute_command(config.command, config.args, config.line_context, config.file_context, config.fail_on_error)
        end

        vim.defer_fn(function()
          callback({ type = 'server', host = server, port = port })
        end, waiting)
      end

      config.port = config.port or (config.random_port and math.random(49152, 65535))

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

local function configure_ruby_debugger()
  add_dap_configs({
    rspec_config({ name = 'RSpec: run nearest test (line)', line_context = true }),
    rspec_config({ name = 'RSpec: run current spec (file)', file_context = true }),
    rspec_config({ name = 'RSpec: run entire suite' }),

    run_config({ name = 'Rails: execute `rails server`', command = 'bundle', args = { 'exec', 'rails', 'server' } }),
    run_config({ name = 'Rails: execute `bin/dev`', command = 'bin/dev' }),

    run_config({ name = 'Ruby: debug current file (rdbg)', command = 'rdbg', file_context = true, fail_on_error = true }),
    base_config({ name = 'Ruby: attach to existing session (port)', waiting = 0 }),
  })
end

function M.setup()
  setup_ruby_adapter()
  configure_ruby_debugger()
end

function M.debug_nearest_test()
  local dap = load_module('dap')

  local config = rspec_config({
    name = 'RSpec: run nearest test (line)',
    line_context = true
  })

  vim.notify(string.format('Starting debug session "%s"...', config.name))
  return dap.run(config)
end

function M.debug_test()
  M.debug_nearest_test()

  -- TODO: Implement logic to dynamically select the appropriate debugging configuration
  --       based on the type of file being edited (e.g., Ruby script, Rails application).
  --       Additionally, develop a method to accurately locate the corresponding test
  --       or spec file when working within a Rails project context.
end

return M
