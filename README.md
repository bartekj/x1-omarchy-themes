# X1 theme family for Omarchy

Four dark ThinkPad-inspired variants generated from a single source of truth:

| Variant | Character | Accent |
| --- | --- | --- |
| `x1` | Matte graphite, TrackPoint-red accents | `#c21f30` |
| `x1-graphite` | Brighter surfaces for daylight | `#9a6a70` |
| `x1-redline` | TrackPoint-forward, clearer red | `#d12736` |
| `x1-stealth` | Near-black, neutral accents | `#7d8792` |

## Layout

```
palettes/<variant>.toml   single source of truth (~45 tokens per variant)
templates/*.tpl           11 shared templates, Omarchy {{ key }} syntax
waybar/                   installed OUTSIDE the themes:
  waybar.css.tpl            -> ~/.config/omarchy/themed/  (stock-theme compat)
  x1-theme-status/next/select -> ~/.config/waybar/scripts/  (variant switcher)
assets/source/BG1.png     shared original wallpaper (tinted per variant)
build/                    output (gitignored)
```

## Usage

```bash
./build.sh     # render templates + generate wallpapers/previews into build/
./install.sh   # copy build/* into ~/.config/omarchy/themes/ + waybar layer
omarchy theme set x1-stealth   # or x1 / x1-redline / x1-graphite
```

Never edit `~/.config/omarchy/themes/x1*` by hand — edit a palette (or a
template) here and rebuild. `omarchy-theme-refresh` is the fast dev loop.

## Custom wallpapers

Two routes:

- **Route A (no rebuild):** drop images into
  `~/.config/omarchy/backgrounds/<variant>/` — Omarchy cycles them natively,
  sorted before the theme's own backgrounds.
- **Route B (versioned):** drop images into `assets/backgrounds/<variant>/`
  (or `assets/backgrounds/all/` for every variant). `./build.sh` then ships
  them **instead of** the generated carbon-weave/heritage set.

## Token contract

- The 22 `colors.toml` keys (accent, cursor, foreground, background,
  selection_*, color0..15) feed Omarchy's stock templates (alacritty, btop,
  kitty, ghostty, foot, helix, chromium, ...).
- The waybar cockpit (`~/.config/waybar/style.css`) consumes 21 custom
  `@define-color` names, all defined in each variant's `waybar.css`.
  `@healthy` and `@surface-raised` are currently unused by style.css —
  **reserved** (healthy = battery-good/status-ok states, surface-raised =
  popover surfaces). Keep them defined.
- Conventions enforced by the templates:
  - `border` = waybar hairlines + Hyprland inactive border (`88` alpha);
    `border_soft` = chrome borders (mako, swayosd, walker) + waybar washes.
  - mako `[urgency=critical]` = `color9` everywhere; `accent` never means
    error. ANSI `color1`/`color9` stay semantically red in every variant.
  - Hyprland active border: `accent` -> `border_gradient` at `dd` alpha, 35deg.
  - `accent` is a standalone identity token (borders, walker focus, swayosd
    progress, waybar accent); it happens to equal `color1` in x1/redline only.

## Stock-theme compatibility

`waybar/waybar.css.tpl` (installed to `~/.config/omarchy/themed/`) maps the
21-var contract onto the keys every theme's `colors.toml` provides, so
switching to a stock theme (tokyo-night, catppuccin, ...) no longer breaks the
bar. X1 variants override it by shipping their exact `waybar.css`.

## Gotchas learned the hard way

- waybar 0.15 exits (code 1) on ANY fatal CSS parse error — web-only
  properties like `font-variant-numeric` or `max-width` kill it silently.
  Use `font-feature-settings: "tnum"` and the module's `max-length` instead.
- `omarchy-theme-set-vscode` strips `workbench.colorTheme` when a theme has
  no `vscode.json`; `"extension": ""` cleanly selects a built-in VS Code theme.
- Themes without `neovim.lua` leave `~/.config/nvim/lua/plugins/theme.lua`
  dangling. Each variant renders its exact 16 colors via RRethy/base16-nvim.
