local function find_first(pattern)
  local hits = vim.fs.find(function(name)
    return name:match(pattern .. '$')
  end, { upward = true, path = vim.fn.expand('%:p:h'), limit = 1 })
  return hits[1]
end

local function find_root()
  for _, pat in ipairs({ '%.sln', '%.slnx', '%.csproj', '%.fsproj' }) do
    local hit = find_first(pat)
    if hit then return vim.fs.dirname(hit) end
  end
  return nil
end

local function find_sln()
  return find_first('%.sln') or find_first('%.slnx')
end

local function find_project()
  return find_first('%.csproj') or find_first('%.fsproj')
end

local function task(name, args, desc, opts)
  opts = opts or {}
  return {
    name = '.NET: ' .. name,
    desc = desc,
    builder = function()
      local root = find_root()
      vim.schedule(function() require('overseer').open({ enter = false }) end)
      return {
        cmd = { 'dotnet' },
        args = args,
        cwd = root,
        components = { 'default' },
      }
    end,
    condition = {
      callback = function()
        if opts.requires == 'sln' then return find_sln() ~= nil end
        if opts.requires == 'project' then return find_project() ~= nil end
        return find_root() ~= nil
      end,
    },
  }
end

local function project_arg()
  local proj = find_project()
  return proj and { '--project', proj } or {}
end

return {
  generator = function(_, cb)
    local with_project = project_arg()
    local with_run = vim.list_extend({ 'run' }, with_project)
    local with_watch = vim.list_extend({ 'watch' }, with_project)

    cb({
      task('build',           { 'build' },                      'dotnet build'),
      task('test',            { 'test' },                       'dotnet test'),
      task('run (project)',   with_run,                         'dotnet run --project <csproj>',  { requires = 'project' }),
      task('run (sln)',       { 'run' },                        'dotnet run (startup project)',   { requires = 'sln' }),
      task('run (cwd)',       { 'run' },                        'dotnet run in cwd'),
      task('watch',           with_watch,                       'dotnet watch (hot reload)'),
      task('restore',         { 'restore' },                    'dotnet restore'),
      task('clean',           { 'clean' },                      'dotnet clean'),
      task('publish',         { 'publish', '-c', 'Release' },   'dotnet publish -c Release'),
      task('format',          { 'format' },                     'dotnet format'),
      {
        name = '.NET: debug (run)',
        desc = 'dotnet run with VSTEST_HOST_DEBUG=1 — attach with ":lua require(\'dap\').continue()"',
        builder = function()
          local root = find_root()
          vim.schedule(function() require('overseer').open({ enter = false }) end)
          return {
            cmd = { 'dotnet' },
            args = vim.list_extend({ 'run' }, project_arg()),
            cwd = root,
            env = { VSTEST_HOST_DEBUG = '1' },
            components = { 'default' },
          }
        end,
        condition = { callback = function() return find_root() ~= nil end },
      },
    })
  end,
}
