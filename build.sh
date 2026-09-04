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
  muted border border_soft window_border_inactive accent_dim
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
  local bg_tint="${P[bg_tint]}" weave_hi="${P[weave_hi]}" weave_lo="${P[weave_lo]}" accent="${P[accent]}"

  # Signature 1: carbon-fiber weave with a single accent fiber crossing at
  # thirds — the variant's own thread in the cloth. The fiber, the tint wash,
  # and the window borders all share the accent.
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
    \( -size 2560x1600 xc:none -stroke "${accent}55" -strokewidth 3 \
       -draw "line 960,0 960,1600" -draw "line 0,800 2560,800" -blur 0x0.6 \) \
    -compose over -composite \
    "$out/backgrounds/1-carbon-weave.jpg"
}

generate_trackpoint() {
  local out="$1"
  local bg_tint="${P[bg_tint]}" accent="${P[accent]}" surface="${P[surface]}" background="${P[background]}"
  local raised="${P[surface_raised]}" color8="${P[color8]}"

  magick -size 2560x1600 gradient:"${surface}"-"${background}" \
    -attenuate 0.12 +noise Gaussian -blur 0x0.4 \
    \( -size 2560x1600 radial-gradient:'rgba(200,200,200,1)'-'rgba(10,10,10,1)' \) \
    -compose multiply -composite \
    \( -size 640x640 xc:none -fill "${raised}" -draw "circle 320,320 320,16" \) \
    -gravity center -compose over -composite \
    \( -size 640x640 xc:none -fill none -stroke "${color8}" -strokewidth 8 \
       -draw "circle 320,320 320,216" -draw "circle 320,320 320,160" -draw "circle 320,320 320,104" \
       -blur 0x1.6 \) -compose over -composite \
    \( -size 640x640 xc:none -fill none -stroke "${accent}" -strokewidth 16 \
       -draw "circle 320,320 320,24" -blur 0x5 \) -compose over -composite \
    \( -size 2560x1600 xc:"${bg_tint}" -alpha set -channel A -evaluate set 3% +channel \) \
    -compose over -composite \
    "$out/backgrounds/2-trackpoint.jpg"
}


generate_heritage() {
  local out="$1"
  local bg_tint="${P[bg_tint]}"

  # Signature 3: the shared original wallpaper, rescaled and tinted.
  magick assets/source/BG1.png \
    -resize 2560x1600^ -gravity center -extent 2560x1600 \
    -modulate 100,85 \
    \( +clone -fill "${bg_tint}" -colorize 100 \) \
    -compose blend -define compose:args=12x88 -composite \
    "$out/backgrounds/3-heritage.jpg"
}

populate_backgrounds() {
  local name="$1" out="$2" dir copied=0
  local tint="${P[bg_tint]}"

  tint_photo() {
    local img="$1"
    magick "$img" \
      \( +clone -fill "$tint" -colorize 100 \) \
      -compose blend -define compose:args=8x92 -composite \
      "$img"
  }

  # User wallpapers win: anything in assets/backgrounds/<variant>/ or
  # assets/backgrounds/all/ ships INSTEAD of the generated set, tinted with
  # the variant accent so the identity carries into photos too.
  for dir in "assets/backgrounds/$name" "assets/backgrounds/all"; do
    if compgen -G "$dir/*" >/dev/null; then
      cp -- "$dir"/* "$out/backgrounds/"
      for img in "$out/backgrounds"/*; do
        tint_photo "$img"
      done
      copied=1
    fi
  done

  if ((!copied)); then
    generate_weave "$out"
    generate_trackpoint "$out"
    generate_heritage "$out"
  fi
}

generate_assets() {
  local name="$1" out="$2"
  local accent="${P[accent]}" background="${P[background]}" foreground="${P[foreground]}"

  populate_backgrounds "$name" "$out"

  # Picker preview: first background (sort order = what omarchy shows first)
  # + accent stripe + 16-swatch ANSI strip. 1600x900 (16:9) 8-bit PNG — the
  # picker thumbnailer targets 1536x864, and its lazy path hands Qt the
  # original file, which must be 8-bit or the card renders blank.
  local first_bg
  first_bg=$(find "$out/backgrounds" -maxdepth 1 -type f | sort | head -1)
  [[ -n "$first_bg" ]] || die "$name: no backgrounds produced"

  local swatches=()
  for i in $(seq 0 15); do
    swatches+=(\( -size 100x52 xc:"${P[color$i]}" \))
  done
  magick \
    \( "$first_bg" -resize 1600x840^ -gravity center -extent 1600x840 \) \
    \( -size 1600x8 xc:"${accent}" \) \
    \( "${swatches[@]}" +append \) \
    -append -depth 8 "$out/preview.png"

  # 4) Plymouth unlock glyph + its picker preview.
  local font
  font=$(fc-match -f '%{file}' 'JetBrainsMono Nerd Font:bold')
  magick -size 512x512 xc:none \
    \( -size 512x512 xc:none -stroke "${accent}" -strokewidth 5 \
       -draw "circle 256,256 256,196" -blur 0x2 \) \
    -compose over -composite \
    -gravity center -font "$font" -pointsize 220 -fill "${foreground}" -annotate 0 'X1' \
    -depth 8 "$out/unlock.png"
  magick "$out/unlock.png" -background "${background}" -flatten -depth 8 "$out/preview-unlock.png"
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
