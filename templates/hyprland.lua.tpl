-- {{ display_name }}: laptop-first visual language — compact and sharp.
local active_border_color = { colors = { "rgba({{ accent_strip }}dd)", "rgba({{ border_gradient_strip }}dd)" }, angle = 35 }
local inactive_border_color = "rgba({{ border_strip }}88)"

hl.config({
  general = {
    gaps_in = {{ hypr_gaps_in }},
    gaps_out = {{ hypr_gaps_out }},
    border_size = {{ hypr_border_size }},
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    rounding = {{ hypr_rounding }},
    shadow = { enabled = true, range = 12, render_power = 3, color = "rgba(00000066)" },
    blur = { enabled = true, size = 6, passes = 3 },
  },
})

-- Bar glass: blur the translucent omarchy-shell bar layer.
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, ignore_alpha = 0.1 })

-- Terminals: frosted glass, deeper than the Omarchy default.
o.window({ tag = "terminal" }, { opacity = "0.90 0.82" })
