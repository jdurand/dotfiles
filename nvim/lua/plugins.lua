-- This file can be loaded by calling `lua require('plugins')` from your init.vim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- color schemes
  -- 'remiprev/vim-colors-solarized',
  -- 'craftzdog/solarized-osaka.nvim',
  -- 'polirritmico/monokai-nightasty.nvim',
  -- 'folke/tokyonight.nvim',
  {
    'catppuccin/vim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup({
        flavour = 'mocha', -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = 'latte',
          dark = 'mocha',
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          harpoon = true,
          illuminate = true,
          indent_blankline = {
            enabled = false,
            scope_color = "sapphire",
            colored_indent_levels = false,
          },
          mason = true,
          native_lsp = { enabled = true },
          notify = true,
          nvimtree = true,
          neotree = true,
          symbols_outline = true,
          telescope = true,
          treesitter = true,
          treesitter_context = true,
        },
      })

      vim.opt.termguicolors = true
      vim.cmd.colorscheme 'catppuccin-mocha'
    end,
  },
  -- plugins
  'rstacruz/vim-closer',
  'mileszs/ack.vim',
  'vim-scripts/camelcasemotion',
  'tmhedberg/matchit',
  {
    'numToStr/Comment.nvim',
    lazy = false,
    opts = {
        -- add any options here
    },
    config = function()
      require('Comment').setup({
        -- ignore = '^$',
        -- toggler = {
        --   line = '<leader>cc',
        --   block = '<leader>bc',
        -- },
        -- opleader = {
        --   line = '<leader>c',
        --   block = '<leader>b',
        -- },
      })

      -- vim.keymap.set("n", "<Leader>cc", function() require('Comment.api').toggle.linewise.current() end, { noremap = true, silent = true })
      -- vim.keymap.set("n", "<Leader>bc", function() require('Comment.api').toggle.blockwise.current() end, { noremap = true, silent = true })
    end,
  },
  'tpope/vim-commentary', -- couldn’t figure out how to map <leader>cc using Comment.nvim
  'tpope/vim-surround',
  'tpope/vim-abolish',
  'vim-scripts/YankRing.vim',
  'ervandew/supertab',
  'jszakmeister/vim-togglecursor',
  'embear/vim-localvimrc',
  'fvictorio/vim-extract-variable',
  'w0rp/ale',
  'edkolev/tmuxline.vim',
  'christoomey/vim-tmux-navigator',
  'scrooloose/nerdtree',
  'airblade/vim-gitgutter',
  'tpope/vim-eunuch',
  'tpope/vim-fugitive',
  'nvim-lua/plenary.nvim',
  'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
  'MunifTanjim/nui.nvim',
  'wincent/terminus',
  'voldikss/vim-floaterm',
  'RRethy/vim-illuminate',
  -- 'sheerun/vim-polyglot',
  -- {
  --   'nvim-treesitter/nvim-treesitter',
  --   build = ':TSUpdate'
  -- },
  --
  {
    "ThePrimeagen/harpoon",
    lazy = true,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    config = function()
      local harpoon = require('harpoon.mark')

      local function truncate_branch_name(branch)
        if not branch or branch == "" then
          return ''
        end

        -- Match the branch name to the specified format
        local _, _, ticket_number = string.find(branch, ".*?/lib%-(%d+)%-")

        -- If the branch name matches the format, display lib-{ticket_number}, otherwise display the full branch name
        if ticket_number then
          return 'lib-' .. ticket_number
        else
          return branch
        end
      end

      local function harpoon_component()
        local total_marks = harpoon.get_length()

        if total_marks == 0 then
          return ''
        end

        local current_mark = "—"

        local mark_idx = harpoon.get_current_index()
        if mark_idx ~= nil then
          current_mark = tostring(mark_idx)
        end

        return string.format("󱡅 %s/%d", current_mark, total_marks)
      end

      require('lualine').setup({
        options = {
          theme = 'catppuccin',
          globalstatus = true,
          component_separators = { left = "█", right = "█" },
          section_separators = { left = "█", right = "█" },
        },
        sections = {
          lualine_b = {
            { 'branch', icon = "", fmt = truncate_branch_name },
            harpoon_component,
            'diff',
            'diagnostics',
          },
          lualine_c = {
            { 'filename', path = 1 },
          },
          lualine_x = {
            'filetype',
          },
        },
      })
    end,
    depencencies = {
      'catppuccin/vim'
    }
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
      }
    end
  },
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
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {} -- this is equalent to setup({}) function
  },
  {
    'windwp/nvim-ts-autotag',
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    -- lazy = false,
    branch = "v3.x",
    keys = {
      { "<C-f>", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
    },
    config = function()
      require('neo-tree').setup()
    end,
    depencencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  },
  {
    'wincent/command-t',
    -- lazy = false,
    -- branch = '5-x-release',
    build = 'cd lua/wincent/commandt/lib && make && cd - && cd ruby/command-t/ext/command-t && ruby extconf.rb && make',
    init = function ()
      -- vim.g.CommandTPreferredImplementation = 'ruby'
      vim.g.CommandTPreferredImplementation = 'lua'
    end,
    config = function()
      require('wincent.commandt').setup({
        -- Customizations go here.
      })
    end,
  },
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      vim.opt.termguicolors = true
      require("bufferline").setup({
        options = {
          separator_style = 'thick', -- "slant" | "slope" | "thick" | "thin" | { 'any', 'any' },
          sort_by = 'relative_directory', -- 'insert_after_current' |'insert_at_end' | 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
        }
      })
    end,
  },
  {
    'jalvesaq/Nvim-R',
    branch = 'stable',
  },
  {
    "dpayne/CodeGPT.nvim",
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    config = function()
      require("codegpt.config")

      vim.g["codegpt_commands"] = {
        ["modernize"] = {
          -- model = "gpt-3.5-turbo",
          model = "gpt-3.5-turbo-16k",
          -- model = "gpt-4-turbo-preview",
          -- max_tokens = 4096,
          max_tokens = 16384,
          user_message_template = "I have the following {{language}} code: ```{{filetype}}\n{{text_selection}}```\nModernize the above code. Use current best practices. Only return the code snippet and comments. {{language_instructions}}",
          language_instructions = {
            cpp = "Refactor the code to use trailing return type, and the auto keyword where applicable.",
          },
        }
      }
    end
  }
})

-- 'prettier/vim-prettier', { 'do': 'yarn install' },
-- " Plug 'prettier/vim-prettier', {
-- "   \ 'do': 'yarn install',
-- "   \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }

