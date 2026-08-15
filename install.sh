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

# Pre-quattro leftover: this user-global template renders a dead waybar.css
# into every theme set. Retire it once, keeping a backup.
legacy_tpl="$HOME/.config/omarchy/themed/waybar.css.tpl"
if [[ -f $legacy_tpl ]]; then
  mv "$legacy_tpl" "$legacy_tpl.pre-quattro.bak"
  echo "retired: $legacy_tpl -> $legacy_tpl.pre-quattro.bak"
fi

current=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
case $current in
x1 | x1-graphite | x1-redline | x1-stealth)
  omarchy-theme-refresh
  echo "OK — refreshed active theme: $current"
  ;;
*)
  echo "OK — apply with: omarchy theme set x1-stealth (or x1 / x1-redline / x1-graphite)"
  ;;
esac
