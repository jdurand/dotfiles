local M = {}

local function load_module(name)
  local ok, mod = pcall(require, name)
  assert(ok, string.format('Missing dependency: %s', name))
  return mod
end

local function find_project_root()
  local markers = { 'pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'mvnw', 'gradlew' }
  local found = vim.fs.find(markers, { upward = true, path = vim.fn.expand('%:p:h') })[1]
  return found and vim.fs.dirname(found) or vim.fn.getcwd()
end

local function build_tool(root)
  if vim.fn.filereadable(root .. '/pom.xml') == 1 then return 'maven' end
  if vim.fn.filereadable(root .. '/build.gradle') == 1 or
     vim.fn.filereadable(root .. '/build.gradle.kts') == 1 then return 'gradle' end
  return nil
end

local function add_configs(configs)
  local dap = load_module('dap')
  dap.configurations.java = vim.list_extend(dap.configurations.java or {}, configs)
end

local function launch_config(opts)
  return vim.tbl_extend('force', {
    type = 'java',
    request = 'launch',
    console = 'integratedTerminal',
  }, opts or {})
end

local function attach_config(opts)
  return vim.tbl_extend('force', {
    type = 'java',
    request = 'attach',
    hostName = '127.0.0.1',
  }, opts or {})
end

local function configure_defaults()
  add_configs({
    attach_config({
      name = 'Java: attach to remote (port 5005)',
      port = 5005,
    }),
    attach_config({
      name = 'Java: attach to remote (prompt port)',
      port = function()
        local input = vim.fn.input('Debug port: ', '5005')
        return tonumber(input)
      end,
    }),
  })
end

function M.setup(opts)
  opts = opts or {}
  configure_defaults()
  if opts.dap_configs then
    for _, cfg in ipairs(opts.dap_configs) do
      add_configs({ launch_config(cfg) })
    end
  end
end

function M.add_config(opts)
  add_configs({ launch_config(opts) })
end

function M.debug_main_class()
  local ok, jdtls_dap = pcall(require, 'jdtls.dap')
  if not ok then
    vim.notify('jdtls.dap not available — open a Java file first', vim.log.levels.WARN)
    return
  end
  jdtls_dap.pick_test() -- falls back nicely; for main-class, use setup_dap_main_class_configs
  vim.notify('Use :lua require("jdtls.dap").pick_test() or dap.continue() after opening a Java buffer.')
end

function M.debug_test()
  local ft = vim.bo.filetype
  if ft ~= 'java' then
    vim.notify('Not a Java buffer.', vim.log.levels.WARN)
    return
  end
  local ok, jdtls_dap = pcall(require, 'jdtls.dap')
  if not ok then
    vim.notify('jdtls.dap not loaded — is jdtls attached?', vim.log.levels.WARN)
    return
  end
  jdtls_dap.test_nearest_method()
end

function M.debug_class()
  local ok, jdtls_dap = pcall(require, 'jdtls.dap')
  if not ok then return end
  jdtls_dap.test_class()
end

function M.build_info()
  local root = find_project_root()
  return { root = root, tool = build_tool(root) }
end

local function overseer()
  return load_module('overseer')
end

-- Runs the current project or file via Overseer.
-- Auto-detects Maven (mvn exec:java), Gradle (gradle run), or falls back
-- to single-file source-code execution (java <file>).
function M.run_project()
  local root = find_project_root()
  local tool = build_tool(root)
  local os = overseer()

  if tool == 'maven' then
    os.run_template({ name = 'Maven: exec:java' })
  elseif tool == 'gradle' then
    os.run_template({ name = 'Gradle: run' })
  else
    os.run_template({ name = 'Java: run current file' })
  end
end

-- Launches the project with JDWP enabled and attaches the DAP debugger
-- once the JVM is listening on :5005. Breakpoints, step, watches, etc.
-- all work via your existing td* keymaps.
function M.debug_project()
  local root = find_project_root()
  local tool = build_tool(root)
  local os = overseer()
  local dap = load_module('dap')

  local template
  if tool == 'maven' then
    template = 'Maven: debug (exec)'
  elseif tool == 'gradle' then
    template = 'Gradle: debug'
  else
    vim.notify('Debug-project needs a Maven or Gradle project.', vim.log.levels.WARN)
    return
  end

  os.run_template({ name = template })

  vim.notify(string.format('Launching %s debug task — attaching DAP on :5005 in 3s...', tool))
  vim.defer_fn(function()
    dap.run({
      type = 'java',
      request = 'attach',
      name = 'Java: attach (auto)',
      hostName = '127.0.0.1',
      port = 5005,
    })
  end, 3000)
end

return M
