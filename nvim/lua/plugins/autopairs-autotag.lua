return {
  {
    'windwp/nvim-ts-autotag', -- Automatically adds/removes matching HTML/template tags
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true,
      },
      per_filetype = {
        ["html"] = { enable_close = true },
        ["markdown"] = { enable_close = true },
      },
    },
  },
}
