@define-color background {{ background }};
@define-color surface {{ surface }};
@define-color surface-raised {{ surface_raised }};
@define-color surface-hover {{ surface_hover }};
@define-color surface-active {{ surface_active }};
@define-color clock-bg {{ clock_bg }};
@define-color workspace-active {{ workspace_active }};
@define-color resource-bg {{ resource_bg }};
@define-color foreground {{ foreground }};
@define-color muted {{ muted }};
@define-color border {{ border }};
@define-color border-soft {{ border_soft }};
@define-color accent {{ accent }};
@define-color accent-dim {{ accent_dim }};
@define-color warning {{ warning }};
@define-color healthy {{ healthy }};
@define-color critical {{ critical }};
@define-color resource-cpu {{ resource_cpu }};
@define-color resource-memory {{ resource_memory }};
@define-color resource-temp {{ resource_temp }};
@define-color resource-disk {{ resource_disk }};
@define-color transparent rgba(0, 0, 0, 0);

/* ---- shapes & transparency: per-variant identity -------------------- */
/* These declarations were REMOVED from ~/.config/waybar/style.css.      */
/* style.css is imported after this file — a duplicate there wins.       */

window#waybar > box {
  background: alpha(@background, {{ bar_alpha }});
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
  background: alpha(@surface, {{ pill_alpha }});
  border: 1px solid alpha(@border-soft, {{ pill_border_alpha }});
  border-radius: {{ pill_radius }}px;
}

/* must follow the pill rule: same specificity, later wins */
#resources {
  background: alpha(@resource-bg, {{ pill_alpha }});
}

#workspaces {
  background: alpha(@surface, {{ ws_alpha }});
  border: 1px solid alpha(@border-soft, {{ pill_border_alpha }});
  border-radius: {{ pill_radius }}px;
}

#workspaces button {
  border-radius: {{ btn_radius }}px;
}

#clock {
  border: 1px solid alpha(@border-soft, {{ pill_border_alpha }});
  border-radius: {{ pill_radius }}px;
}
