return {
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',      -- LSP source
      'hrsh7th/cmp-buffer',        -- buffer source
      'hrsh7th/cmp-path',          -- filesystem paths
      'hrsh7th/cmp-cmdline',       -- cmdline completions
      'L3MON4D3/LuaSnip',          -- snippet engine
      'saadparwaiz1/cmp_luasnip',  -- LuaSnip completions
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      local next_suggestion = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end

      local previous_suggestion = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<Tab>'] = cmp.mapping(next_suggestion, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(previous_suggestion, { 'i', 's' }),
          ['<C-j>'] = cmp.mapping(next_suggestion, { 'i', 's' }),
          ['<C-k>'] = cmp.mapping(previous_suggestion, { 'i', 's' }),
          ['<C-u>'] = cmp.mapping.scroll_docs(-4),
          ['<C-d>'] = cmp.mapping.scroll_docs(4),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          {
            name = 'buffer',
            option = {
              -- include all visible buffers
              get_bufnrs = function()
                local bufs = {}

                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  bufs[vim.api.nvim_win_get_buf(win)] = true
                end
                return vim.tbl_keys(bufs)
              end
            }
          },
        }),
      })
    end,
  },
}
