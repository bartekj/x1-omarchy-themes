-- {{ display_name }}: laptop-first visual language — compact and sharp.
-- Solid full-alpha borders: one accent line active, warm graphite inactive.
-- The shell popups consume hyprland_active_border at border-alpha 1.0, so
-- window borders and popup borders are now the exact same line.
local active_border_color = "rgba({{ accent_strip }}ff)"
local inactive_border_color = "rgba({{ window_border_inactive_strip }}ff)"

hl.config({
  general = {
    gaps_in = {{ hypr_gaps_in }},
    gaps_out = {{ hypr_gaps_out }},
    border_size = {{ hypr_border_size }},
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
      nogroup_border_active = "rgba({{ warning_strip }}ff)",
      nogroup_border = "rgba({{ warning_strip }}aa)",
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
      border_locked_active = "rgba({{ warning_strip }}ff)",
      border_locked_inactive = "rgba({{ warning_strip }}aa)",
    },
    groupbar = {
      text_color = "rgb({{ foreground_strip }})",
      text_color_inactive = "rgba({{ muted_strip }}cc)",
      col = { active = "rgba({{ accent_strip }}40)", inactive = "rgba({{ surface_strip }}cc)" },
    },
  },
  decoration = {
    rounding = {{ hypr_rounding }},
    border_part_of_window = false,
    -- range = gaps_out: inner seams no longer darker than screen edges.
    shadow = { enabled = true, range = 8, render_power = 3, color = "rgba(00000066)" },
    -- xray: window glass samples the wallpaper only — kills the red bloom.
    blur = { enabled = true, size = 6, passes = 3, xray = true },
  },
})

hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, blur_popups = true, ignore_alpha = 0.1 })
for _, ns in ipairs({
  "omarchy-menu", "omarchy-notifications", "omarchy-osd",
  "omarchy-keyboard-panel", "omarchy-clipboard", "omarchy-emojis",
}) do
  hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.1 })
end

-- One glass level (terminals included; explicit fullscreen value).
o.window({ tag = "default-opacity" }, { opacity = "0.97 0.94 1.0" })
-- Chromium never sheds default-opacity (same-pass tag quirk) — pin opaque,
-- declared AFTER the rule above so it wins regardless.
o.window({ tag = "chromium-based-browser" }, { opacity = "1 1 1" })
o.window({ tag = "firefox-based-browser" }, { opacity = "1 1 1" })
-- Stock apps/system.lua pops windows to rounding 8; keep theme geometry.
o.window({ tag = "pop" }, { rounding = {{ hypr_rounding }} })
