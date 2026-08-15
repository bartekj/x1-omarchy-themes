# {{ display_name }}: laptop-first visual language — compact and sharp.
$activeBorderColor = rgba({{ accent_strip }}dd) rgba({{ border_gradient_strip }}dd) 35deg

general {
    col.active_border = $activeBorderColor
    col.inactive_border = rgba({{ border_strip }}88)
    gaps_in = {{ hypr_gaps_in }}
    gaps_out = {{ hypr_gaps_out }}
    border_size = {{ hypr_border_size }}
}

group {
    col.border_active = $activeBorderColor
}

decoration {
    rounding = {{ hypr_rounding }}

    shadow {
        enabled = yes
        range = 12
        render_power = 3
        color = rgba(00000066)
    }

    blur {
        enabled = true
        size = 6
        passes = 3
    }
}

# Waybar glass: blur the bar's translucent box; skip fully transparent
# pixels (the bottom-margin strip and window#waybar's transparent bg).
layerrule = blur on, match:namespace waybar
layerrule = ignore_alpha 0.3, match:namespace waybar

# Terminals: frosted glass, deeper than the Omarchy default (0.985/0.96).
# Omarchy tags terminals in default/hypr/apps/terminals.conf; this theme file
# is sourced after it, so this later rule wins for the same property.
windowrule = opacity 0.90 0.82, match:tag terminal
