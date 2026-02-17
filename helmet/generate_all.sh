#!/usr/bin/env bash
# Generate all helmet assets for web, mobile, and social media.
#
# Output structure per flavor:
#   <flavor>/
#     light/                          (for light backgrounds)
#       favicon.ico                   (16+32+48 multi-size)
#       favicon-16x16.png
#       favicon-32x32.png
#       apple-touch-icon.png          (180×180)
#       android-chrome-192x192.png
#       android-chrome-512x512.png
#       maskable-512x512.png          (icon with safe-zone padding)
#       mstile-150x150.png
#       og-image.jpg                  (1200×630, white bg)
#       logo-64.png
#       logo-128.png
#       logo-256.png
#       logo-512.png
#       logo-1024.png
#       site.webmanifest
#       browserconfig.xml
#     dark/                           (for dark backgrounds)
#       ...same files...              (og-image on black bg)
#     favicon.svg                     (auto light/dark via prefers-color-scheme)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SVG_SOURCE="$SCRIPT_DIR/helmet.svg"
OUT_DIR="${1:-$SCRIPT_DIR}"
COUNT=0

# ── Dependencies ────────────────────────────────────────────────────────────
command -v rsvg-convert &>/dev/null || { echo "Error: rsvg-convert required (brew install librsvg)" >&2; exit 1; }
command -v magick &>/dev/null || { echo "Error: ImageMagick 7 required (brew install imagemagick)" >&2; exit 1; }

# ── Gradient direction (diagonal) ──────────────────────────────────────────
GX1=0; GY1=20480; GX2=20480; GY2=0

# ── build_colored_svg HEART THICK THIN BUBBLE ──────────────────────────────
# Creates a temp SVG with injected fills. Prints its path to stdout.
# Caller is responsible for cleanup.
build_colored_svg() {
  local heart="$1" thick="$2" thin="$3" bubble="$4"
  local defs="" style=""

  _fill() {
    local class="$1" color="$2" id="grad-${1}"
    if [[ "$color" == *:* ]]; then
      IFS=: read -ra stops <<< "$color"
      local n=${#stops[@]}
      defs+="<linearGradient id=\"${id}\" gradientUnits=\"userSpaceOnUse\""
      defs+=" x1=\"${GX1}\" y1=\"${GY1}\" x2=\"${GX2}\" y2=\"${GY2}\">"
      for i in "${!stops[@]}"; do
        local pct; if (( n == 1 )); then pct=0; else pct=$(( i * 100 / (n - 1) )); fi
        defs+="<stop offset=\"${pct}%\" stop-color=\"${stops[$i]}\"/>"
      done
      defs+="</linearGradient>"
      style+=".${class}{fill:url(#${id})}"
    else
      style+=".${class}{fill:${color}}"
    fi
  }

  _fill "heart"      "$heart"
  _fill "thick-band" "$thick"
  _fill "thin-band"  "$thin"
  _fill "bubble"     "$bubble"

  local inject=""
  [[ -n "$defs" ]] && inject+="<defs>${defs}</defs>"
  inject+="<style>${style}</style>"

  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/helmet_XXXXXX")
  awk -v inject="$inject" '/<\/svg>/{ print inject }{ print }' "$SVG_SOURCE" > "$tmp"
  echo "$tmp"
}

# ── gen_assets DIR BG_COLOR SVG_PATH ───────────────────────────────────────
# Generates all raster assets for one theme (light or dark).
gen_assets() {
  local dir="$1" bg="$2" svg="$3"
  mkdir -p "$dir"

  # ── Logos ──
  for s in 64 128 256 512 1024; do
    rsvg-convert -w "$s" -h "$s" -o "$dir/logo-${s}.png" "$svg"
  done

  # ── Favicon PNGs ──
  rsvg-convert -w 16 -h 16 -o "$dir/favicon-16x16.png" "$svg"
  rsvg-convert -w 32 -h 32 -o "$dir/favicon-32x32.png" "$svg"
  local tmp48; tmp48=$(mktemp "${TMPDIR:-/tmp}/fav48_XXXXXX")
  rsvg-convert -w 48 -h 48 -o "$tmp48" "$svg"

  # ── favicon.ico (multi-size) ──
  magick "$dir/favicon-16x16.png" "$dir/favicon-32x32.png" "$tmp48" "$dir/favicon.ico"
  rm -f "$tmp48"

  # ── Apple Touch Icon ──
  rsvg-convert -w 180 -h 180 -o "$dir/apple-touch-icon.png" "$svg"

  # ── Android Chrome ──
  rsvg-convert -w 192 -h 192 -o "$dir/android-chrome-192x192.png" "$svg"
  rsvg-convert -w 512 -h 512 -o "$dir/android-chrome-512x512.png" "$svg"

  # ── Maskable Icon (icon ~70% of canvas, centered on bg) ──
  local tmp_mask; tmp_mask=$(mktemp "${TMPDIR:-/tmp}/mask_XXXXXX")
  rsvg-convert -w 360 -h 360 -o "$tmp_mask" "$svg"
  magick -size 512x512 "xc:${bg}" "$tmp_mask" -gravity center -composite "$dir/maskable-512x512.png"
  rm -f "$tmp_mask"

  # ── MS Tile ──
  rsvg-convert -w 150 -h 150 -o "$dir/mstile-150x150.png" "$svg"

  # ── OG Image (1200×630, icon centered on bg) ──
  local tmp_og; tmp_og=$(mktemp "${TMPDIR:-/tmp}/og_XXXXXX")
  rsvg-convert -w 400 -h 400 -o "$tmp_og" "$svg"
  magick -size 1200x630 "xc:${bg}" "$tmp_og" -gravity center -composite -quality 90 "$dir/og-image.jpg"
  rm -f "$tmp_og"

  # ── site.webmanifest ──
  cat > "$dir/site.webmanifest" << 'EOF'
{
  "icons": [
    { "src": "android-chrome-192x192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "android-chrome-512x512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "maskable-512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
EOF

  # ── browserconfig.xml ──
  cat > "$dir/browserconfig.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<browserconfig>
  <msapplication>
    <tile>
      <square150x150logo src="mstile-150x150.png"/>
    </tile>
  </msapplication>
</browserconfig>
EOF
}

# ── gen_favicon_svg DIR L_HEART L_THICK L_THIN L_BUBBLE D_HEART D_THICK D_THIN D_BUBBLE
# Creates a single favicon.svg that auto-switches light/dark via CSS media query.
gen_favicon_svg() {
  local dir="$1"; shift
  local lh="$1" ltk="$2" ltn="$3" lb="$4"; shift 4
  local dh="$1" dtk="$2" dtn="$3" db="$4"

  local defs="" light_css="" dark_css=""

  _fav_fill() {
    local class="$1" color="$2" mode="$3"
    local id="grad-${class}-${mode}"
    if [[ "$color" == *:* ]]; then
      IFS=: read -ra stops <<< "$color"
      local n=${#stops[@]}
      defs+="<linearGradient id=\"${id}\" gradientUnits=\"userSpaceOnUse\""
      defs+=" x1=\"${GX1}\" y1=\"${GY1}\" x2=\"${GX2}\" y2=\"${GY2}\">"
      for i in "${!stops[@]}"; do
        local pct; if (( n == 1 )); then pct=0; else pct=$(( i * 100 / (n - 1) )); fi
        defs+="<stop offset=\"${pct}%\" stop-color=\"${stops[$i]}\"/>"
      done
      defs+="</linearGradient>"
      eval "${mode}_css+='.${class}{fill:url(#${id})}'"
    else
      eval "${mode}_css+='.${class}{fill:${color}}'"
    fi
  }

  _fav_fill "heart"      "$lh"  "light"
  _fav_fill "thick-band" "$ltk" "light"
  _fav_fill "thin-band"  "$ltn" "light"
  _fav_fill "bubble"     "$lb"  "light"
  _fav_fill "heart"      "$dh"  "dark"
  _fav_fill "thick-band" "$dtk" "dark"
  _fav_fill "thin-band"  "$dtn" "dark"
  _fav_fill "bubble"     "$db"  "dark"

  local inject=""
  [[ -n "$defs" ]] && inject+="<defs>${defs}</defs>"
  inject+="<style>"
  inject+="@media(prefers-color-scheme:light){${light_css}}"
  inject+="@media(prefers-color-scheme:dark){${dark_css}}"
  inject+="</style>"

  awk -v inject="$inject" '/<\/svg>/{ print inject }{ print }' "$SVG_SOURCE" > "$dir/favicon.svg"
}

# ── flavor NAME  L_HEART L_THICK L_THIN L_BUBBLE  D_HEART D_THICK D_THIN D_BUBBLE
# Main entry: generates all assets (light + dark + favicon.svg) for one flavor.
flavor() {
  local name="$1"; shift
  local lh="$1" ltk="$2" ltn="$3" lb="$4"; shift 4
  local dh="$1" dtk="$2" dtn="$3" db="$4"

  echo "$name/"

  local light_svg dark_svg
  light_svg=$(build_colored_svg "$lh" "$ltk" "$ltn" "$lb")
  dark_svg=$(build_colored_svg "$dh" "$dtk" "$dtn" "$db")

  gen_assets "$OUT_DIR/$name/light" "white" "$light_svg"
  echo "  ✓ light"
  gen_assets "$OUT_DIR/$name/dark" "black" "$dark_svg"
  echo "  ✓ dark"

  gen_favicon_svg "$OUT_DIR/$name" "$lh" "$ltk" "$ltn" "$lb" "$dh" "$dtk" "$dtn" "$db"
  echo "  ✓ favicon.svg"

  rm -f "$light_svg" "$dark_svg"
  COUNT=$((COUNT + 1))
}

echo "Generating helmet assets in $OUT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ══════════════════════════════════════════════════════════════════════════════
# Monochrome
# ══════════════════════════════════════════════════════════════════════════════

flavor "black" \
  "#000000" "#000000" "#000000" "#000000" \
  "#000000" "#000000" "#000000" "#000000"

flavor "white" \
  "#FFFFFF" "#FFFFFF" "#FFFFFF" "#FFFFFF" \
  "#FFFFFF" "#FFFFFF" "#FFFFFF" "#FFFFFF"

# ══════════════════════════════════════════════════════════════════════════════
# Single colors
# ══════════════════════════════════════════════════════════════════════════════

flavor "blue" \
  "#004080" "#004080:#0066CC:#0099FF" "#004080:#0066CC:#0099FF" "#004080" \
  "#66CCFF" "#0099FF:#33BBFF:#66CCFF" "#0099FF:#33BBFF:#66CCFF" "#66CCFF"

flavor "green" \
  "#007A54" "#007A54:#00B377:#00E5A0" "#007A54:#00B377:#00E5A0" "#007A54" \
  "#80FFD4" "#00E5A0:#40EFBF:#80FFD4" "#00E5A0:#40EFBF:#80FFD4" "#80FFD4"

flavor "purple" \
  "#4A0072" "#4A0072:#6C128E:#8E24AA" "#4A0072:#6C128E:#8E24AA" "#4A0072" \
  "#CE93D8" "#8E24AA:#AE5CBC:#CE93D8" "#8E24AA:#AE5CBC:#CE93D8" "#CE93D8"

flavor "red" \
  "#8B0000" "#8B0000:#CC0000:#FF1A1A" "#8B0000:#CC0000:#FF1A1A" "#8B0000" \
  "#FF8A80" "#FF1A1A:#FF5252:#FF8A80" "#FF1A1A:#FF5252:#FF8A80" "#FF8A80"

flavor "orange" \
  "#BF5700" "#BF5700:#E67300:#FF9933" "#BF5700:#E67300:#FF9933" "#BF5700" \
  "#FFCC80" "#FF9933:#FFB347:#FFCC80" "#FF9933:#FFB347:#FFCC80" "#FFCC80"

flavor "gold" \
  "#B8860B" "#B8860B:#DAA520:#FFD700" "#B8860B:#DAA520:#FFD700" "#B8860B" \
  "#FFE082" "#FFD700:#FFDF4A:#FFE082" "#FFD700:#FFDF4A:#FFE082" "#FFE082"

flavor "pink" \
  "#AD1457" "#AD1457:#D81B60:#F06292" "#AD1457:#D81B60:#F06292" "#AD1457" \
  "#F8BBD0" "#F06292:#F48FB1:#F8BBD0" "#F06292:#F48FB1:#F8BBD0" "#F8BBD0"

flavor "teal" \
  "#00695C" "#00695C:#00897B:#26A69A" "#00695C:#00897B:#26A69A" "#00695C" \
  "#80CBC4" "#26A69A:#4DB6AC:#80CBC4" "#26A69A:#4DB6AC:#80CBC4" "#80CBC4"

flavor "cyan" \
  "#006064" "#006064:#00838F:#00BCD4" "#006064:#00838F:#00BCD4" "#006064" \
  "#80DEEA" "#00BCD4:#4DD0E1:#80DEEA" "#00BCD4:#4DD0E1:#80DEEA" "#80DEEA"

flavor "indigo" \
  "#1A237E" "#1A237E:#283593:#3949AB" "#1A237E:#283593:#3949AB" "#1A237E" \
  "#9FA8DA" "#3949AB:#5C6BC0:#9FA8DA" "#3949AB:#5C6BC0:#9FA8DA" "#9FA8DA"

flavor "coral" \
  "#BF360C" "#BF360C:#E64A19:#FF7043" "#BF360C:#E64A19:#FF7043" "#BF360C" \
  "#FFAB91" "#FF7043:#FF8A65:#FFAB91" "#FF7043:#FF8A65:#FFAB91" "#FFAB91"

flavor "lime" \
  "#558B2F" "#558B2F:#7CB342:#9CCC65" "#558B2F:#7CB342:#9CCC65" "#558B2F" \
  "#C5E1A5" "#9CCC65:#AED581:#C5E1A5" "#9CCC65:#AED581:#C5E1A5" "#C5E1A5"

flavor "amber" \
  "#FF6F00" "#FF6F00:#FF8F00:#FFA000" "#FF6F00:#FF8F00:#FFA000" "#FF6F00" \
  "#FFE082" "#FFA000:#FFB300:#FFCA28" "#FFA000:#FFB300:#FFCA28" "#FFE082"

flavor "rose" \
  "#880E4F" "#880E4F:#C2185B:#E91E63" "#880E4F:#C2185B:#E91E63" "#880E4F" \
  "#F48FB1" "#E91E63:#EC407A:#F48FB1" "#E91E63:#EC407A:#F48FB1" "#F48FB1"

flavor "slate" \
  "#37474F" "#37474F:#546E7A:#78909C" "#37474F:#546E7A:#78909C" "#37474F" \
  "#B0BEC5" "#78909C:#90A4AE:#B0BEC5" "#78909C:#90A4AE:#B0BEC5" "#B0BEC5"

flavor "brown" \
  "#4E342E" "#4E342E:#6D4C41:#8D6E63" "#4E342E:#6D4C41:#8D6E63" "#4E342E" \
  "#BCAAA4" "#8D6E63:#A1887F:#BCAAA4" "#8D6E63:#A1887F:#BCAAA4" "#BCAAA4"

flavor "magenta" \
  "#6A1B9A" "#6A1B9A:#9C27B0:#BA68C8" "#6A1B9A:#9C27B0:#BA68C8" "#6A1B9A" \
  "#E1BEE7" "#BA68C8:#CE93D8:#E1BEE7" "#BA68C8:#CE93D8:#E1BEE7" "#E1BEE7"

flavor "violet" \
  "#4527A0" "#4527A0:#5E35B1:#7E57C2" "#4527A0:#5E35B1:#7E57C2" "#4527A0" \
  "#B39DDB" "#7E57C2:#9575CD:#B39DDB" "#7E57C2:#9575CD:#B39DDB" "#B39DDB"

flavor "sky" \
  "#01579B" "#01579B:#0288D1:#03A9F4" "#01579B:#0288D1:#03A9F4" "#01579B" \
  "#81D4FA" "#03A9F4:#29B6F6:#81D4FA" "#03A9F4:#29B6F6:#81D4FA" "#81D4FA"

flavor "emerald" \
  "#1B5E20" "#1B5E20:#2E7D32:#43A047" "#1B5E20:#2E7D32:#43A047" "#1B5E20" \
  "#A5D6A7" "#43A047:#66BB6A:#A5D6A7" "#43A047:#66BB6A:#A5D6A7" "#A5D6A7"

# ══════════════════════════════════════════════════════════════════════════════
# Two-color combos
# ══════════════════════════════════════════════════════════════════════════════

# Thick=blue, thin=green
flavor "blue_green" \
  "#4A0072" "#004080:#0066CC:#0099FF" "#007A54:#00B377:#00E5A0" "#1A237E" \
  "#CE93D8" "#0099FF:#33BBFF:#66CCFF" "#00E5A0:#40EFBF:#80FFD4" "#7B8AFF"

# Heart=blue, thick=green, thin=indigo, bubble=purple
flavor "3_colors" \
  "#0066CC" "#00B377" "#1A237E" "#6A1B9A" \
  "#0099FF" "#80FFD4" "#7B8AFF" "#CE93D8"

# Thick=red, thin=orange
flavor "fire" \
  "#8B0000" "#8B0000:#CC0000:#FF1A1A" "#BF5700:#E67300:#FF9933" "#FF6F00" \
  "#FF8A80" "#FF1A1A:#FF5252:#FF8A80" "#FF9933:#FFB347:#FFCC80" "#FFCA28"

# Thick=pink, thin=purple
flavor "pink_purple" \
  "#880E4F" "#AD1457:#D81B60:#F06292" "#4A0072:#6C128E:#8E24AA" "#4527A0" \
  "#F8BBD0" "#F06292:#F48FB1:#F8BBD0" "#8E24AA:#AE5CBC:#CE93D8" "#B39DDB"

# Thick=teal, thin=blue
flavor "ocean" \
  "#006064" "#00695C:#00897B:#26A69A" "#004080:#0066CC:#0099FF" "#01579B" \
  "#80DEEA" "#26A69A:#4DB6AC:#80CBC4" "#0099FF:#33BBFF:#66CCFF" "#81D4FA"

# Thick=orange, thin=gold
flavor "sunset" \
  "#BF360C" "#BF5700:#E67300:#FF9933" "#B8860B:#DAA520:#FFD700" "#FF6F00" \
  "#FFAB91" "#FF9933:#FFB347:#FFCC80" "#FFD700:#FFDF4A:#FFE082" "#FFCA28"

# Thick=emerald, thin=gold
flavor "forest" \
  "#1B5E20" "#1B5E20:#2E7D32:#43A047" "#B8860B:#DAA520:#FFD700" "#558B2F" \
  "#A5D6A7" "#43A047:#66BB6A:#A5D6A7" "#FFD700:#FFDF4A:#FFE082" "#C5E1A5"

# Thick=indigo, thin=cyan
flavor "arctic" \
  "#1A237E" "#1A237E:#283593:#3949AB" "#006064:#00838F:#00BCD4" "#00695C" \
  "#9FA8DA" "#3949AB:#5C6BC0:#9FA8DA" "#00BCD4:#4DD0E1:#80DEEA" "#80CBC4"

# Thick=red, thin=purple
flavor "berry" \
  "#8B0000" "#8B0000:#CC0000:#FF1A1A" "#4A0072:#6C128E:#8E24AA" "#4527A0" \
  "#FF8A80" "#FF1A1A:#FF5252:#FF8A80" "#8E24AA:#AE5CBC:#CE93D8" "#B39DDB"

# Thick=coral, thin=teal
flavor "tropical" \
  "#BF360C" "#BF360C:#E64A19:#FF7043" "#00695C:#00897B:#26A69A" "#006064" \
  "#FFAB91" "#FF7043:#FF8A65:#FFAB91" "#26A69A:#4DB6AC:#80CBC4" "#80DEEA"

# Thick=violet, thin=pink
flavor "lavender" \
  "#4527A0" "#4527A0:#5E35B1:#7E57C2" "#AD1457:#D81B60:#F06292" "#880E4F" \
  "#B39DDB" "#7E57C2:#9575CD:#B39DDB" "#F06292:#F48FB1:#F8BBD0" "#F48FB1"

# Thick=lime, thin=cyan
flavor "mint" \
  "#558B2F" "#558B2F:#7CB342:#9CCC65" "#006064:#00838F:#00BCD4" "#00695C" \
  "#C5E1A5" "#9CCC65:#AED581:#C5E1A5" "#00BCD4:#4DD0E1:#80DEEA" "#80CBC4"

# ══════════════════════════════════════════════════════════════════════════════
# Multi-color gradient mixes
# ══════════════════════════════════════════════════════════════════════════════

# Aurora — Green → Blue → Indigo
flavor "aurora" \
  "#1A237E" "#007A54:#004080:#1A237E" "#007A54:#004080:#1A237E" "#1A237E" \
  "#7B8AFF" "#00E5A0:#0099FF:#304FFE" "#00E5A0:#0099FF:#304FFE" "#304FFE"

# Nebula — Indigo → Violet → Blue
flavor "nebula" \
  "#4A0072" "#1A237E:#4A0072:#004080" "#1A237E:#4A0072:#004080" "#1A237E" \
  "#CE93D8" "#304FFE:#8E24AA:#0099FF" "#304FFE:#8E24AA:#0099FF" "#304FFE"

# Cosmic — Green → Violet → Blue
flavor "cosmic" \
  "#4A0072" "#007A54:#4A0072:#004080" "#007A54:#4A0072:#004080" "#4A0072" \
  "#CE93D8" "#00E5A0:#8E24AA:#0099FF" "#00E5A0:#8E24AA:#0099FF" "#8E24AA"

# Flame — Red → Orange → Gold
flavor "flame" \
  "#8B0000" "#8B0000:#BF5700:#B8860B" "#8B0000:#BF5700:#B8860B" "#BF5700" \
  "#FF8A80" "#FF5252:#FFB347:#FFD700" "#FF5252:#FFB347:#FFD700" "#FFB347"

# Dusk — Orange → Rose → Purple
flavor "dusk" \
  "#880E4F" "#BF5700:#880E4F:#4A0072" "#BF5700:#880E4F:#4A0072" "#880E4F" \
  "#FFCC80" "#FFB347:#EC407A:#CE93D8" "#FFB347:#EC407A:#CE93D8" "#EC407A"

# Deep — Teal → Blue → Indigo
flavor "deep" \
  "#1A237E" "#00695C:#004080:#1A237E" "#00695C:#004080:#1A237E" "#004080" \
  "#9FA8DA" "#4DB6AC:#33BBFF:#5C6BC0" "#4DB6AC:#33BBFF:#5C6BC0" "#33BBFF"

# Reef — Cyan → Teal → Emerald
flavor "reef" \
  "#006064" "#006064:#00695C:#1B5E20" "#006064:#00695C:#1B5E20" "#00695C" \
  "#80DEEA" "#4DD0E1:#4DB6AC:#66BB6A" "#4DD0E1:#4DB6AC:#66BB6A" "#4DB6AC"

# Electric — Cyan → Magenta → Yellow
flavor "electric" \
  "#006064" "#00BCD4:#9C27B0:#FFD700" "#00BCD4:#9C27B0:#FFD700" "#9C27B0" \
  "#80DEEA" "#4DD0E1:#CE93D8:#FFE082" "#4DD0E1:#CE93D8:#FFE082" "#CE93D8"

# Plasma — Pink → Blue → Lime
flavor "plasma" \
  "#AD1457" "#D81B60:#0066CC:#7CB342" "#D81B60:#0066CC:#7CB342" "#0066CC" \
  "#F8BBD0" "#F06292:#33BBFF:#AED581" "#F06292:#33BBFF:#AED581" "#33BBFF"

# Terra — Brown → Amber → Lime
flavor "terra" \
  "#4E342E" "#4E342E:#FF6F00:#558B2F" "#4E342E:#FF6F00:#558B2F" "#FF6F00" \
  "#BCAAA4" "#A1887F:#FFCA28:#AED581" "#A1887F:#FFCA28:#AED581" "#FFCA28"

# Stone — Slate → Brown → Teal
flavor "stone" \
  "#37474F" "#37474F:#4E342E:#00695C" "#37474F:#4E342E:#00695C" "#4E342E" \
  "#B0BEC5" "#90A4AE:#A1887F:#4DB6AC" "#90A4AE:#A1887F:#4DB6AC" "#A1887F"

# Prism — Red → Green → Blue
flavor "prism" \
  "#8B0000" "#CC0000:#00B377:#0066CC" "#CC0000:#00B377:#0066CC" "#00B377" \
  "#FF8A80" "#FF5252:#80FFD4:#33BBFF" "#FF5252:#80FFD4:#33BBFF" "#80FFD4"

# Spectrum — Orange → Violet → Cyan
flavor "spectrum" \
  "#BF5700" "#E67300:#5E35B1:#00838F" "#E67300:#5E35B1:#00838F" "#5E35B1" \
  "#FFCC80" "#FFB347:#9575CD:#4DD0E1" "#FFB347:#9575CD:#4DD0E1" "#9575CD"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Done: $COUNT flavors (light + dark + favicon.svg each)"
