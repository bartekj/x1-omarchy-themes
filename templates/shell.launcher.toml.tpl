# {{ display_name }} launcher: surface card + hairline border; the selected
# row echoes the solid window-border line (the old walker identity). No font
# keys — stock sizing wins.
background                = "{{ surface }}"
background-alpha          = {{ pill_alpha }}
text                      = "{{ foreground }}"
border                    = "{{ border_soft }}"
border-alpha              = {{ pill_border_alpha }}
scrim                     = "{{ background }}"
scrim-alpha               = 0.5
selected-background       = "{{ foreground }}"
selected-background-alpha = 0.08
selected-text             = "{{ accent }}"
selected-border           = "hyprland.active-border"
selected-border-alpha     = 0.35
