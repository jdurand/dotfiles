return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require("nvim-treesitter.install").prefer_git = true
      require 'nvim-treesitter.configs'.setup {
        autotag = {
          enable = true,
          filetypes = {
            "html",
            "javascript", "typescript",
            "typescript.glimmer", "javascript.glimmer",
            "javascriptreact", "typescriptreact",
            "markdown",
            "glimmer", "handlebars", "hbs", "svelte", "vue"
          }
        },
        ensure_installed = {
          -- Web Languages
          "javascript", "typescript",
          "html", "css", "regex",
          -- "ejs",
          -- Web Framework Languages
          "glimmer", "svelte",
          -- Web Transport Languages
          "graphql",
          -- Documentation Languages
          "markdown", "markdown_inline",
          -- "help", -- missing?
          -- "comment", -- slow?
          "jsdoc",
          -- Configuration Languages
          "toml", "jsonc",
          "dockerfile",
          "lua", "vim",
          -- Scripting Languages
          "commonlisp",
          "bash",
          "jq",
          -- Systems Languages
          "c", "cmake",
          "rust",
          "go",
          -- Specifically for the treesitter AST
          "query",
          -- Utility Syntaxes
          "diff",
          "jq",
          "git_rebase", "gitcommit", "gitignore"
        },
        ignore_install = {
          "json" -- jsonc is better
        },
        highlight = {
          enable = true,
        },
        indent = {
          enable = true
        },
      }

      require('ts_context_commentstring').setup({})
      vim.g.skip_ts_context_commentstring_module = true
    end
  },
  {
    -- Useful for large functions or in unfamiliar code
    'nvim-treesitter/nvim-treesitter-context'
  },
}
