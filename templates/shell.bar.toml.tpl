# {{ display_name }} bar: translucent glass over the wallpaper. Sizing and
# scale-with-font keys are deliberately omitted so omarchy-display-text-size
# keeps working. `active` is critical, not accent: accent never means alert.
background       = "{{ background }}"
background-alpha = {{ bar_alpha }}
text             = "{{ foreground }}"
active           = "{{ critical }}"
