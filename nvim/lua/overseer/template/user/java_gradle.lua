local function find_root()
  local found = vim.fs.find({ 'build.gradle', 'build.gradle.kts', 'settings.gradle' },
    { upward = true, path = vim.fn.expand('%:p:h') })[1]
  return found and vim.fs.dirname(found) or nil
end

local function gradle_cmd(root)
  local wrapper = root .. '/gradlew'
  if vim.fn.executable(wrapper) == 1 then return { wrapper } end
  return { 'gradle' }
end

local function task(name, args, desc)
  return {
    name = 'Gradle: ' .. name,
    desc = desc,
    builder = function()
      local root = find_root()
      vim.schedule(function() require('overseer').open({ enter = false }) end)
      return {
        cmd = gradle_cmd(root),
        args = args,
        cwd = root,
        components = { 'default' },
      }
    end,
    condition = { callback = function() return find_root() ~= nil end },
  }
end

return {
  generator = function(_, cb)
    cb({
      task('build',   { 'build' },                          'gradle build'),
      task('test',    { 'test' },                           'gradle test'),
      task('run',     { 'run' },                            'gradle run (application plugin)'),
      task('clean',   { 'clean' },                          'gradle clean'),
      task('debug',   { 'run', '--debug-jvm' },             'gradle run with JDWP on :5005 — attach afterwards'),
    })
  end,
}
