# X1 Mono Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the X1 theme family to a monochrome-graphite + per-variant-accent system: mono palettes, unified window geometry, graphite-glass bar, `columns` chart readout, quiet dividers, and a pruned widget style matrix (shader deleted).

**Architecture:** Five TOML palettes render through shared templates into `build/<variant>/` (build.sh sed renderer, byte-compatible with Omarchy's); two Quickshell plugins (`bart.resources`, `bart.media`) share QML from `bar/shared/` fanned out by `tools/build-plugin-shared`. This plan renames one palette token (`border_gradient` → `accent_dim`), retunes palette values, unifies geometry, rewrites three shared QML components, and deletes the fragment-shader path entirely.

**Tech Stack:** Bash (build/install/stats scripts), TOML palettes, Omarchy `{{ key }}` templates, QML/QtQuick (Quickshell plugins), ImageMagick (asset generation), Python (contrast audit).

**Spec:** `docs/superpowers/specs/2026-08-18-x1-mono-refactor-design.md`

## Global Constraints

- Unified geometry in ALL five palettes: `hypr_gaps_in = "4"`, `hypr_gaps_out = "8"`, `hypr_rounding = "5"`, `hypr_border_size = "2"`, `bar_alpha = "0.50"`.
- Token rename is total: after Task 1, `grep -rn border_gradient` over `palettes/ templates/ build.sh` must return nothing.
- `critical` stays red in every variant; `accent` never means error.
- ANSI ramp `color0..15` is out of scope — do not touch it.
- `tools/contrast-audit` must pass (exit 0) after every palette edit.
- Kept style sets: readouts `columns|meter|text` (default `columns`); dividers `hairline|tick` (default `hairline`); frames `none|flat|bloom` (default `none`). Unknown values from stale user `shell.json` must fall back to the default, never error.
- Never edit `bar/plugins/*/CardFrame.qml`, `CellDivider.qml`, `CellReadout.qml` by hand — edit `bar/shared/` and run `./tools/build-plugin-shared`.
- Editing plugin QML requires `omarchy-restart-shell` to take effect (the component cache survives config reloads). `omarchy-refresh-shell` is a config RESET — never run it.
- `~/.config/omarchy/shell.json` is user config: `install.sh` must never write it. The one-time transparent→filled flip happens only in Task 8, as an explicit local edit.
- This machine runs the theme live: after visual tasks, verify with a `grim` screenshot (crop the bar region and read it — the bar is ~36px on a 3840x1200 screen).
- Commit after every task; message style follows the repo's short imperative subject lines.

---

### Task 1: Palettes + templates — `accent_dim` rename, mono values, unified geometry, bar glass

**Files:**
- Modify: `palettes/x1.toml`, `palettes/x1-graphite.toml`, `palettes/x1-redline.toml`, `palettes/x1-stealth.toml`, `palettes/x1-ember.toml`
- Modify: `build.sh` (REQUIRED_KEYS list, line 18)
- Modify: `templates/colors.toml.tpl` (lines 34–38)
- Modify: `templates/hyprland.lua.tpl` (line 2)
- Modify: `templates/shell.controls.toml.tpl` (lines 1–2, 12, 18)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: palette key `accent_dim` (replaces `border_gradient`) available to all templates as `{{ accent_dim }}` / `{{ accent_dim_strip }}`; unified `hypr_*` values; `bar_alpha = "0.50"`. Rendered `colors.toml` keys `hyprland_active_border` / `hyprland_inactive_border` keep their names (external contract with Omarchy).

- [ ] **Step 1: Edit the five palettes**

In each palette, in the `# lines & emphasis` block, replace the `border_gradient` line with `accent_dim`, and replace the whole `# shape & glass identity` block. Per variant:

`palettes/x1.toml`:
```toml
accent_dim = "#6e1a22"
```
`palettes/x1-graphite.toml`:
```toml
accent_dim = "#75202a"
```
`palettes/x1-redline.toml`:
```toml
accent_dim = "#7a1f2b"
```
`palettes/x1-stealth.toml`:
```toml
accent_dim = "#454e57"
```
`palettes/x1-ember.toml`:
```toml
accent_dim = "#7c5c36"
```

Shape & glass block, IDENTICAL in all five palettes (replace existing values; keep the `pill_alpha` / `pill_border_alpha` lines each variant already has, unchanged):
```toml
bar_alpha = "0.50"
hypr_rounding = "5"
hypr_gaps_in = "4"
hypr_gaps_out = "8"
hypr_border_size = "2"
```

Also update each palette's header comment where it mentions steel/blue gradients (x1: no change needed beyond the token; keep comments truthful).

- [ ] **Step 2: Update build.sh required keys**

In `build.sh` line 18, change:
```bash
  muted border border_soft border_gradient
```
to:
```bash
  muted border border_soft accent_dim
```

- [ ] **Step 3: Update templates**

`templates/colors.toml.tpl` — replace lines 34–38 with:
```
# X1 border identity: accent -> accent_dim at dd alpha, 35deg — the variant's
# own accent deepened, no foreign hue. Inactive = border at aa alpha (must be
# clearly visible at a glance, quieter than active). Consumed by Omarchy's
# stock hyprland.lua.tpl and the shell.toml [hyprland] tokens.
hyprland_active_border = "rgba({{ accent_strip }}dd) rgba({{ accent_dim_strip }}dd) 35deg"
hyprland_inactive_border = "rgba({{ border_strip }}aa)"
```

`templates/hyprland.lua.tpl` — replace line 2 with:
```lua
local active_border_color = { colors = { "rgba({{ accent_strip }}dd)", "rgba({{ accent_dim_strip }}dd)" }, angle = 35 }
```

`templates/shell.controls.toml.tpl` — replace the header comment (lines 1–2) with:
```
# {{ display_name }} controls: three-step border story — idle hairline
# (border_soft), interaction dimmed accent (accent_dim), committed accent.
```
and replace `"{{ border_gradient }}"` with `"{{ accent_dim }}"` on the `hover-cursor-border` and `focus-border` lines.

- [ ] **Step 4: Verify rename is total and audit passes**

Run: `grep -rn border_gradient palettes/ templates/ build.sh; echo "exit=$?"`
Expected: no matches, `exit=1`.

Run: `./tools/contrast-audit`
Expected: `all palettes pass`, exit 0. (The audit never referenced `border_gradient`, so only the unchanged pairs are checked — they must still pass.)

- [ ] **Step 5: Verify a clean build**

Run: `./build.sh`
Expected: `built: build/<name>` for all five variants, `OK: 5 variant(s) built`, no `unresolved placeholders` error.

Run: `grep -h hyprland_active_border build/*/colors.toml`
Expected: five lines, each `rgba(<accent>dd) rgba(<accent_dim>dd) 35deg` with the variant's own accent pair (e.g. x1: `rgba(c82031dd) rgba(6e1a22dd) 35deg`).

Run: `grep -h "gaps_in\|gaps_out\|rounding" build/*/hyprland.lua`
Expected: every variant shows `gaps_in = 4`, `gaps_out = 8`, `rounding = 5`.

- [ ] **Step 6: Commit**

```bash
git add palettes/ templates/colors.toml.tpl templates/hyprland.lua.tpl templates/shell.controls.toml.tpl build.sh
git commit -m "Mono palettes: accent_dim replaces steel gradient, unified geometry, glass bar"
```

---

### Task 2: `x1-bar-stats` — mono level ramp (gray → white → red)

**Files:**
- Modify: `bar/scripts/x1-bar-stats:91-93`

**Interfaces:**
- Consumes: `omarchy-theme-color <key> <fallback>` (verified working for `muted`, `foreground`, `bright_red` on this machine).
- Produces: the stats JSON `colors` array becomes `[muted, foreground, bright_red]` — consumed by `BarWidget.qml` as `levelColors[0..2]` (icon tint + chart color). Task 4 relies on index 2 being the only saturated color.

- [ ] **Step 1: Change the level color resolution**

Replace lines 91–93 of `bar/scripts/x1-bar-stats`:
```bash
ok=$(omarchy-theme-color green '#7fbf7f')
warn=$(omarchy-theme-color orange '#d19a66')
crit=$(omarchy-theme-color bright_red '#e06c75')
```
with:
```bash
# Mono ramp: the cluster idles in gray, brightens to the foreground on
# warning, and only goes red at critical. Accent never means error and
# green/orange never appear in the bar.
ok=$(omarchy-theme-color muted '#9199a3')
warn=$(omarchy-theme-color foreground '#d9dde3')
crit=$(omarchy-theme-color bright_red '#e06c75')
```

- [ ] **Step 2: Verify the JSON**

Run: `bash bar/scripts/x1-bar-stats | python3 -m json.tool | grep -A4 colors`
Expected: a `colors` array of three hex strings where entry 0 = the active theme's `muted` (currently `#a2aab3` for x1-graphite), entry 1 = `foreground` (`#e4e7ea`), entry 2 = `bright_red` (`#e0555f`).

- [ ] **Step 3: Install and commit**

The script is read from `~/.config/omarchy/bar/scripts/` at runtime; copy it:
Run: `install -Dm755 bar/scripts/x1-bar-stats ~/.config/omarchy/bar/scripts/x1-bar-stats`
The bar picks it up on the next 2s tick — the resource icons should turn gray/white within seconds (no restart needed; the script is re-executed each tick).

```bash
git add bar/scripts/x1-bar-stats
git commit -m "Bar level ramp goes mono: muted -> foreground -> red"
```

---

### Task 3: `CellReadout` — add `columns`, remove spark/segments

**Files:**
- Modify: `bar/shared/CellReadout.qml` (full rewrite below)
- Regenerated: `bar/plugins/bart.resources/CellReadout.qml` (via tools/build-plugin-shared — never by hand)

**Interfaces:**
- Consumes: `history` (oldest→newest array of 0..1 reals) and `levelColor` exactly as the host already binds them.
- Produces: `readoutStyle` accepts `"columns" | "meter" | "text"`, anything else falls back to columns. NEW property `property int level: 0` (host may bind it; unbound ⇒ columns never go red, which is safe). Removed: `spark`, `sparkwide`, `segments` modes and the `SparkCanvas` component.

- [ ] **Step 1: Rewrite bar/shared/CellReadout.qml**

Full new file content:

```qml
import QtQuick
import qs.Commons

// How a single resource cell states its value.
//
//   columns  the number, then a mini bar-chart of history (default)
//   meter    the number with a progress rule under it
//   text     the padded number, as the cluster has always shown it
//
// columns keeps the digits: a graph alone shows trend but loses the reading,
// and at bar size the reading is what you actually glance for. The gaps
// between the columns are what keep a steady value reading as an even chart
// rather than a solid block — the failure mode that killed the sparkline.
//
// Every mode keeps a fixed width. The value text is space-padded upstream, so
// nothing in the row shifts as 2% becomes 100%.
//
// Source of truth: bar/shared/CellReadout.qml. Copied into the plugin by
// tools/build-plugin-shared — do not edit the copy.
Item {
  id: root

  property string readoutStyle: "columns"
  property string value: ""
  // 0..1, already normalised by the host — temperature is not a percentage.
  property real fraction: 0
  // Oldest-to-newest normalised samples; only columns reads it.
  property var history: []
  // 0 ok / 1 warn / 2 crit from x1-bar-stats. The chart goes red only at 2;
  // levels 0 and 1 stay graphite — the icon already carries the warning.
  property int level: 0

  property color textColor: "white"
  property color levelColor: "white"
  property string fontFamily: "monospace"
  property real fontSize: 12

  // Chart geometry: columnCount columns of columnWidth px with columnGap px
  // of light between them, newest sample at the right edge.
  property int columnCount: 10
  readonly property real columnWidth: 2
  readonly property real columnGap: 1

  implicitWidth: loader.item ? loader.item.implicitWidth : 0
  implicitHeight: loader.item ? loader.item.implicitHeight : fontSize

  readonly property real clamped: Math.max(0, Math.min(1, fraction))

  Loader {
    id: loader
    anchors.centerIn: parent
    sourceComponent: switch (root.readoutStyle) {
      case "meter": return meterMode
      case "text": return textMode
      default: return columnsMode
    }
  }

  Component {
    id: textMode

    Text {
      text: root.value
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
  }

  // The number, underlined by how full it is.
  Component {
    id: meterMode

    Item {
      implicitWidth: label.implicitWidth
      implicitHeight: label.implicitHeight + 4

      Text {
        id: label
        text: root.value
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
      }

      Rectangle {
        y: label.implicitHeight + 2
        width: parent.width
        height: 1.5
        color: Qt.alpha(root.textColor, 0.14)

        Rectangle {
          width: parent.width * root.clamped
          height: parent.height
          color: root.levelColor

          Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
          }
          Behavior on color {
            ColorAnimation { duration: 300 }
          }
        }
      }
    }
  }

  // The number, then the history as a row of gapped columns on an absolute
  // 0..1 scale. Slots older than the history draw nothing, so the chart
  // grows in from the right after a shell restart instead of showing
  // zero-height ghosts for samples that never happened.
  Component {
    id: columnsMode

    Row {
      spacing: 4

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
      }

      Item {
        id: chart
        anchors.verticalCenter: parent.verticalCenter
        width: root.columnCount * (root.columnWidth + root.columnGap) - root.columnGap
        height: 12

        Repeater {
          model: root.columnCount

          Rectangle {
            // Slot columnCount-1 holds the newest sample. history is
            // reassigned wholesale each tick, so these bindings re-evaluate.
            readonly property int sampleIndex: root.history.length - root.columnCount + index
            readonly property real sample: sampleIndex >= 0 && sampleIndex < root.history.length
              ? Math.max(0, Math.min(1, root.history[sampleIndex])) : -1

            x: index * (root.columnWidth + root.columnGap)
            y: chart.height - height
            width: root.columnWidth
            // A near-zero sample still shows a 1px base mark; a missing
            // sample shows nothing at all.
            height: sample < 0 ? 0 : Math.max(1, Math.round(sample * chart.height))
            visible: sample >= 0
            color: root.level >= 2 ? Qt.alpha(root.levelColor, 0.9)
                                   : Qt.alpha(root.textColor, 0.75)

            Behavior on color {
              ColorAnimation { duration: 300 }
            }
          }
        }
      }
    }
  }
}
```

- [ ] **Step 2: Fan out to the plugin**

Run: `./tools/build-plugin-shared`
Expected: exits 0, lists `bar/plugins/bart.resources` under cells. (The shader step still exists at this point — that's fine, it goes away in Task 5.)

- [ ] **Step 3: Install and restart the shell**

Run: `./install.sh && omarchy-restart-shell`
Expected: install lists both plugins; shell restarts without error.

- [ ] **Step 4: Visual verification**

Wait ~30s for history to accumulate, then:
Run: `grim /tmp/claude-*/**/scratchpad/task3-bar.png` (use the session scratchpad path), crop the right third of the bar at 300% zoom with `magick`, and read the image.
Expected: each of the four cells shows number + a row of thin gray columns growing in from the right; a steady RAM value reads as an even comb of equal columns, NOT a solid block; no green/orange anywhere (Task 2 already landed the mono ramp).

- [ ] **Step 5: Commit**

```bash
git add bar/shared/CellReadout.qml bar/plugins/bart.resources/CellReadout.qml
git commit -m "Columns readout replaces sparklines; prune spark/segments modes"
```

---

### Task 4: `CellDivider` + resources wiring — quiet hairline/tick, prune the rest

**Files:**
- Modify: `bar/shared/CellDivider.qml` (full rewrite below)
- Modify: `bar/plugins/bart.resources/BarWidget.qml` (CellSeparator, readout defaults, level binding, levelColors fallback)
- Modify: `bar/plugins/bart.resources/manifest.json` (dividerStyle + readoutStyle entries)
- Regenerated: `bar/plugins/bart.resources/CellDivider.qml` (via tools/build-plugin-shared)

**Interfaces:**
- Consumes: `CellReadout.level` (added in Task 3).
- Produces: `CellDivider` keeps only `dividerStyle` (`"hairline"` default, `"tick"`), `lineColor`, `markHeight`. REMOVED properties: `accentColor`, `meterValue`, `meterColor` — any host still assigning them would error, so the host changes in the same commit.

- [ ] **Step 1: Rewrite bar/shared/CellDivider.qml**

Full new file content:

```qml
import QtQuick
import qs.Commons

// Cell dividers for the resources readout.
//
// With frameStyle "none" there is no container at all, so these marks are
// the only thing giving the cluster structure. In the mono system they stay
// quiet: graphite only, no accent — the chart columns are the loudest thing
// in the cluster and these must not compete.
//
//   hairline the 1px rule (default)
//   tick     instrument I-beam: capped stem with a centre node
//
// Source of truth: bar/shared/CellDivider.qml. Copied into the plugin by
// tools/build-plugin-shared — do not edit the copy.
Item {
  id: root

  property string dividerStyle: "hairline"
  property color lineColor: "white"
  // Nominal height of the mark; the old hairline rule was 14.
  property real markHeight: 14

  implicitWidth: loader.item ? loader.item.implicitWidth : 1
  implicitHeight: markHeight
  anchors.verticalCenter: parent ? parent.verticalCenter : undefined

  Loader {
    id: loader
    anchors.centerIn: parent
    sourceComponent: root.dividerStyle === "tick" ? tickMark : hairlineMark
  }

  // An instrument tick: capped stem with a node on the axis — all graphite.
  Component {
    id: tickMark

    Item {
      implicitWidth: 5
      implicitHeight: root.markHeight

      Rectangle {
        x: 2; y: 2
        width: 1; height: root.markHeight - 4
        color: Qt.alpha(root.lineColor, 0.35)
      }
      Rectangle {
        x: 0; y: 1
        width: 5; height: 1
        color: Qt.alpha(root.lineColor, 0.6)
      }
      Rectangle {
        x: 0; y: root.markHeight - 2
        width: 5; height: 1
        color: Qt.alpha(root.lineColor, 0.6)
      }
      Rectangle {
        x: 1.5; y: root.markHeight / 2 - 1
        width: 2; height: 2
        color: Qt.alpha(root.lineColor, 0.9)
      }
    }
  }

  Component {
    id: hairlineMark

    Rectangle {
      implicitWidth: 1
      implicitHeight: root.markHeight
      width: 1
      height: root.markHeight
      color: Qt.alpha(root.lineColor, 0.12)
    }
  }
}
```

- [ ] **Step 2: Update the resources BarWidget**

In `bar/plugins/bart.resources/BarWidget.qml` (this file is plugin-owned, not shared — edit directly):

Line 18, update the fallback to the mono ramp:
```qml
  readonly property var levelColors: stats && stats.colors ? stats.colors : ["#9199a3", "#d9dde3", "#e06c75"]
```

Line 187, flip the readout default:
```qml
        readoutStyle: root.setting("readoutStyle", "columns")
```

Inside the `CellReadout { ... }` block (after the `history: cell.samples` line), add the level binding:
```qml
        level: cell.level
```

Replace the whole `CellSeparator` component (lines 199–206) with:
```qml
  // With no frame around the cluster these marks are the only structure the
  // readout has. Quiet graphite only — no accent, no live meter.
  component CellSeparator: CellDivider {
    dividerStyle: root.setting("dividerStyle", "hairline")
    lineColor: root.lineColor
  }
```

Do NOT remove `worstLevel` / `loadFraction` — the bloom frame still consumes them via `glowColor` / `glowIntensity`.

- [ ] **Step 3: Update manifest.json**

In `bar/plugins/bart.resources/manifest.json`:

In `defaults`, change `"dividerStyle": "glitch"` → `"dividerStyle": "hairline"` and `"readoutStyle": "sparkwide"` → `"readoutStyle": "columns"`.

Replace the `dividerStyle` schema entry with:
```json
      {
        "key": "dividerStyle",
        "type": "enum",
        "label": "Cell divider",
        "options": [
          "hairline",
          "tick"
        ],
        "defaultValue": "hairline",
        "description": "hairline: a quiet 1px rule. tick: instrument I-beam with a centre node. Both graphite-only."
      },
```

Replace the `readoutStyle` schema entry with:
```json
      {
        "key": "readoutStyle",
        "type": "enum",
        "label": "Cell readout",
        "options": [
          "columns",
          "meter",
          "text"
        ],
        "defaultValue": "columns",
        "description": "columns: the number plus a mini bar-chart of recent history. meter: the number with a progress rule under it. text: the padded number alone."
      }
```

(Leave the `frameStyle` / `lensBulge` / `lensSpecular` entries alone — Task 5 owns them.)

- [ ] **Step 4: Fan out, validate JSON, install, restart**

Run: `./tools/build-plugin-shared && python3 -m json.tool bar/plugins/bart.resources/manifest.json > /dev/null && echo JSON_OK`
Expected: `JSON_OK`.

Run: `./install.sh && omarchy-restart-shell`
Expected: no errors.

- [ ] **Step 5: Visual verification**

Screenshot the bar (as in Task 3, Step 4).
Expected: between cells there is now a single faint vertical hairline — no red segments, no offset glitch marks. Cells otherwise unchanged from Task 3.

- [ ] **Step 6: Commit**

```bash
git add bar/shared/CellDivider.qml bar/plugins/bart.resources/
git commit -m "Quiet graphite dividers: hairline default, prune glitch/slash/chevron/bars"
```

---

### Task 5: `CardFrame` — prune to none/flat/bloom, delete the shader everywhere

**Files:**
- Modify: `bar/shared/CardFrame.qml` (full rewrite below)
- Delete: `bar/shared/card.frag`, `bar/plugins/bart.resources/card.frag.qsb`, `bar/plugins/bart.media/card.frag.qsb`
- Modify: `tools/build-plugin-shared` (full rewrite below)
- Modify: `build.sh` (remove the stale-shader warning block, lines 136–143)
- Modify: `bar/plugins/bart.resources/BarWidget.qml:217-218` (drop bulge/specular)
- Modify: `bar/plugins/bart.media/BarWidget.qml:52-53` (drop bulge/specular)
- Modify: `bar/plugins/bart.resources/manifest.json`, `bar/plugins/bart.media/manifest.json` (frameStyle enum, remove lens entries)
- Regenerated: `bar/plugins/*/CardFrame.qml` (via tools/build-plugin-shared)

**Interfaces:**
- Consumes: nothing new.
- Produces: `CardFrame` keeps `lineColor`, `frameStyle` (`"none"` default, `"flat"`, `"bloom"`; unknown ⇒ none), `fillAlpha`, `glowColor`, `glowIntensity`, `cornerRadius`. REMOVED properties: `bulge`, `specular`, `rimGain`, `light`, `accentColor`, `tint` — hosts stop assigning `bulge`/`specular` in the same commit.

- [ ] **Step 1: Rewrite bar/shared/CardFrame.qml**

Full new file content:

```qml
import QtQuick
import QtQuick.Effects
import qs.Commons

// The bar cards' frame. Drops in where a framed Rectangle used to be —
// children go straight on this Item, so `parent` still means the card and
// anchoring to it by id still finds a parent rather than a grandparent.
// Every surface sits at z -1, so children paint over it.
//
//   none   nothing at all; the cell dividers carry the structure (default)
//   bloom  no frame — a halo behind the card, coloured by load
//   flat   the original hairline-bordered rectangle
//
// Source of truth: bar/shared/CardFrame.qml. Copied into each plugin by
// tools/build-plugin-shared — do not edit the copies.
Item {
  id: root

  // The bar's animated, transparency-aware foreground: the card recolors
  // with the bar, exactly as the flat frame did.
  property color lineColor: "white"

  property string frameStyle: "none"
  property real fillAlpha: 0.07

  // bloom only: halo colour and how hard it burns, 0..1. The host widget
  // feeds these from whatever it considers "load".
  property color glowColor: lineColor
  property real glowIntensity: 0

  // Style.cornerRadius tracks Hyprland rounding, so the cards share the
  // family's one corner identity.
  property real cornerRadius: Math.min(Style.cornerRadius, height / 2)

  // Stale style names from an older shell.json (lens, emboss, ...) fall
  // back to "none" rather than erroring or surprising with a flat box.
  readonly property string effectiveStyle:
    ["none", "flat", "bloom"].indexOf(frameStyle) >= 0 ? frameStyle : "none"
  readonly property bool useBloom: effectiveStyle === "bloom"
  readonly property bool useNone: effectiveStyle === "none"
  readonly property bool useFlat: effectiveStyle === "flat"

  // Bloom: the card is defined by light rather than by an edge. The halo is
  // a blurred copy of the card's own shape sitting behind it, so it swells
  // and colours with load instead of just decorating.
  Loader {
    anchors.fill: parent
    z: -2
    active: root.useBloom

    sourceComponent: Item {
      Rectangle {
        id: haloSource
        anchors.fill: parent
        radius: root.cornerRadius
        // An outline, not a fill: blurring a filled rect leaves the middle
        // fully coloured, which fogs the readout instead of haloing it. A
        // ring blurs outward from the edge and leaves the centre clear.
        color: "transparent"
        border.color: root.glowColor
        border.width: 2
        // Drawn only through the effect below; showing it too would stack a
        // hard-edged copy under the halo.
        visible: false
      }

      MultiEffect {
        source: haloSource
        anchors.fill: haloSource
        blurEnabled: true
        blur: 1.0
        blurMax: 16
        autoPaddingEnabled: true
        opacity: 0.35 + 0.55 * Math.max(0, Math.min(1, root.glowIntensity))

        Behavior on opacity {
          NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
      }
    }
  }

  // Bloom still needs a body, or the text floats on a bare halo.
  Rectangle {
    anchors.fill: parent
    z: -1
    visible: root.useBloom
    radius: root.cornerRadius
    color: Qt.alpha(root.lineColor, root.fillAlpha * 0.8)
  }

  // The original hairline-bordered rectangle, kept for "flat".
  Rectangle {
    anchors.fill: parent
    z: -1
    visible: root.useFlat
    radius: root.cornerRadius
    color: Style.normalFillFor(root.lineColor, root.lineColor)
    border.width: Style.normalBorderWidth
    border.color: Style.normalBorderFor(root.lineColor, root.lineColor)
  }
}
```

- [ ] **Step 2: Rewrite tools/build-plugin-shared (no qsb)**

Full new file content:

```bash
#!/bin/bash
#
# Fan the shared bar QML out to every plugin that uses it.
#
# Quickshell plugins cannot import each other — a plugin's QML resolves only
# against its own directory — so shared components have to exist physically
# in each plugin. This script is what keeps those copies identical; never
# edit them by hand.

set -euo pipefail
cd "$(dirname "$0")/.."

FRAME=bar/shared/CardFrame.qml
FRAME_CONSUMERS=(
  bar/plugins/bart.resources
  bar/plugins/bart.media
)

# Only the resources cluster has cells; the media widget is a single
# label, so it does not get a copy.
DIVIDER=bar/shared/CellDivider.qml
READOUT=bar/shared/CellReadout.qml
CELL_CONSUMERS=(
  bar/plugins/bart.resources
)

die() {
  echo "build-plugin-shared: ERROR: $*" >&2
  exit 1
}

[[ -f $FRAME ]] || die "missing $FRAME"
[[ -f $READOUT ]] || die "missing $READOUT"
[[ -f $DIVIDER ]] || die "missing $DIVIDER"

for plugin in "${FRAME_CONSUMERS[@]}"; do
  [[ -d $plugin ]] || die "missing plugin directory: $plugin"
  cp -- "$FRAME" "$plugin/CardFrame.qml"
  echo "  frame: $plugin"
done

for plugin in "${CELL_CONSUMERS[@]}"; do
  [[ -d $plugin ]] || die "missing plugin directory: $plugin"
  cp -- "$DIVIDER" "$plugin/CellDivider.qml"
  cp -- "$READOUT" "$plugin/CellReadout.qml"
  echo "  cells: $plugin"
done

echo "OK: shared QML fanned out"
```

- [ ] **Step 3: Delete the shader artifacts and the stale-check**

```bash
git rm bar/shared/card.frag bar/plugins/bart.resources/card.frag.qsb bar/plugins/bart.media/card.frag.qsb
```

In `build.sh`, delete the whole stale-shader block (the comment starting `# Bar plugins ship prebuilt shaders` and the `for stale in ...` loop through its `done`, lines 136–143).

- [ ] **Step 4: Drop bulge/specular from both hosts**

`bar/plugins/bart.resources/BarWidget.qml` — in the `CardFrame {` block delete these two lines:
```qml
    bulge: Number(root.setting("lensBulge", 4))
    specular: Number(root.setting("lensSpecular", 60)) / 100
```

`bar/plugins/bart.media/BarWidget.qml` — same two lines, same deletion.

- [ ] **Step 5: Shrink both manifests**

In BOTH `bar/plugins/bart.resources/manifest.json` and `bar/plugins/bart.media/manifest.json`:
- In `defaults`: delete the `"lensBulge": 4,` and `"lensSpecular": 60` lines (mind trailing commas).
- In `schema`: delete the entire `lensBulge` and `lensSpecular` entries.
- Replace the `frameStyle` entry's `options` and `description` with:
```json
        "options": [
          "none",
          "bloom",
          "flat"
        ],
        "defaultValue": "none",
        "description": "none: no container at all — the dividers carry the structure. bloom: a halo behind the card, coloured by load. flat: the original bordered rectangle."
```

- [ ] **Step 6: Fan out, validate, install, restart**

Run: `./tools/build-plugin-shared && python3 -m json.tool bar/plugins/bart.resources/manifest.json > /dev/null && python3 -m json.tool bar/plugins/bart.media/manifest.json > /dev/null && echo OK`
Expected: `OK`, script no longer mentions qsb.

Run: `ls bar/plugins/*/card.frag.qsb bar/shared/card.frag 2>&1`
Expected: `No such file or directory` for all three.

Run: `./build.sh > /dev/null && ./install.sh && omarchy-restart-shell`
Expected: no stale-shader warning, no errors; install's `rsync --delete` removes the installed `.qsb` copies.

- [ ] **Step 7: Visual verification**

Screenshot the bar. Expected: identical to Task 4's result (both widgets already default to `frameStyle: none`) — this task must cause NO visible change; if the cluster or media widget vanished, a QML error slipped in (check `journalctl --user -u omarchy-shell -n 50` or the shell's stderr).

- [ ] **Step 8: Commit**

```bash
git add -A bar/ tools/build-plugin-shared build.sh
git commit -m "Prune card frames to none/flat/bloom; delete the fragment shader path"
```

---

### Task 6: Media widget — faded marquee edges

**Files:**
- Modify: `bar/plugins/bart.media/BarWidget.qml` (imports + scrollClip)

**Interfaces:**
- Consumes: nothing new.
- Produces: no API change; purely visual. The scrolling title fades out over the last ~8% at each clip edge instead of cutting mid-glyph.

- [ ] **Step 1: Add the import**

At the top of `bar/plugins/bart.media/BarWidget.qml`, after `import QtQuick`:
```qml
import QtQuick.Effects
```

- [ ] **Step 2: Mask the scroll clip**

In the `Item { id: scrollClip ... }` block, add layer lines right after `clip: true`:
```qml
      clip: true
      // Fade the marquee out at both edges instead of cutting mid-glyph.
      // Layered only while scrolling: a short title that fits needs neither
      // the fade nor the extra texture.
      layer.enabled: labelText.needsScroll
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: fadeMask
      }
```

Then, as a sibling of `scrollClip` (directly after its closing brace, still inside the `Row { id: row }`), add:
```qml
    Item {
      id: fadeMask
      width: scrollClip.width
      height: scrollClip.height
      visible: false
      layer.enabled: true

      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 0.08; color: "white" }
          GradientStop { position: 0.92; color: "white" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }
    }
```

- [ ] **Step 3: Install, restart, verify**

Run: `./install.sh && omarchy-restart-shell`
Play something (or use the already-playing player), wait for a long title to scroll, screenshot the left bar region at 300%.
Expected: the title's leading/trailing characters dissolve softly at the clip edges; no hard mid-glyph cut. If the mask renders wrong (blank label, doubled text), revert Steps 1–2 — the spec explicitly allows keeping the hard clip.

- [ ] **Step 4: Commit**

```bash
git add bar/plugins/bart.media/BarWidget.qml
git commit -m "Fade the media marquee at the clip edges"
```

---

### Task 7: Documentation — README + variant README template

**Files:**
- Modify: `README.md`
- Modify: `templates/README.md.tpl:5`

**Interfaces:**
- Consumes: everything above (documents the end state).
- Produces: docs that match the shipped system; no stale style tables.

- [ ] **Step 1: Update README.md**

Apply these content changes (keep the file's voice and structure):
- Variant table intro: describe the family as "mono-graphite base + one accent per variant".
- "Token contract" section: replace the two custom border keys' description with: `hyprland_active_border` = `accent` → `accent_dim` at `dd`, 35deg; `hyprland_inactive_border` = `border` at `aa`. Remove the steel/complementary gradient sentences ("In ember the gradient is amber -> steel...") — the gradient is now accent → accent_dim everywhere.
- Shape identity bullet: replace "the per-variant radius (stealth 1 / redline 4 / x1 6 / graphite 8 / ember 10)" with "one shared geometry (rounding 5, gaps 4/8, border 2px) in every variant".
- "Card frames" table: keep only `none` (default), `bloom`, `flat` rows; delete the shader-styles table rows and the paragraphs about the SDF/normal/fresnel lighting, the `.qsb` being committed, qsb tooling, and `lensBulge`/`lensSpecular` tuning. Keep the bloom paragraphs (they still apply) and the "source of truth is bar/shared/" bullet (now QML-only).
- "Cell dividers" table: keep only `hairline` (default) and `tick`; note both are graphite-only (no accent marks). Delete the `bars` explanation paragraphs.
- "Cell readouts" table: replace with `columns` (default; number + mini bar-chart, gapped columns, absolute scale), `meter`, `text`. Replace the two spark-mode paragraphs with one sentence on why columns keep the digits and why the gaps matter (steady value reads as an even comb, not a block). Keep the history/normalization paragraph (historyLen 24, temp 35–95 °C mapping, wholesale reassignment) — still true.
- Bar level colors: update the `x1-bar-stats` description from "green/orange/red via omarchy-theme-color green|orange|bright_red" to "muted/foreground/red via omarchy-theme-color muted|foreground|bright_red — the cluster idles gray, brightens on warn, goes red only at critical".
- Bar transparency paragraph: state filled graphite glass (`bar_alpha` 0.50) is the intended default and double-click toggles transparent mode.
- `build.sh` layout note: remove the mention of shader warn/qt6-shadertools.

- [ ] **Step 2: Update templates/README.md.tpl**

Line 5: add Ember to the family list:
```
Part of the X1 theme family for Omarchy 4 (X1 / Graphite / Redline / Stealth / Ember).
```

- [ ] **Step 3: Verify no stale references**

Run: `grep -n "sparkwide\|glitch\|lensBulge\|lensSpecular\|border_gradient\|card.frag\|emboss\|chamfer" README.md templates/ bar/ build.sh install.sh tools/ --include="*" -r; echo "exit=$?"`
Expected: no matches, `exit=1`.

Run: `./build.sh > /dev/null && echo BUILD_OK`
Expected: `BUILD_OK`.

- [ ] **Step 4: Commit**

```bash
git add README.md templates/README.md.tpl
git commit -m "Document the mono system; drop pruned style tables"
```

---

### Task 8: Integration — flip the bar to filled, full verify, visual tune

**Files:**
- Modify: `~/.config/omarchy/shell.json` (user config — one-time local edit, NOT part of the repo or install.sh)
- Possibly tune: `palettes/*.toml` (`accent_dim`, `bar_alpha`) based on the screenshot

**Interfaces:**
- Consumes: everything above.
- Produces: the finished look, verified on screen.

- [ ] **Step 1: Flip the bar to filled mode (one-time)**

Inspect first: `python3 -c "import json;print(json.load(open('$HOME/.config/omarchy/shell.json')).get('bar',{}).get('transparent'))"`
If `True`, edit `~/.config/omarchy/shell.json` and set the bar's `"transparent"` key to `false` (edit only that key; the file also holds tray pins and widget entries that must survive).

- [ ] **Step 2: Full pipeline**

Run: `./tools/contrast-audit && ./build.sh && ./install.sh && omarchy-restart-shell`
Expected: audit `all palettes pass`; build `OK: 5 variant(s) built`; install refreshes the active theme (`OK — refreshed active theme: x1-graphite`).

- [ ] **Step 3: Geometry check**

Run: `hyprctl getoption general:gaps_in -j | python3 -m json.tool && hyprctl getoption general:gaps_out -j | python3 -m json.tool && hyprctl getoption decoration:rounding -j && hyprctl getoption general:border_size -j`
Expected: gaps_in 4, gaps_out 8, rounding 5, border_size 2.

- [ ] **Step 4: Full-screen visual review**

Take `grim` screenshot; crop and inspect at 300%: (a) the bar — graphite glass fill visible over the wallpaper, columns readable, hairline dividers visible-but-quiet (if the 0.12 alpha hairline disappears on the glass fill, raise to 0.18 in `bar/shared/CellDivider.qml`, re-fan-out, reinstall, restart, re-check); (b) two windows side by side — active border reads accent→dark-accent, inactive border clearly visible, gaps even; (c) media widget — fade edges working.

- [ ] **Step 5: Cycle all five variants**

For each of `x1 x1-redline x1-stealth x1-ember x1-graphite` (ending back on graphite): `omarchy theme set <variant>`, screenshot, check the accent identity carries (red/red/red/steel/amber active border + theme switcher label) and nothing renders blank in the theme picker (`preview.png` regenerated as 8-bit).
If any variant's `accent_dim` reads muddy or the inactive border vanishes on its background, adjust that palette token, then re-run `./tools/contrast-audit && ./build.sh && ./install.sh`.

- [ ] **Step 6: Commit any tuning**

```bash
git add palettes/ bar/shared/ bar/plugins/
git commit -m "Visual tuning pass from on-screen review"
```
(Skip the commit if nothing needed tuning.)

---

## Self-review notes

- Spec coverage: palette system → Task 1+2; geometry → Task 1 (values) + Task 8 (verify); bar glass → Task 1 (alpha) + Task 8 (flip+verify); columns readout → Task 3; dividers → Task 4; frame prune + shader deletion → Task 5; media fade → Task 6; template/README pass → Task 1 (controls/colors/hyprland) + Task 7 (docs); verification → per-task + Task 8. Out-of-scope items (ANSI ramp, detail panels, weather, installer touching shell.json) are not implemented anywhere. ✓
- Ordering keeps the shell working after every task: Task 3 changes CellReadout only in ways the old host tolerates (removed modes fall back via the switch default; new `level` has a default); Task 4 changes CellDivider and its host in one commit (removed properties would otherwise error); Task 5 changes CardFrame and both hosts in one commit (same reason). ✓
- Type consistency: `CellReadout.level` (int, default 0) bound as `level: cell.level` in Task 4 Step 2 matches Task 3's definition; `CellDivider` post-Task-4 surface (`dividerStyle`, `lineColor`, `markHeight`) matches the Task 4 host wiring; `CardFrame` post-Task-5 surface (`lineColor`, `frameStyle`, `fillAlpha`, `glowColor`, `glowIntensity`) matches both hosts' remaining bindings (`glowColor`/`glowIntensity` in resources, media). ✓
