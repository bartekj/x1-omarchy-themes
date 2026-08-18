# {{ display_name }}

{{ description }}

Part of the X1 theme family for Omarchy 4 (X1 / Graphite / Redline / Stealth / Ember).
The omarchy-shell bar, launcher, notifications, and lock screen pick up the
variant's glass identity through `shell.<section>.toml` overrides; window
borders, gaps, and rounding come from the theme's `hyprland.lua`.

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
