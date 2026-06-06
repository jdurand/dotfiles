return {
  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets
          -- This step is not supported in many windows environments
          -- Remove the below condition to re-enable on windows
          if vim.fn.has 'win32' == 1 then
            return
          end
          return 'make install_jsregexp'
        end)(),
      },
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', version = '1.11.0' },
      { 'williamboman/mason-lspconfig.nvim', version = '1.32.0' },

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
    config = function()
      -- mason-lspconfig requires that these setup functions are called in this order
      -- before setting up the servers.
      require('mason').setup({
        registries = {
          'github:mason-org/mason-registry',
          'github:Crashdummyy/mason-registry', -- roslyn (C# LSP), rzls
        },
      })
      require('mason-lspconfig').setup()

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. They will be passed to
      --  the `settings` field of the server config. You must look up that documentation yourself.
      --
      --  If you want to override the default filetypes that your language server will attach to you can
      --  define the property 'filetypes' to the map in question.
      local servers = {
        html = { filetypes = { 'html', 'twig', 'hbs'} },
        bashls = {},
        cssls = {},
        jsonls = {},
        yamlls = {},
        -- solargraph = {},
        ruby_lsp = {},
        ember = {},
        rubocop = {},
        marksman = {},
        tailwindcss = {
          tailwindCSS = {
            includeLanguages = {
              markdown = "html",
              handlebars = "html",
              javascript = {
                glimmer = "javascript"
              },
              typescript = {
                glimmer = "javascript"
              }
            }
          }
        },
        ts_ls = {
          maxTsServerMemory = 8000,
          implicitProjectConfig = {
            experimentalDecorators = true
          },
          -- importModuleSpecifier = "shortest"
        },
        lua_ls = {
          Lua = {
            workspace = {
              checkThirdParty = false,
              library = {},              -- empty = project only (recommended)
              -- Or: library = { vim.fn.getcwd() }  -- explicit project root
              ignoreDir = {              -- keep the crawl out of heavy dirs
                ".git", "node_modules", "dist", "build", ".venv", ".cache", "target", "tmp"
              },
              maxPreload = 500,          -- defaults are quite generous; lower them
              preloadFileSize = 50,      -- in KB; skip giant files
            },
            telemetry = { enable = false },
            -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
        eslint = {},
        -- snyk_ls = {},
      }

      -- Setup neovim lua configuration
      require('neodev').setup()

      -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      -- Ensure the servers above are installed
      require('mason-lspconfig').setup {
        ensure_installed = vim.tbl_keys(servers),
      }

      -- Set up LSP keymaps when a server attaches to a buffer
      local on_attach = require('user.keymaps.lsp').on_attach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          on_attach(vim.lsp.get_client_by_id(args.data.client_id), args.buf)
        end,
      })

      -- Configure and enable each server using native vim.lsp API
      for server_name, server_settings in pairs(servers) do
        local config = {
          capabilities = capabilities,
          settings = server_settings,
        }
        if server_settings.filetypes then
          config.filetypes = server_settings.filetypes
        end
        vim.lsp.config(server_name, config)
      end

      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },
}
