local M = {}

local function load_module(name)
  local ok, mod = pcall(require, name)
  assert(ok, string.format('Missing dependency: %s', name))
  return mod
end

local function find_project_root()
  local markers = { '*.sln', '*.slnx', '*.csproj', '*.fsproj' }
  for _, glob in ipairs(markers) do
    local hits = vim.fs.find(function(name)
      return name:match(glob:gsub('%*', '.*') .. '$')
    end, { upward = true, path = vim.fn.expand('%:p:h'), limit = 1 })
    if hits[1] then return vim.fs.dirname(hits[1]) end
  end
  return vim.fn.getcwd()
end

local function find_first(pattern)
  local hits = vim.fs.find(function(name)
    return name:match(pattern .. '$')
  end, { upward = true, path = vim.fn.expand('%:p:h'), limit = 1 })
  return hits[1]
end

local function project_kind(root)
  if find_first('%.sln') or find_first('%.slnx') then return 'sln' end
  if vim.fn.glob(root .. '/*.csproj') ~= '' then return 'csproj' end
  if vim.fn.glob(root .. '/*.fsproj') ~= '' then return 'fsproj' end
  return nil
end

local function netcoredbg_path()
  return vim.fn.stdpath('data') .. '/mason/packages/netcoredbg/netcoredbg'
end

local function pick_dll(root)
  local dlls = vim.fn.globpath(root, 'bin/Debug/**/*.dll', false, true)
  if #dlls == 0 then
    vim.notify('No built dll under bin/Debug — run `dotnet build` first.', vim.log.levels.WARN)
    return nil
  end
  if #dlls == 1 then return dlls[1] end
  return coroutine.create(function(co)
    vim.ui.select(dlls, { prompt = 'Select dll to debug' }, function(choice)
      coroutine.resume(co, choice)
    end)
  end)
end

local function configure_adapter()
  local dap = load_module('dap')
  dap.adapters.coreclr = {
    type = 'executable',
    command = netcoredbg_path(),
    args = { '--interpreter=vscode' },
  }
end

local function add_configs(configs)
  local dap = load_module('dap')
  dap.configurations.cs = vim.list_extend(dap.configurations.cs or {}, configs)
  dap.configurations.fsharp = vim.list_extend(dap.configurations.fsharp or {}, configs)
end

local function launch_config(opts)
  return vim.tbl_extend('force', {
    type = 'coreclr',
    request = 'launch',
    console = 'integratedTerminal',
  }, opts or {})
end

local function configure_defaults()
  add_configs({
    launch_config({
      name = '.NET: launch (pick dll)',
      program = function()
        return pick_dll(find_project_root())
      end,
      cwd = function() return find_project_root() end,
    }),
    launch_config({
      name = '.NET: attach (pid)',
      request = 'attach',
      processId = function()
        return require('dap.utils').pick_process()
      end,
    }),
  })
end

function M.setup(opts)
  opts = opts or {}
  configure_adapter()
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

local function overseer()
  return load_module('overseer')
end

-- Runs the current project via Overseer. Auto-detects .sln (dotnet run on
-- startup project), .csproj/.fsproj (dotnet run --project), or falls back
-- to a plain `dotnet run` in the cwd.
function M.run_project()
  local root = find_project_root()
  local kind = project_kind(root)
  local os = overseer()

  if kind == 'sln' then
    os.run_template({ name = '.NET: run (sln)' })
  elseif kind == 'csproj' or kind == 'fsproj' then
    os.run_template({ name = '.NET: run (project)' })
  else
    os.run_template({ name = '.NET: run (cwd)' })
  end
end

-- Launches the project with VSDBG enabled and attaches DAP. netcoredbg
-- attaches by pid since coreclr launch requires a built dll path; this
-- builds, runs the assembly, and lets the user pick the running pid.
function M.debug_project()
  local root = find_project_root()
  local dap = load_module('dap')

  if project_kind(root) == nil then
    vim.notify('Debug-project needs a .sln, .csproj, or .fsproj.', vim.log.levels.WARN)
    return
  end

  overseer().run_template({ name = '.NET: build' })
  vim.notify('Built — pick the dll to launch under DAP.')
  vim.defer_fn(function()
    dap.run({
      type = 'coreclr',
      request = 'launch',
      name = '.NET: launch (auto)',
      program = pick_dll(root),
      cwd = root,
      console = 'integratedTerminal',
    })
  end, 1500)
end

return M
