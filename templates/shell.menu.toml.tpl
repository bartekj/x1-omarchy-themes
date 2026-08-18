# {{ display_name }} menu: same card treatment as the launcher — hairline
# border, selected row echoes the solid window-border line.
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
