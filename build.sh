#!/bin/bash
#
# Build the X1 theme family: render templates/ against each palettes/*.toml
# into build/<variant>/ and generate per-variant image assets.
#
# Template syntax is byte-compatible with Omarchy's own renderer
# (omarchy-theme-set-templates): {{ key }}, {{ key_strip }}, {{ key_rgb }}.

set -euo pipefail
cd "$(dirname "$0")"

REQUIRED_KEYS=(
  accent cursor foreground background selection_foreground selection_background
  color0 color1 color2 color3 color4 color5 color6 color7
  color8 color9 color10 color11 color12 color13 color14 color15
  display_name description icons_theme vscode_name
  surface surface_raised
  muted border border_soft border_gradient
  warning critical
  bg_tint weave_hi weave_lo
  bar_alpha pill_alpha pill_border_alpha
  hypr_rounding hypr_gaps_in hypr_gaps_out hypr_border_size
)

die() {
  echo "build.sh: ERROR: $*" >&2
  exit 1
}

# Same conversion as omarchy-theme-set-templates: "#1e1e2e" -> "30,30,46"
hex_to_rgb() {
  local hex="${1#\#}"
  printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

generate_weave() {
  local out="$1"
  local bg_tint="${P[bg_tint]}" weave_hi="${P[weave_hi]}" weave_lo="${P[weave_lo]}"

  # Procedural carbon-fiber weave: interleaved vertical/horizontal gradient
  # tiles, faint noise, vignette, and a whisper of the variant tint.
  magick \
    \( -size 24x48 gradient:"${weave_hi}"-"${weave_lo}" \) \
    \( -size 48x24 gradient:"${weave_hi}"-"${weave_lo}" -rotate 90 \) \
    -background none +append -write mpr:weave +delete \
    -size 2560x1600 tile:mpr:weave \
    -attenuate 0.25 +noise Gaussian -blur 0x0.4 \
    \( -size 2560x1600 radial-gradient:'rgba(255,255,255,1)'-'rgba(160,160,160,1)' \) \
    -compose multiply -composite \
    \( -size 2560x1600 xc:"${bg_tint}" -alpha set -channel A -evaluate set 4% +channel \) \
    -compose over -composite \
    "$out/backgrounds/1-carbon-weave.png"
}

generate_heritage() {
  local out="$1"
  local bg_tint="${P[bg_tint]}"

  # Heritage: the shared original wallpaper, rescaled and tinted per variant.
  magick assets/source/BG1.png \
    -resize 2560x1600^ -gravity center -extent 2560x1600 \
    -modulate 100,85 \
    \( +clone -fill "${bg_tint}" -colorize 100 \) \
    -compose blend -define compose:args=12x88 -composite \
    "$out/backgrounds/2-heritage.png"
}

populate_backgrounds() {
  local name="$1" out="$2" dir copied=0

  # User wallpapers win: anything in assets/backgrounds/<variant>/ or
  # assets/backgrounds/all/ ships as-is INSTEAD of the generated set.
  for dir in "assets/backgrounds/$name" "assets/backgrounds/all"; do
    if compgen -G "$dir/*" >/dev/null; then
      cp -- "$dir"/* "$out/backgrounds/"
      copied=1
    fi
  done

  if ((!copied)); then
    generate_weave "$out"
    generate_heritage "$out"
  fi
}

generate_assets() {
  local name="$1" out="$2"
  local accent="${P[accent]}" background="${P[background]}" foreground="${P[foreground]}"

  populate_backgrounds "$name" "$out"

  # Picker preview: first background (sort order = what omarchy shows first)
  # + accent stripe + 16-swatch ANSI strip.
  local first_bg
  first_bg=$(find "$out/backgrounds" -maxdepth 1 -type f | sort | head -1)
  [[ -n "$first_bg" ]] || die "$name: no backgrounds produced"

  local swatches=()
  for i in $(seq 0 15); do
    swatches+=(\( -size 50x52 xc:"${P[color$i]}" \))
  done
  magick \
    \( "$first_bg" -resize 800x420^ -gravity center -extent 800x420 \) \
    \( -size 800x8 xc:"${accent}" \) \
    \( "${swatches[@]}" +append \) \
    -append "$out/preview.png"

  # 4) Plymouth unlock glyph + its picker preview.
  local font
  font=$(fc-match -f '%{file}' 'JetBrainsMono Nerd Font:bold')
  magick -size 512x512 xc:none -gravity center \
    -font "$font" -pointsize 220 -fill "${foreground}" -annotate 0 'X1' \
    "$out/unlock.png"
  magick "$out/unlock.png" -background "${background}" -flatten "$out/preview-unlock.png"
}

[[ -x /usr/bin/magick ]] || die "ImageMagick (magick) not found"
compgen -G 'palettes/*.toml' >/dev/null || die "no palettes found in palettes/"
compgen -G 'templates/*.tpl' >/dev/null || die "no templates found in templates/"

for palette in palettes/*.toml; do
  name=$(basename "$palette" .toml)
  out="build/$name"
  rm -rf "$out"
  mkdir -p "$out/backgrounds"

  # Parse palette + build sed script (parser copied from omarchy-theme-set-templates)
  unset P
  declare -A P=()
  sed_script=$(mktemp)
  while IFS='=' read -r key value; do
    key="${key//[\"\' ]/}"                # strip quotes and spaces from key
    [[ $key && $key != \#* ]] || continue # skip empty lines and comments
    value="${value#*[\"\']}"
    value="${value%%[\"\']*}" # extract value between quotes (ignores inline comments)
    P[$key]=$value

    printf 's|{{ %s }}|%s|g\n' "$key" "$value"
    printf 's|{{ %s_strip }}|%s|g\n' "$key" "${value#\#}"
    if [[ $value =~ ^# ]]; then
      echo "s|{{ ${key}_rgb }}|$(hex_to_rgb "$value")|g"
    fi
  done <"$palette" >"$sed_script"
  printf 's|{{ slug }}|%s|g\n' "$name" >>"$sed_script"

  for k in "${REQUIRED_KEYS[@]}"; do
    [[ -n "${P[$k]:-}" ]] || die "$name: missing required key '$k'"
  done

  for tpl in templates/*.tpl; do
    filename=$(basename "$tpl" .tpl)
    sed -f "$sed_script" "$tpl" >"$out/$filename"
  done
  rm "$sed_script"

  generate_assets "$name" "$out"

  # Guard: no unresolved {{ placeholders }} may survive (text files only)
  if leftovers=$(grep -rIn '{{' "$out"); then
    die "$name: unresolved placeholders:"$'\n'"$leftovers"
  fi

  echo "built: $out"
done

echo "OK: $(ls -d build/*/ | wc -l) variant(s) built"
