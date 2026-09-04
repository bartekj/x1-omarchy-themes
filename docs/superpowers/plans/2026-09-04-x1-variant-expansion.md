# X1 Variant Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grow the X1 family from five to seven dark variants by adding `x1-azure` (ThinkVantage steel blue) and `x1-moss` (power-LED green), reusing the established mono-graphite system unchanged: shared graphite base, per-variant accent lane, solid full-alpha borders, unified geometry, audit-gated palettes.

**Architecture:** `build.sh` and `install.sh` iterate `palettes/*.toml` / `build/*/` — a new variant needs NO build-system changes. Each variant is one ~30-key palette; the bar theme-switcher cycle (`bar/scripts/x1-theme-next`), its label map (`x1-theme-status`), and the README table are the only other touchpoints.

**Tech Stack:** TOML palettes, Omarchy `{{ key }}` templates (unchanged), Python contrast audit, Bash scripts, ImageMagick asset generation.

**Precedent for accent ≠ ANSI-red:** `x1-stealth` already decouples them (accent `#7d8792`, `color1` `#b02a38`). Azure/moss follow the same rule.

## Global Constraints

- `color1`/`color9` stay semantically red in EVERY variant; `accent` never means error; `critical` == `color9` red.
- The graphite mono base is family-shared: `background`/`color0` `#0b0d0f`, `surface` `#15191d`, `surface_raised` `#20262c`, `foreground`/`color7` `#d9dde3`, `color15` `#f6f7f9`, `muted` `#9199a3`, `border` `#535d69`, `border_soft` `#5a6472`, selection `#f6f7f9`/`#535d69`, `cursor` `#e6e9ed`, `color8` `#535d69`. Only the accent lane, `window_border_inactive`, and `bg_tint` carry the variant hue.
- Geometry/glass block byte-identical in every palette: `bar_alpha = "0.50"`, `pill_alpha = "0.85"`, `pill_border_alpha = "0.86"`, `hypr_rounding = "5"`, `hypr_gaps_in = "4"`, `hypr_gaps_out = "8"`, `hypr_border_size = "2"`.
- Contrast floors via `tools/contrast-audit` (exit 0 gates everything). New palettes target floor **+0.15 margin** — the family's existing 2.91/3.12 margins are thin; do not reproduce that.
- Brighter-than rule: `color9..14` must be brighter than `color1..6` (audit enforces).
- `icons_theme` must exist in `/usr/share/icons` (verified: `Yaru-blue`, `Yaru-prussiangreen` both present). `vscode_name` must be a built-in VS Code theme name (no `vscode.json` extension is shipped).
- Never hand-edit `build/` or `~/.config/omarchy/themes/x1*` — palettes are the source of truth.
- Commit after every task; short imperative subject lines.

---

### Task 1: `palettes/x1-azure.toml` — ThinkVantage steel blue

**Files:**
- Create: `palettes/x1-azure.toml`

- [ ] **Step 1: Write the palette**, modeled on `palettes/x1.toml`:

```toml
# X1 Azure — matte graphite with ThinkVantage steel-blue accents.

# identity / meta
display_name = "X1 Azure"
description = "Matte graphite with ThinkVantage steel-blue active states."
icons_theme = "Yaru-blue"
vscode_name = "Tomorrow Night Blue"

# colors.toml keys
accent = "#5e9ad4"
cursor = "#e6e9ed"
foreground = "#d9dde3"
background = "#0b0d0f"
selection_foreground = "#f6f7f9"
selection_background = "#535d69"

color0 = "#0b0d0f"
color1 = "#c82031"
color2 = "#83a598"
color3 = "#d19a66"
color4 = "#4f83b4"
color5 = "#a78bba"
color6 = "#6fa3a8"
color7 = "#d9dde3"
color8 = "#535d69"
color9 = "#ef4f5f"
color10 = "#9fc3b4"
color11 = "#e2b27a"
color12 = "#85b4dc"
color13 = "#c6b0d7"
color14 = "#9ac0c4"
color15 = "#f6f7f9"

# surface ramp
surface = "#15191d"
surface_raised = "#20262c"

# lines & emphasis
muted = "#9199a3"
border = "#535d69"
border_soft = "#5a6472"
window_border_inactive = "#565a60"
accent_dim = "#274a63"

# semantic
warning = "#d19a66"
critical = "#ef4f5f"

# background generation knobs
bg_tint = "#5e9ad4"
weave_hi = "#20262c"
weave_lo = "#0b0d0f"

# shape & glass identity
bar_alpha = "0.50"
pill_alpha = "0.85"
pill_border_alpha = "0.86"
hypr_rounding = "5"
hypr_gaps_in = "4"
hypr_gaps_out = "8"
hypr_border_size = "2"
```

Blue-lane notes: `color4`/`color12` move onto the accent hue (steel), `window_border_inactive` cools to steel-warm graphite `#565a60` (contrast vs bg ≈ 2.67, floor 1.8 — verify by audit), `accent` `#5e9ad4` computes to 6.53 bg / 5.93 surface / 5.13 raised — all well above floors. Reds untouched.

- [ ] **Step 2: Audit and iterate.** Run `./tools/contrast-audit` — every x1-azure row must pass with margin ≥ +0.15. If `accent/surface` or a `colorN/bg` row is tight, lift lightness only (keep hue drift ≤ 2°).

- [ ] **Step 3: Build and pixel-verify.** `./build.sh` → `OK: 6 variant(s) built`. Then:
  - `grep hyprland_active_border build/x1-azure/colors.toml` → `rgba(5e9ad4ff)` (solid full alpha, no gradient).
  - `magick identify -format "%wx%h %z-bit\n" build/x1-azure/preview.png` → `1600x900 8-bit`.
  - `ls build/x1-azure/` → same file set as `build/x1/` (18 entries incl. unlock.png, shell.*.toml).

- [ ] **Step 4: Commit** — `git add palettes/x1-azure.toml && git commit -m "Azure variant: ThinkVantage steel blue on the mono graphite base"`

### Task 2: `palettes/x1-moss.toml` — power-LED green

**Files:**
- Create: `palettes/x1-moss.toml`

- [ ] **Step 1: Write the palette** — same skeleton as Task 1, differing in:

```toml
display_name = "X1 Moss"
description = "Matte graphite with subdued power-LED green accents."
icons_theme = "Yaru-prussiangreen"
vscode_name = "Monokai"

accent = "#58a877"          # bg 6.75 / surface 6.13 (computed)
window_border_inactive = "#5a584f"   # warm olive-graphite (~2.7 vs bg, audit-gated)
accent_dim = "#2a4f39"
bg_tint = "#58a877"
```

Green-lane notes: `color2` harmonizes toward the moss hue (`#6f9e7f`), `color10` brighter (`#96bda3`); every other ramp lane keeps the x1 values; reds untouched.

- [ ] **Step 2: Audit and iterate** — same rule as Task 1 Step 2. Extra check: `color2/bg` and `color10 > color2` (brightness ordering).

- [ ] **Step 3: Build and pixel-verify** — same as Task 1 Step 3, now `OK: 7 variant(s) built`, `rgba(58a877ff)`.

- [ ] **Step 4: Commit** — `git commit -m "Moss variant: subdued LED green on the mono graphite base"`

### Task 3: Switcher cycle, labels, install hint

**Files:**
- Modify: `bar/scripts/x1-theme-next:5` — `themes=(x1 x1-stealth x1-redline x1-graphite x1-ember x1-azure x1-moss)`
- Modify: `bar/scripts/x1-theme-status:7-13` — add `x1-azure) label="Azure" ;;` and `x1-moss) label="Moss" ;;`
- Modify: `install.sh:85` — hint line lists the seven variants

- [ ] **Step 1: Apply the three edits.**

- [ ] **Step 2: Verify.** `bash -n` both scripts. Cycle dry-check without switching: `name=x1-moss; themes=(x1 x1-stealth x1-redline x1-graphite x1-ember x1-azure x1-moss); ...` (replicate the array walk inline) → next = `x1`. Status JSON: `bash -c 'theme=x1-azure; case ...'` prints `{"text":"󰔎 Azure",...}`.

- [ ] **Step 3: Commit** — `git commit -m "Cycle and labels cover azure and moss"`

### Task 4: README family table

**Files:**
- Modify: `README.md` — variant table (two new rows with accents `#5e9ad4`, `#58a877`), the `omarchy theme set` usage line (seven variants), and any "Five"/"five variants" wording (`grep -ni five README.md`).

- [ ] **Step 1: Update table + usage + counts.** Token contract and Border system sections are variant-count-agnostic — confirm, don't rewrite.

- [ ] **Step 2: Commit** — `git commit -m "README: seven-variant family table"`

### Task 5: Install + live verification (no repo changes)

- [ ] `./install.sh` → 7 themes installed, picker thumbnails warmed.
- [ ] `omarchy theme set x1-azure` → `omarchy theme current` = "X1 Azure"; `hyprctl configerrors` clean; `grim` screenshot: bar glass + solid steel-blue active border + one inactive graphite border; open launcher (SUPER+SPACE) → hairline card, selection echo; cycle the switcher once (right-click → next) to prove Azure→Moss hop.
- [ ] `omarchy theme set x1-moss` → same checklist, green accents.
- [ ] `magick identify -format "%z-bit\n" ~/.config/omarchy/themes/x1-azure/preview.png` → `8-bit`.
- [ ] Restore the user's live theme: `omarchy theme set x1-graphite`.

## Adding further variants later

Repeat Task 1–2 with a new accent (audit + build + pixel-check gates), then Task 3–4 one-liners. No build-system changes are ever needed — `palettes/*.toml` is the only registry.
