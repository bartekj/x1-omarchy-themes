#!/bin/bash
#
# Install the built X1 theme family into the live Omarchy (4.x) config:
#   build/<variant>/ -> ~/.config/omarchy/themes/<variant>/
#
# Run ./build.sh first. Apply afterwards with: omarchy theme set <variant>

set -euo pipefail
cd "$(dirname "$0")"

THEMES_DIR="$HOME/.config/omarchy/themes"

compgen -G 'build/*/colors.toml' >/dev/null || {
  echo "install.sh: ERROR: nothing built — run ./build.sh first" >&2
  exit 1
}

for src in build/*/; do
  name=$(basename "$src")
  mkdir -p "$THEMES_DIR/$name"
  rsync -a --delete "$src" "$THEMES_DIR/$name/"
  echo "installed: $THEMES_DIR/$name"
done

# Bar cockpit: command-module scripts + the patched weather plugin clone.
# shell.json itself is user config and is never touched by this installer.
for script in bar/scripts/x1-*; do
  install -Dm755 "$script" "$HOME/.config/omarchy/bar/scripts/$(basename "$script")"
done
echo "installed: ~/.config/omarchy/bar/scripts/ ($(basename -a bar/scripts/x1-* | paste -sd' '))"

# This loop only ever ships the plugins that still live in-tree under
# bar/plugins/ (bart.media, bart.weather). Git-managed plugins installed via
# `omarchy plugin add` — bart.resources now lives in its own repo, cloned
# straight into ~/.config/omarchy/plugins/bart.resources — must NEVER be
# rsynced over: with its directory gone from this repo the glob below simply
# never matches it, so its git clone is left untouched.
mkdir -p "$HOME/.config/omarchy/plugins"
for plugin in bar/plugins/*/; do
  name=$(basename "$plugin")
  rsync -a --delete "$plugin" "$HOME/.config/omarchy/plugins/$name/"
  echo "installed: ~/.config/omarchy/plugins/$name (shell hot-reloads it)"
done

# Pre-quattro leftover: this user-global template renders a dead waybar.css
# into every theme set. Retire it once, keeping a backup.
legacy_tpl="$HOME/.config/omarchy/themed/waybar.css.tpl"
if [[ -f $legacy_tpl ]]; then
  mv "$legacy_tpl" "$legacy_tpl.pre-quattro.bak"
  echo "retired: $legacy_tpl -> $legacy_tpl.pre-quattro.bak"
fi

# bart.resources moved to its own plugin repo; retire the old shared scripts.
for stale in x1-bar-stats x1-bar-detail; do
  if [[ -f "$HOME/.config/omarchy/bar/scripts/$stale" ]]; then
    rm -f "$HOME/.config/omarchy/bar/scripts/$stale"
    echo "retired: ~/.config/omarchy/bar/scripts/$stale (ships with the bart.resources plugin now)"
  fi
done

# Warm the theme-picker thumbnail cache: without this, the first picker open
# after a rebuild hits the lazy-thumbnails path that hands Qt the original
# preview.png instead of a cached JPEG.
if command -v omarchy-theme-switcher >/dev/null; then
  omarchy-theme-switcher --preload
  echo "warmed: theme-picker thumbnails"
fi

current=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
case $current in
x1 | x1-*)
  omarchy-theme-refresh
  echo "OK — refreshed active theme: $current"
  ;;
*)
  echo "OK — apply with: omarchy theme set x1-ember (or x1 / x1-graphite / x1-redline / x1-stealth)"
  ;;
esac
