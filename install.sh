#!/bin/bash
#
# Install the built X1 theme family into the live Omarchy config:
#   build/<variant>/            -> ~/.config/omarchy/themes/<variant>/
#   waybar/waybar.css.tpl       -> ~/.config/omarchy/themed/waybar.css.tpl
#   waybar/x1-*                 -> ~/.config/waybar/scripts/
#
# Run ./build.sh first. Apply afterwards with: omarchy theme set <variant>

set -euo pipefail
cd "$(dirname "$0")"

THEMES_DIR="$HOME/.config/omarchy/themes"
THEMED_DIR="$HOME/.config/omarchy/themed"
SCRIPTS_DIR="$HOME/.config/waybar/scripts"

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

mkdir -p "$THEMED_DIR"
install -m 644 waybar/waybar.css.tpl "$THEMED_DIR/waybar.css.tpl"
echo "installed: $THEMED_DIR/waybar.css.tpl"

mkdir -p "$SCRIPTS_DIR"
install -m 755 waybar/x1-* "$SCRIPTS_DIR/"
echo "installed: $SCRIPTS_DIR/ ($(basename -a waybar/x1-* | paste -sd' '))"

echo "OK — apply with: omarchy theme set x1-stealth (or x1 / x1-redline / x1-graphite)"
