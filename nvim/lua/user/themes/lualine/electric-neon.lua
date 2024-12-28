-- stylua: ignore
local colors = {
  blue   = '#33ccff',  -- Electric Blue
  cyan   = '#9c27b0',  -- Violet Accent
  black  = '#1b0b23',  -- Dark Purple Background
  white  = '#f0e6f6',  -- Soft White/Pink Glow
  red    = '#ff3399',  -- Bright Neon Pink
  pink = '#ff3399',  -- Neon Pink (Active highlight)
  grey   = '#302136',  -- Subtle Dark Grey Accent
  grey2   = '#32344D',  -- Subtle Grey Accent
}

return {
  normal = {
    a = { fg = colors.black, bg = colors.pink }, -- Neon Pink highlight
    b = { fg = colors.white, bg = colors.grey },   -- White text on subtle grey
    c = { fg = colors.white, bg = colors.grey2 },  -- Soft White Glow
  },

  insert = { a = { fg = colors.black, bg = colors.blue } },   -- Electric Blue
  visual = { a = { fg = colors.black, bg = colors.cyan } },   -- Violet Accent
  replace = { a = { fg = colors.black, bg = colors.red } },   -- Bright Neon Pink
  terminal = { a = { fg = colors.black, bg = colors.white } },   -- Electric Blue

  inactive = {
    a = { fg = colors.white, bg = colors.black },  -- White on Dark Purple
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white, bg = colors.grey2 },
  },
}
