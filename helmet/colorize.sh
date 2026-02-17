#!/usr/bin/env bash
# Generate PNG and JPG from helmet.svg with custom fill colors or gradients.
#
# Usage:
#   ./colorize.sh [OPTIONS]
#
# Color format:
#   Solid:    "#0099FF"
#   Gradient: "#00E5A0:#0099FF:#304FFE"   (colon-separated stops)
#
# Options:
#   --heart COLOR       Fill for the heart shape          (default: #000000)
#   --thick-band COLOR  Fill for thick-band shapes        (default: #000000)
#   --thin-band COLOR   Fill for thin-band shapes         (default: #000000)
#   --bubble COLOR      Fill for bubble shapes            (default: #000000)
#   --direction DIR     Gradient direction: lr rl tb bt diag diag-rev (default: lr)
#   --output PATH       Output basename without extension (default: helmet_out)
#   --size WxH          Output size in pixels             (default: SVG native)
#   --bg COLOR          JPG background color              (default: white)
#   --help              Show this help
#
# Requires: rsvg-convert (librsvg) or inkscape, plus magick (ImageMagick) or sips.
#   Install: brew install librsvg imagemagick
#
# Examples:
#   ./colorize.sh --thick-band "#0099FF" --bubble "#304FFE"
#   ./colorize.sh --thick-band "#00E5A0:#0099FF:#304FFE" --direction lr --size 1024x1024
#   ./colorize.sh --heart "#8E24AA" --thick-band "#00E5A0:#0099FF" --thin-band "#0099FF:#304FFE" --bubble "#304FFE"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SVG_SOURCE="$SCRIPT_DIR/helmet.svg"

# Defaults
COLOR_HEART="#000000"
COLOR_THICK_BAND="#000000"
COLOR_THIN_BAND="#000000"
COLOR_BUBBLE="#000000"
OUTPUT="helmet_out"
SIZE=""
BG="white"
DIRECTION="lr"

usage() {
  grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --heart)      COLOR_HEART="$2";      shift 2 ;;
    --thick-band) COLOR_THICK_BAND="$2"; shift 2 ;;
    --thin-band)  COLOR_THIN_BAND="$2";  shift 2 ;;
    --bubble)     COLOR_BUBBLE="$2";     shift 2 ;;
    --direction)  DIRECTION="$2";        shift 2 ;;
    --output)     OUTPUT="$2";           shift 2 ;;
    --size)       SIZE="$2";             shift 2 ;;
    --bg)         BG="$2";              shift 2 ;;
    --help|-h)    usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Validate source SVG
[[ -f "$SVG_SOURCE" ]] || { echo "Error: $SVG_SOURCE not found" >&2; exit 1; }

# ── Gradient direction ────────────────────────────────────────────────────────
# Path coordinate space: 0–20480 in both axes.
# The <g> transform is translate(0,2048) scale(0.1,-0.1), so y is flipped:
#   visual top    = high y in path space
#   visual bottom = low y in path space
case "$DIRECTION" in
  lr)       GX1=0;     GY1=10240; GX2=20480; GY2=10240 ;;
  rl)       GX1=20480; GY1=10240; GX2=0;     GY2=10240 ;;
  tb)       GX1=10240; GY1=20480; GX2=10240; GY2=0     ;;
  bt)       GX1=10240; GY1=0;     GX2=10240; GY2=20480 ;;
  diag)     GX1=0;     GY1=20480; GX2=20480; GY2=0     ;;
  diag-rev) GX1=20480; GY1=0;     GX2=0;     GY2=20480 ;;
  *) echo "Unknown direction: $DIRECTION (use lr rl tb bt diag diag-rev)" >&2; exit 1 ;;
esac

# ── Build SVG <defs> and <style> ─────────────────────────────────────────────
DEFS=""
STYLE=""

build_fill() {
  local class="$1" color="$2" id="grad-${1}"

  if [[ "$color" == *:* ]]; then
    # Gradient: colon-separated color stops
    IFS=: read -ra stops <<< "$color"
    local n=${#stops[@]}

    DEFS+="<linearGradient id=\"${id}\" gradientUnits=\"userSpaceOnUse\""
    DEFS+=" x1=\"${GX1}\" y1=\"${GY1}\" x2=\"${GX2}\" y2=\"${GY2}\">"
    for i in "${!stops[@]}"; do
      local pct
      if (( n == 1 )); then pct=0; else pct=$(( i * 100 / (n - 1) )); fi
      DEFS+="<stop offset=\"${pct}%\" stop-color=\"${stops[$i]}\"/>"
    done
    DEFS+="</linearGradient>"
    STYLE+=".${class}{fill:url(#${id})}"
  else
    # Solid color
    STYLE+=".${class}{fill:${color}}"
  fi
}

build_fill "heart"      "$COLOR_HEART"
build_fill "thick-band" "$COLOR_THICK_BAND"
build_fill "thin-band"  "$COLOR_THIN_BAND"
build_fill "bubble"     "$COLOR_BUBBLE"

# Assemble the XML to inject
INJECT=""
[[ -n "$DEFS" ]] && INJECT+="<defs>${DEFS}</defs>"
INJECT+="<style>${STYLE}</style>"

# ── Create temp SVG ──────────────────────────────────────────────────────────
TMP_SVG=$(mktemp "${TMPDIR:-/tmp}/helmet_XXXXXX.svg")
trap 'rm -f "$TMP_SVG"' EXIT

awk -v inject="$INJECT" '
  /<\/svg>/ { print inject }
  { print }
' "$SVG_SOURCE" > "$TMP_SVG"

PNG_FILE="${OUTPUT}.png"
JPG_FILE="${OUTPUT}.jpg"

# ── PNG rendering ─────────────────────────────────────────────────────────────
render_png() {
  if command -v rsvg-convert &>/dev/null; then
    local args=(-o "$PNG_FILE")
    if [[ -n "$SIZE" ]]; then
      args+=(-w "${SIZE%x*}" -h "${SIZE#*x}")
    fi
    rsvg-convert "${args[@]}" "$TMP_SVG"

  elif command -v inkscape &>/dev/null; then
    local args=("--export-type=png" "--export-filename=$PNG_FILE")
    if [[ -n "$SIZE" ]]; then
      args+=("--export-width=${SIZE%x*}" "--export-height=${SIZE#*x}")
    fi
    inkscape "${args[@]}" "$TMP_SVG" 2>/dev/null

  else
    echo "Error: rsvg-convert or inkscape is required to render PNG." >&2
    echo "       brew install librsvg" >&2
    exit 1
  fi
}

# ── JPG conversion ────────────────────────────────────────────────────────────
render_jpg() {
  if command -v magick &>/dev/null; then
    magick "$PNG_FILE" -background "$BG" -flatten "$JPG_FILE"
  elif command -v convert &>/dev/null; then
    convert "$PNG_FILE" -background "$BG" -flatten "$JPG_FILE"
  elif command -v sips &>/dev/null; then
    sips -s format jpeg "$PNG_FILE" --out "$JPG_FILE" >/dev/null
  else
    echo "Warning: ImageMagick or sips required for JPG output. Skipping." >&2
    return 1
  fi
}

# ── Run ───────────────────────────────────────────────────────────────────────
echo "Fills:"
echo "  heart:      $COLOR_HEART"
echo "  thick-band: $COLOR_THICK_BAND"
echo "  thin-band:  $COLOR_THIN_BAND"
echo "  bubble:     $COLOR_BUBBLE"
[[ "$DIRECTION" != "lr" ]] && echo "  direction:  $DIRECTION"
echo ""

render_png
echo "PNG: $PNG_FILE"

render_jpg && echo "JPG: $JPG_FILE"
