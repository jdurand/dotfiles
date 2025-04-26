local nnoremap = require('user.keymaps.bind').nnoremap

-- Asynchronously reload .gitignored files and directories
local function async_load_git_ignored(callback)
  local handle
  local stdout = vim.loop.new_pipe(false)
  local result = {}
  local ignored_files = {}
  local potential_dirs = {}

  handle = vim.loop.spawn('git', {
    args = { 'ls-files', '--others', '--ignored', '--exclude-standard' },
    stdio = { nil, stdout, nil },
    cwd = vim.fn.getcwd(),
  }, function()
    stdout:close()
    handle:close()

    -- Fill ignored files
    for _, path in ipairs(result) do
      local abs = vim.fn.fnamemodify(path, ':p')
      ignored_files[abs] = true

      -- Mark parent directories as potentially fully ignored
      local parent = vim.fn.fnamemodify(abs, ':h')
      while parent and parent ~= '/' do
        parent = parent:gsub('/*$', '') -- normalize to no trailing slash
        potential_dirs[parent] = true
        parent = vim.fn.fnamemodify(parent, ':h')
      end
    end

    -- A folder is only ignored if **all** its contents are ignored
    local ignored_dirs = {}

    for dir, _ in pairs(potential_dirs) do
      dir = dir:gsub('/*$', '') -- normalize to no trailing slash
      local fs = vim.loop.fs_scandir(dir)
      if fs then
        local all_ignored = true
        while true do
          local name, type = vim.loop.fs_scandir_next(fs)
          if not name then break end

          local full_path = vim.fn.fnamemodify(dir .. '/' .. name, ':p')
          full_path = full_path:gsub('/*$', '') -- normalize to no trailing slash

          if not vim.startswith(name, '.') and type == 'file' and not ignored_files[full_path] then
            all_ignored = false
            break
          elseif type == 'directory' then
            if not potential_dirs[full_path] then
              all_ignored = false
              break
            end
          end
        end

        if all_ignored then
          ignored_dirs[dir] = true
        end
      end
    end

    if callback then
      vim.schedule(function()
        callback({
          files = ignored_files,
          dirs = ignored_dirs,
        })
      end)
    end
  end)

  stdout:read_start(function(err, data)
    assert(not err, err)
    if data then
      for line in data:gmatch('[^\r\n]+') do
        table.insert(result, line)
      end
    end
  end)
end

-- Filter function used by mini.files
local function filter_hidden_files(entry, ignored)
  local abs_path = vim.fn.fnamemodify(entry.path, ':p')
  abs_path = abs_path:gsub('/*$', '') -- normalize to no trailing slash

  -- Always hide dotfiles unless explicitly toggled
  if vim.startswith(entry.name, '.') then
    return false
  end

  if entry.fs_type == 'file' then
    return not ignored.files[abs_path]
  end

  if entry.fs_type == 'directory' then
    return not ignored.dirs[abs_path]
  end

  return true
end

return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    -- lazy = false,
    branch = 'v3.x',
    keys = {
      { '<leader><C-f>', '<cmd>Neotree toggle<cr>', desc = 'NeoTree' },
    },
    config = function()
      require('neo-tree').setup({
        window = {
          mappings = {
            ['<space>'] = {
              'toggle_preview', config = { use_float = true, use_image_nvim = false }
            },
            ['<C-f>'] = 'close_window',
            ['<C-l>'] = 'focus_preview',
            ['<C-d>'] = { 'scroll_preview', config = { direction = -5 } },
            ['<C-u>'] = { 'scroll_preview', config = { direction = 5 } },
          }
        }
      })
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  },
  {
    '3rd/image.nvim',
    dependencies = { 'luarocks.nvim' },
    opts = {
      rocks = {
        hererocks = true,
        enabled = false
      }
    }
  },
  {
    'vhyrro/luarocks.nvim',
    priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    config = true,
    opts = {
      rocks = { 'magick' },
    },
  },
  {
    'echasnovski/mini.files',
    config = function()
      local files = require('mini.files')

      files.setup({
        options = {
          use_as_default_explorer = true,
        },
        mappings = {
          close       = 'q',
          go_in       = 'l',
          go_in_plus  = '<CR>',
          -- go_out      = 'H',
          go_out_plus = 'h',
          mark_goto   = "'",
          mark_set    = 'm',
          reset       = '<BS>',
          reveal_cwd  = '.',
          synchronize = '<C-s>',
          trim_left   = '<',
          trim_right  = '>',
          show_help   = '?',
        },
      })

      -- Hook into MiniFiles open
      local show_hidden = false
      local ignored_cache = {}

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          if vim.b[args.buf].is_hidden_files_filter_initialized then
            return
          end
          vim.b[args.buf].is_hidden_files_filter_initialized = true

          local function files_refresh()
            vim.defer_fn(function()
              files.refresh({
                content = {
                  filter = function(entry)
                    return show_hidden or filter_hidden_files(entry, ignored_cache)
                  end
                }
              })
            end, 10)
          end

          -- Setup keymap
          vim.keymap.set('n', 'H', function()
            show_hidden = not show_hidden
            files_refresh()
          end, { buffer = args.buf, desc = 'Toggle hidden files in mini.files' })

          -- Load ignored cache only if not already cached
          if ignored_cache and next(ignored_cache) == nil then
            async_load_git_ignored(function(ignored)
              ignored_cache = ignored
              files_refresh()
            end)
          else
            files_refresh()
          end
        end,
      })

      local open_file_explorer = function()
        -- open to the cwd with file preview
        files.open(vim.uv.cwd(), true, {
          windows = {
            preview = true,
            width_preview = 100,
          }
        })
      end

      -- Open the directory of the current file, or the working directory if the file is absent (e.g., after switching branches).
      nnoremap('<C-f>', function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")

        if vim.fn.filereadable(buf_name) == 1 then
          -- Pass the full file path to highlight the file
          files.open(buf_name, true)
        elseif vim.fn.isdirectory(dir_name) == 1 then
          -- If the directory exists but the file doesn't, open the directory
          files.open(dir_name, true)
        else
          -- If neither exists
          -- open file explorer
          -- open_file_explorer()
          --
          -- fallback to Neotree
          files.close()
          require('neo-tree.command').execute({ action = 'focus' })
        end
      end, { desc = 'Open mini.files (directory of current file)' })

      -- Open the current working directory
      nnoremap('<leader><C-d>', open_file_explorer, { desc = 'Open mini.files (working directory)' })
    end
  },
}
