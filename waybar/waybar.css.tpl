/*
 * Stock-theme compatibility layer for the X1 waybar cockpit.
 * Installed as ~/.config/omarchy/themed/waybar.css.tpl — rendered by
 * omarchy-theme-set-templates for ANY theme that does not ship its own
 * waybar.css (all X1 variants do, so they override this file).
 *
 * ~/.config/waybar/style.css consumes 21 custom @define-color names; stock
 * Omarchy themes define only foreground/background. This template maps the
 * full contract onto the keys every colors.toml provides. Surfaces flatten a
 * little on stock themes (color0 is often close to background) — acceptable;
 * the bar renders instead of breaking.
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
