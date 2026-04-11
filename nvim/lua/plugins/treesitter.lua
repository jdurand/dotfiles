return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup {}

      require('nvim-treesitter').install {
        -- Web Languages
        "javascript", "typescript",
        "html", "css", "regex",
        -- Web Framework Languages
        "glimmer", "svelte",
        -- Web Transport Languages
        "graphql",
        -- Documentation Languages
        "markdown", "markdown_inline",
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
        "ruby", "rust", "go",
        -- Specifically for the treesitter AST
        "query",
        -- Utility Syntaxes
        "diff",
        "git_rebase", "gitcommit", "gitignore",
      }

      -- Enable treesitter highlighting for all supported filetypes
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })

      -- Enable treesitter-based indentation
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      require('ts_context_commentstring').setup({})
      vim.g.skip_ts_context_commentstring_module = true
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = true,
    config = function()
      require("nvim-treesitter-textobjects").setup {
        select = {
          lookahead = true,
        },
        swap = {},
      }

      local swap = require("nvim-treesitter-textobjects.swap")

      vim.keymap.set("n", "<leader>na", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap parameter with next" })
      vim.keymap.set("n", "<leader>nm", function()
        swap.swap_next("@function.outer")
      end, { desc = "Swap function with next" })
      vim.keymap.set("n", "<leader>pa", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap parameter with previous" })
      vim.keymap.set("n", "<leader>pm", function()
        swap.swap_previous("@function.outer")
      end, { desc = "Swap function with previous" })
    end,
  },
  {
    -- Useful for large functions or in unfamiliar code
    'nvim-treesitter/nvim-treesitter-context',
  },
}
