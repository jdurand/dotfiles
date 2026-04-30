local function find_root()
  local found = vim.fs.find({ 'pom.xml' }, { upward = true, path = vim.fn.expand('%:p:h') })[1]
  return found and vim.fs.dirname(found) or nil
end

local function mvn_cmd(root)
  local wrapper = root .. '/mvnw'
  if vim.fn.executable(wrapper) == 1 then return { wrapper } end
  return { 'mvn' }
end

local function task(name, args, desc)
  return {
    name = 'Maven: ' .. name,
    desc = desc,
    builder = function()
      local root = find_root()
      local cmd = mvn_cmd(root)
      vim.schedule(function() require('overseer').open({ enter = false }) end)
      return {
        cmd = cmd,
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
      task('compile',       { 'compile' },                                   'mvn compile'),
      task('test',          { 'test' },                                      'mvn test'),
      task('package',       { 'package' },                                   'mvn package'),
      task('clean install', { 'clean', 'install' },                          'mvn clean install'),
      task('exec:java',     { 'exec:java' },                                 'mvn exec:java (uses <exec.mainClass>)'),
      task('debug (exec)',  { 'exec:exec',
                              '-Dexec.executable=java',
                              '-Dexec.args=-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005 -classpath %classpath ${exec.mainClass}' },
                            'mvn exec with JDWP on :5005 — attach with "Java: attach to remote (port 5005)"'),
    })
  end,
}
