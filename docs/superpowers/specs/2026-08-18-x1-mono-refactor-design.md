# X1 mono refactor — design

Date: 2026-08-18
Status: approved (direction confirmed interactively; each decision below was
picked explicitly by Bart)

## Problem

The theme family has drifted into a multi-hue pastel system (sage green, sand,
steel blue, violet) that no longer reads as "ThinkPad X1". Concretely, on the
live desktop (x1-graphite active):

- The `sparkwide` readout renders a steady value as a solid filled block (RAM
  at ~62%) or a flat line (disk), so the four cells read inconsistently — one
  looks like a graph, one like a brick, one like nothing.
- Charts are painted in the *level* color (green/orange/red), and the
  graphite "orange" is a sandy brown `#c99a68` — muddy on a transparent bar
  over a dark wallpaper. Four cells can glow in four hues at once.
- Glitch dividers add red micro-accents right next to the charts: noise.
- The bar is fully transparent; widgets sit on raw wallpaper (a light streak
  crosses the bar and hurts legibility).
- The inactive window border (`border` @ `88` alpha) is nearly invisible.
- Every variant ships different gaps/rounding (stealth r1/2/4 … ember
  r10/5/10), which reads as inconsistency rather than identity.
- The widget style matrix (11 frame styles × 6 dividers × 5 readouts + a
  fragment shader) is far larger than what is actually on screen.

## Decisions (locked)

1. **Color direction: monochrome + accent.** UI chrome (bar, shell surfaces,
   window borders, widgets) uses a graphite ramp only; color appears only as
   the variant accent and semantically (`critical`).
2. **Variants keep their accent identity** on a shared mono base:
   x1 `#c82031`, graphite `#ce2835`, redline `#d12736`, stealth steel
   `#7d8792`, ember amber `#d9a05b`. `critical` stays red in *every* variant.
3. **Charts become `columns`** — a mini bar-chart of history (gapped columns,
   absolute 0–100% scale). Gaps between columns make a steady value read as
   an even chart, not a solid block.
4. **Bar becomes graphite glass** — filled mode by default, `bar_alpha` ≈ 0.5,
   existing blur layer rule.
5. **One compact geometry for the whole family**: `gaps_in 4 / gaps_out 8 /
   rounding 5 / border 2px`; inactive border made clearly visible.
6. **Dividers calm down**: graphite `hairline` default (+ `tick` without its
   red node); no red micro-accents.
7. **Prune the style matrix to what is used.** Readouts `text|meter|columns`;
   dividers `hairline|tick`; frames `none|flat|bloom`. The fragment shader
   (`card.frag`, `.qsb`, the qsb build step) is deleted — `flat` is a plain
   Rectangle and `bloom` is already QML.

## 1. Palette system

Token structure stays; values and one name change. All five palettes keep the
same schema so templates stay shared.

### Token rename: `border_gradient` → `accent_dim`

The steel-blue gradient stop leaves the system. The active-border (and every
place that echoed it) instead deepens the variant's own accent:

| Variant  | accent    | accent_dim (start point) |
| -------- | --------- | ------------------------ |
| x1       | `#c82031` | `#6e1a22`                |
| graphite | `#ce2835` | `#75202a`                |
| redline  | `#d12736` | `#7a1f2b`                |
| stealth  | `#7d8792` | `#454e57`                |
| ember    | `#d9a05b` | `#7c5c36`                |

`accent_dim` ≈ the accent at roughly 40% of its lightness, same hue. Values
above are starting points; final values are tuned visually and must pass
`tools/contrast-audit`.

Templates that reference `border_gradient` (`colors.toml.tpl`,
`shell.controls.toml.tpl`, `hyprland.lua.tpl`, any shell.\* override) switch
to `accent_dim`. `build.sh`'s `*_strip` derivation follows the rename.

### Border tokens

- `hyprland_active_border` = `accent` → `accent_dim`, both at `dd`, 35deg
  (depth without a foreign hue).
- `hyprland_inactive_border` = `border` at `aa` (was `88`); if a variant's
  `border` still vanishes on its background, lighten the `border` token —
  target: clearly visible at a glance, quieter than active.

### ANSI ramp

`color0..15` are terminal *content*, not chrome — syntax highlighting needs
distinguishable hues. The ANSI ramp is already muted and stays **unchanged**
in this refactor. The mono mandate applies to UI chrome only. (Revisit later
if the terminal feels off next to the mono shell.)

### Bar level colors

`x1-bar-stats` stops resolving `green|orange|bright_red` and resolves:

- ok → `muted` (fallback `#9199a3`)
- warn → `foreground` (fallback `#d9dde3`)
- crit → `bright_red` (fallback `#e06c75`)

So the cluster idles in gray, *brightens to white* on warning, and only goes
red on critical. Icon tint and chart color both follow automatically since
they consume `stats.colors`.

## 2. Window geometry (all five palettes)

```
hypr_gaps_in     4
hypr_gaps_out    8
hypr_rounding    5
hypr_border_size 2
```

Stealth gives up r1/1px, ember gives up r10 — variants differ by color only.
`Style.cornerRadius` in the shell tracks `hyprctl decoration:rounding`, so
shell cards follow to r5 with no extra work. Shadow, blur, and the terminal
frosted glass (`0.90 0.82`) stay as they are.

## 3. Bar surface

- `bar_alpha` = `0.50` in all palettes (was 0.20–0.32; imperceptible).
- Default mode = **filled**. The `"transparent"` flag lives in the user's
  `~/.config/omarchy/shell.json` (toggled by double-clicking empty bar
  space), which themes must not overwrite — flipping it back to filled is a
  documented one-time manual step, not an install.sh action.

## 4. Resources cluster

### New readout: `columns` (default)

- 10 columns, 2px wide, 1px gap → 29px canvas, 12px tall, vertically
  centered next to the value text (layout as `sparkwide` had it).
- Data: the newest 10 samples of the existing history (historyLen stays 24),
  right-aligned — newest column at the right edge; missing samples draw
  nothing (no zero-height ghosts while history fills).
- Absolute scale: 0–100% (temp keeps its 35–95 °C normalization). Minimum
  visible column height 1px so a near-zero sample still shows a base mark.
- Color: `textColor` (barForeground) at 0.75 alpha; when the cell's level is
  2 (critical) the whole column set switches to the crit color at 0.9. No
  per-column level coloring.
- Implementation: a `Row`/`Repeater` of `Rectangle`s bound to the history
  tail (declarative, no Canvas repaint plumbing).

Removed readouts: `spark`, `sparkwide`, `segments` (and `SparkCanvas`).
Kept: `text`, `meter`, `columns`. Unknown/stale `readoutStyle` values from
user `shell.json` fall back to `columns` (the switch default).

### Dividers

Kept: `hairline` (new default) and `tick`. The tick's accent node recolors to
`lineColor` — no red micro-accents. Removed: `glitch`, `slash`, `chevron`,
`bars`, plus the now-unused `meterValue`/`meterColor` properties and the
`CellSeparator` meter wiring in `BarWidget.qml`. Unknown values fall back to
`hairline`.

### Card frames

Kept: `none` (default), `flat`, `bloom`. Removed: the eight shader styles,
the `ShaderEffect` block, `card.frag`, both committed `card.frag.qsb` copies,
and the qsb compile step in `tools/build-plugin-shared` (which becomes a pure
copy script and loses its qt6-shadertools dependency). `lensBulge` /
`lensSpecular` settings disappear from both manifests and both BarWidgets.
Unknown `frameStyle` values fall back to `none`.

`bloom` keeps its current behavior (worst-level halo on resources, steady
halo on media); with the new level ramp its idle halo is graphite and it
only ever colors red at critical — consistent with the mono rules.

### manifest.json (both plugins)

Settings enums shrink to the kept styles; defaults update
(`readoutStyle: columns`, `dividerStyle: hairline`, `frameStyle: none`).

## 5. Media widget

- Stays frameless with the source glyph; no color changes needed
  (`barForeground`-driven already).
- The hard `clip: true` edge on the scrolling title is replaced with a
  horizontal fade-out at both clip edges via `MultiEffect` mask (pure QML,
  no shader file). If the mask proves visually or performance-wise worse in
  practice, keep the hard clip — this is polish, not structure.

## 6. Other surfaces (template pass)

- `shell.controls.toml.tpl`: three-step story becomes idle = `border_soft`
  hairline, hover/focus = `accent_dim`, selected = `accent` (same alphas).
- `shell.launcher/menu/notifications/popups/tooltip/lock`: token-driven —
  they inherit the mono palette; only `border_gradient` references rename.
- `templates/README.md.tpl` + root `README.md`: style tables shrink to the
  kept sets; border-system section drops the shader paragraphs and the
  steel-blue gradient description.
- neovim / vscode / icons: structurally unchanged (render from the same 16
  colors).
- Wallpapers: `bg_tint` / weave knobs unchanged; previews regenerate on
  build.

## 7. Verification

Per palette change: `tools/contrast-audit` must pass for all five palettes.
Per visual change: `./build.sh && ./install.sh`, `omarchy-restart-shell`,
then a `grim` screenshot reviewed for: bar glass legibility, columns shape
(steady RAM must read as an even chart), divider quietness, active/inactive
border visibility, uniform gaps. `hyprctl getoption general:gaps_in` (etc.)
confirms geometry landed.

## Out of scope

- ANSI ramp retune (deliberately deferred).
- Any change to detail panels' content or `x1-bar-detail`.
- The weather plugin patch flow.
- install.sh touching user `shell.json`.
