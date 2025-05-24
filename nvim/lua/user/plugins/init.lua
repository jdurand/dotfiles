local plugin_dir = vim.fn.stdpath('config') .. '/lua/user/plugins'
for name, _type in vim.fs.dir(plugin_dir) do
  if name ~= 'init.lua' and name:sub(-4) == '.lua' then
    local module = 'user.plugins.' .. name:sub(1, -5)
    require(module)
  end
end
