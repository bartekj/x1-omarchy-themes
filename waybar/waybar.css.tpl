/*
 * Stock-theme compatibility layer for the X1 waybar cockpit.
 * Installed as ~/.config/omarchy/themed/waybar.css.tpl — rendered by
 * omarchy-theme-set-templates for ANY theme that does not ship its own
 * waybar.css (all X1 variants do, so they override this file).
 *
 * ~/.config/waybar/style.css consumes 21 custom @define-color names plus a
 * "shapes & transparency" section that lives in the theme file; stock Omarchy
 * themes define only foreground/background. This template maps the full
 * contract onto the keys every colors.toml provides, with FIXED shape values
 * (the pre-glass look): stock themes lack the waybar blur layerrule (it lives
 * in the X1 themes' hyprland.conf), so a translucent bar would be unreadable
 * glass-with-no-glass. Surfaces flatten a little on stock themes (color0 is
 * often close to background) — acceptable; the bar renders instead of
 * breaking.
 */
@define-color background {{ background }};
@define-color surface {{ color0 }};
@define-color surface-raised {{ selection_background }};
@define-color surface-hover {{ selection_background }};
@define-color surface-active {{ selection_background }};
@define-color clock-bg {{ color0 }};
@define-color workspace-active {{ selection_background }};
@define-color resource-bg {{ color0 }};
@define-color foreground {{ foreground }};
@define-color muted {{ color8 }};
@define-color border {{ selection_background }};
@define-color border-soft {{ color8 }};
@define-color accent {{ accent }};
@define-color accent-dim {{ color8 }};
@define-color warning {{ color3 }};
@define-color healthy {{ color2 }};
@define-color critical {{ color9 }};
@define-color resource-cpu {{ color4 }};
@define-color resource-memory {{ color10 }};
@define-color resource-temp {{ color11 }};
@define-color resource-disk {{ color13 }};
@define-color transparent rgba(0, 0, 0, 0);

/* shapes & transparency — fixed defaults for stock themes (no waybar
   blur layerrule outside the X1 family, so keep the bar near-opaque) */
window#waybar > box {
  background: alpha(@background, 0.95);
  border-bottom: 1px solid alpha(@border-soft, 0.8);
  box-shadow: 0 5px 16px alpha(#000000, 0.42);
}

#launcher,
#indicators,
#theme,
#connectivity,
#resources,
#power,
#tray,
#mpris,
#privacy {
  background: alpha(@surface, 0.92);
  border: 1px solid alpha(@border-soft, 0.86);
  border-radius: 5px;
}

#resources {
  background: alpha(@resource-bg, 0.9);
}

#workspaces {
  background: alpha(@surface, 0.72);
  border: 1px solid alpha(@border-soft, 0.72);
  border-radius: 5px;
}

#workspaces button {
  border-radius: 4px;
}

#clock {
  border: 1px solid alpha(@border-soft, 0.92);
  border-radius: 6px;
}
