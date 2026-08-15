# {{ display_name }} lock screen: surface input field, accent ring, red only
# on error (the old hyprlock identity).
background       = "{{ surface }}"
background-alpha = 0.92
text             = "{{ foreground }}"
placeholder      = "{{ muted }}"
text-error       = "{{ critical }}"
border           = "{{ accent }}"
border-active    = "{{ accent }}"
border-error     = "{{ critical }}"
selection        = "{{ accent }}"
selection-alpha  = 0.45
