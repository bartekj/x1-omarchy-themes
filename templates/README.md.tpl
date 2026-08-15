# {{ display_name }}

{{ description }}

Part of the X1 theme family for Omarchy (X1 / Graphite / Redline / Stealth).
Waybar is arranged as a compact cockpit: workspaces and controls on the left,
a prominent clock in the center, hardware status on the right, and an X1 theme
switcher that cycles the family. Click the clock for a terminal calendar.

| Token | Value |
| --- | --- |
| accent | `{{ accent }}` |
| background | `{{ background }}` |
| foreground | `{{ foreground }}` |

Set it with:

```bash
omarchy theme set {{ slug }}
```

**Generated file — do not edit by hand.** This theme is built from a single
source of truth in `~/Projects/x1-omarchy-themes` (`palettes/{{ slug }}.toml`
plus shared templates). Edit the palette there and re-run `./build.sh &&
./install.sh`.
