return {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    dependencies = {
      'mfussenegger/nvim-dap',
      'williamboman/mason.nvim',
    },
    config = function()
      local mr = require('mason-registry')

      local function ensure(pkg)
        if not mr.is_installed(pkg) then
          local p = mr.get_package(pkg)
          p:install()
        end
      end

      mr.refresh(function()
        ensure('jdtls')
        ensure('java-debug-adapter')
        ensure('java-test')
      end)
    end,
  },
}
