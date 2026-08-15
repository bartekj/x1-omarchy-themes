# {{ display_name }}: laptop-first visual language — compact and sharp.
$activeBorderColor = rgba({{ accent_strip }}dd) rgba({{ border_gradient_strip }}dd) 35deg

general {
    col.active_border = $activeBorderColor
    col.inactive_border = rgba({{ border_strip }}88)
    gaps_in = 3
    gaps_out = 5
    border_size = 2
}

group {
    col.border_active = $activeBorderColor
}

decoration {
    rounding = 3

    shadow {
        enabled = yes
        range = 12
        render_power = 3
        color = rgba(00000066)
    }

    blur {
        enabled = true
        size = 3
        passes = 2
    }
}
