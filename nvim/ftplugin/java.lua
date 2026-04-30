local ok_jdtls, jdtls = pcall(require, 'jdtls')
if not ok_jdtls then return end

local mason_path = vim.fn.stdpath('data') .. '/mason/packages'
local jdtls_path = mason_path .. '/jdtls'
local launcher = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')
if launcher == '' then
  vim.notify('jdtls not installed yet — run :Mason', vim.log.levels.WARN)
  return
end

local os_config
if vim.fn.has('mac') == 1 then
  os_config = jdtls_path .. '/config_mac'
elseif vim.fn.has('unix') == 1 then
  os_config = jdtls_path .. '/config_linux'
else
  os_config = jdtls_path .. '/config_win'
end

local root_markers = { 'pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'mvnw', 'gradlew', '.git' }
local root_dir = require('jdtls.setup').find_root(root_markers) or vim.fn.getcwd()

local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.fn.stdpath('cache') .. '/jdtls/workspace/' .. project_name

local bundles = {
  vim.fn.glob(mason_path .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
}
vim.list_extend(
  bundles,
  vim.split(vim.fn.glob(mason_path .. '/java-test/extension/server/*.jar', true), '\n')
)

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if ok_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

local config = {
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx2g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-jar', launcher,
    '-configuration', os_config,
    '-data', workspace_dir,
  },
  root_dir = root_dir,
  capabilities = capabilities,
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      completion = {
        favoriteStaticMembers = {
          'org.junit.jupiter.api.Assertions.*',
          'org.junit.Assert.*',
          'org.mockito.Mockito.*',
          'java.util.Objects.requireNonNull',
        },
      },
      sources = {
        organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
      },
      configuration = {
        updateBuildConfiguration = 'interactive',
      },
    },
  },
  init_options = {
    bundles = bundles,
  },
  on_attach = function(client, bufnr)
    jdtls.setup_dap({ hotcodereplace = 'auto', config_overrides = {} })
    require('jdtls.dap').setup_dap_main_class_configs()

    local ok_keymaps, keymaps = pcall(require, 'user.keymaps.lsp')
    if ok_keymaps and keymaps.on_attach then
      keymaps.on_attach(client, bufnr)
    end
  end,
}

jdtls.start_or_attach(config)

-- Buffer-local Java keymaps (bound regardless of LSP attach state)
local bufnr = vim.api.nvim_get_current_buf()
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
end

local dap_java = require('user.extensions.nvim-dap-java')

map('n', '<leader>Jr', function() dap_java.run_project() end,                      'Java: run project/file')
map('n', '<leader>Jd', function() dap_java.debug_project() end,                    'Java: debug project (JDWP :5005)')
map('n', '<leader>Jo', function() jdtls.organize_imports() end,                    'Java: organize imports')
map('n', '<leader>Jv', function() jdtls.extract_variable() end,                    'Java: extract variable')
map('n', '<leader>Jc', function() jdtls.extract_constant() end,                    'Java: extract constant')
map('n', '<leader>Jm', function() jdtls.extract_method() end,                      'Java: extract method')
map('n', '<leader>Jt', function() require('jdtls.dap').test_nearest_method() end,  'Java: test nearest')
map('n', '<leader>JT', function() require('jdtls.dap').test_class() end,           'Java: test class')
map('n', '<leader>Jp', function() require('jdtls.dap').pick_test() end,            'Java: pick test')

map('v', '<leader>Jv', function() jdtls.extract_variable(true) end,                'Java: extract variable')
map('v', '<leader>Jc', function() jdtls.extract_constant(true) end,                'Java: extract constant')
map('v', '<leader>Jm', function() jdtls.extract_method(true) end,                  'Java: extract method')

local wk_ok, whichkey = pcall(require, 'which-key')
if wk_ok then
  whichkey.add({
    { '<leader>J', group = '[J]ava', buffer = bufnr },
    { '<leader>J', group = '[J]ava', mode = 'v', buffer = bufnr },
  })
end
