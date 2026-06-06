return {
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs', 'razor' },
    dependencies = {
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
        ensure('roslyn')
        ensure('netcoredbg')
        ensure('csharpier')
      end)

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
      if ok_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      require('roslyn').setup({
        config = {
          capabilities = capabilities,
          on_attach = function(client, bufnr)
            local ok_keymaps, keymaps = pcall(require, 'user.keymaps.lsp')
            if ok_keymaps and keymaps.on_attach then
              keymaps.on_attach(client, bufnr)
            end
          end,
        },
      })
    end,
  },
  {
    'GustavEikaas/easy-dotnet.nvim',
    ft = { 'cs', 'fsharp', 'razor' },
    cmd = { 'Dotnet' },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('easy-dotnet').setup({
        test_runner = {
          viewmode = 'split',
        },
      })
    end,
  },
  {
    'Issafalcon/neotest-dotnet',
    ft = { 'cs', 'fsharp' },
    dependencies = {
      'nvim-neotest/neotest',
    },
  },
}
