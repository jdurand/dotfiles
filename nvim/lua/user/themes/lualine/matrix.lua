-- stylua: ignore
local colors = {
  green  = '#00ff41',  -- Matrix Green
  dim    = '#00cc33',  -- Dimmer Green
  black  = '#0a1a0a',  -- Dark Green-Black Background
  white  = '#b3ffb3',  -- Pale Green Glow
  amber  = '#ccff00',  -- Bright Lime Accent
  grey   = '#0d2b0d',  -- Subtle Dark Green Accent
  grey2  = '#142814',  -- Subtle Green-Grey Accent
}

return {
  normal = {
    a = { fg = colors.black, bg = colors.green },
    b = { fg = colors.white, bg = colors.grey },
    c = { fg = colors.white, bg = colors.grey2 },
  },

  insert = { a = { fg = colors.black, bg = colors.amber } },
  visual = { a = { fg = colors.black, bg = colors.dim } },
  replace = { a = { fg = colors.black, bg = colors.green } },
  terminal = { a = { fg = colors.black, bg = colors.white } },

  inactive = {
    a = { fg = colors.white, bg = colors.black },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white, bg = colors.grey2 },
  },
}
