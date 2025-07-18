return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>cf',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        ruby = { "rubocop" },
        javascript = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
        python = { "black", "isort" },
        lua = { "stylua" },
        markdown = { "prettier" },
        ['javascript.glimmer'] = { { "prettierd", "prettier" } },
      },
      format_on_save = false,
      notify_on_error = false,
      formatters = {
        prettierd = {
          require_cwd = true
        },
        prettier = {
          require_cwd = true
        }
      }
    },
  }
}
