return {
  black = 0xff181819,
  white = 0xffe2e2e3,
  red = 0xfffc5d7c,
  green = 0xff00ff7f,
  blue = 0xdd33ccff,
  dark_blue = 0xff007aff,
  yellow = 0xffe7c664,
  orange = 0xfff39660,
  cyan = 0xff00d4ff,
  magenta = 0xffff1d8e,
  grey = 0xff7f8490,
  transparent = 0x00000000,

  bar = {
    bg = 0xd024283b,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xc02c2e34,
    border = 0xff7f8490
  },
  bg1 = 0xff2e2e3f,
  bg2 = 0x884b4e5a,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
