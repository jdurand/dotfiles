local M = {}

local function load_module(module_name)
  local ok, module = pcall(require, module_name)

  assert(ok, string.format("dap-ruby dependency error: %s not installed", module_name))

  return module
end

local function prompt_for_port(callback)
  vim.ui.input(
    { prompt = "Input port to connect to: " },
    function(input)
      if input and input:match("^%d+$") then
        callback(tonumber(input))
      else
        print("Invalid port selected.")
        callback(nil)
      end
    end
  )
end

-- Command may not be in path, so travel up the directory tree to find it
local function find_cmd_dir(cmd)
  local filepath = vim.fn.getcwd()
  local og_filepath = filepath

  if vim.fn.executable(cmd) == 1 then
    return filepath
  end

  while filepath ~= "" and filepath ~= "/" do
    if vim.fn.executable(filepath .. "/" .. cmd) == 1 then
      return filepath
    end
    filepath = vim.fn.fnamemodify(filepath, ':h')
  end

  error(cmd .. " not found in " .. og_filepath .. " or any of its ancestors")
end

local function run_cmd(cmd, args, for_current_line, for_current_file, error_on_failure)
  local handle
  local pid_or_err
  local stdout = vim.loop.new_pipe(false)
  local working_dir = find_cmd_dir(cmd)

  args = args or {}

  if for_current_line then
    table.insert(args, vim.fn.expand("%:p") .. ":" .. vim.fn.line("."))
  elseif for_current_file then
    table.insert(args, vim.fn.expand("%:p"))
  end

  local opts = { args = args, cwd = working_dir, stdio = { nil, stdout } }

  handle, pid_or_err = vim.loop.spawn(cmd, opts, function(code)
    if handle then
      handle:close()
    end
    if error_on_failure and code ~= 0 then
      local full_cmd = cmd .. " " .. table.concat(args, " ")
      error("Command `" .. full_cmd .. "` ran from `" .. working_dir .. "` exited with code " .. code)
    end
  end)

  assert(handle, "Error running command: " .. cmd .. tostring(pid_or_err))

  stdout:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      vim.schedule(function()
        require("dap.repl").append(chunk)
      end)
    end
  end)
end

local function setup_ruby_adapter(dap)
  dap.adapters.ruby = function(callback, config)
    local waiting = config.waiting or 500
    local server = config.server or vim.env.RUBY_DEBUG_HOST or '127.0.0.1'

    local function run_on_port(port)
      if config.command then
        vim.env.RUBY_DEBUG_OPEN = true
        vim.env.RUBY_DEBUG_HOST = server
        vim.env.RUBY_DEBUG_PORT = port
        run_cmd(
          config.command, config.args, config.current_line, config.current_file,
          config.error_on_failure
        )
      end

      -- Wait for rdbg to start
      vim.defer_fn(function()
        callback({ type = "server", host = server, port = port })
      end, waiting)
    end

    -- Take the port from the config if the user has set this
    -- If not, pick a random ephemeral port so we (probably) wont collide with other debuggers or anything else
    -- If not, have the user pick a port
    config.port = config.port or (config.random_port and math.random(49152, 65535))

    if config.port then
      run_on_port(config.port)
    else
      prompt_for_port(run_on_port)
    end
  end
end

local function setup_ruby_configuration(dap)
  local base_config = { type = "ruby", request = "attach", options = { source_filetype = "ruby" }, error_on_failure = true, localfs = true }
  local run_config = vim.tbl_extend("force", base_config, { waiting = 1000, random_port = true })

  local function extend_base_config(config)
    return vim.tbl_extend("force", base_config, config)
  end

  local function extend_run_config(config)
    return vim.tbl_extend("force", run_config, config)
  end

  dap.configurations.ruby = {
    --
    -- TDOO: find a way to filter these options based on the filename
    --
    extend_run_config({ name = "run rspec current_file:current_line", command = "bundle", args = { "exec", "rspec" }, current_line = true, error_on_failure = false }),
    extend_run_config({ name = "run rspec current file", command = "bundle", args = { "exec", "rspec" }, current_file = true, error_on_failure = false }),
    extend_run_config({ name = "run rspec", command = "bundle", args = { "exec", "rspec" }, error_on_failure = false }),

    extend_run_config({ name = "debug current file", command = "ruby", args = { "-rdebug" }, current_file = true }),

    extend_run_config({ name = "run rails", command = "bundle", args = { "exec", "rails", "server" }, error_on_failure = false }),
    extend_run_config({ name = "bin/dev", command = "bin/dev", error_on_failure = false }),

    -- extend_base_config({ name = "attach existing (port 38698)", port = 38698, waiting = 0 }),
    extend_base_config({ name = "attach existing (pick port)", waiting = 0 }),

    -- extend_run_config({ name = "dap", command = "bundle", args = { "exec", "rspec" }, current_line = true }),
  }
end

function M.setup()
  local dap = load_module("dap")

  setup_ruby_adapter(dap)
  setup_ruby_configuration(dap)
end

return M
