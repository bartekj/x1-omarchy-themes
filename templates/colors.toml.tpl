# {{ display_name }}: {{ description }}
mode = "dark"

accent = "{{ accent }}"
selection = "{{ selection_background }}"
# Shell secondary text uses the palette's muted gray (~7:1), not the ANSI
# dim gray color8 (~2.9:1) — terminals still get color8 via the ANSI ramp.
muted = "{{ muted }}"

background = "{{ background }}"
lighter_background = "{{ surface_raised }}"
# dark_background / darker_background: auto-derived by omarchy-theme-color

foreground = "{{ foreground }}"
dark_foreground = "{{ muted }}"
light_foreground = "{{ cursor }}"
bright_foreground = "{{ color15 }}"

red = "{{ color1 }}"
green = "{{ color2 }}"
yellow = "{{ color3 }}"
blue = "{{ color4 }}"
magenta = "{{ color5 }}"
cyan = "{{ color6 }}"
orange = "{{ warning }}"

bright_red = "{{ color9 }}"
bright_green = "{{ color10 }}"
bright_yellow = "{{ color11 }}"
bright_blue = "{{ color12 }}"
bright_magenta = "{{ color13 }}"
bright_cyan = "{{ color14 }}"

# X1 border identity: accent -> accent_dim at dd alpha, 35deg — the variant's
# own accent deepened, no foreign hue. Inactive = border at aa alpha (must be
# clearly visible at a glance, quieter than active). Consumed by Omarchy's
# stock hyprland.lua.tpl and the shell.toml [hyprland] tokens.
hyprland_active_border = "rgba({{ accent_strip }}dd) rgba({{ accent_dim_strip }}dd) 35deg"
hyprland_inactive_border = "rgba({{ border_strip }}aa)"
