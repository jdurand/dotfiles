hl.config({
  input = {
    kb_layout = "us,ca",
    kb_variant = ",fr",
    kb_options = "compose:caps,grp:alt_space_toggle",
    repeat_rate = 40,
    repeat_delay = 200,
    numlock_by_default = true,
    natural_scroll = true,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
})

o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
