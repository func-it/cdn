#!/usr/bin/env bash
# Generate all helmet variants: 2 themes (light/dark) × many color modes.
#
# Output structure:
#   <color_mode>/helmet_<theme>.png
#   <color_mode>/helmet_<theme>.jpg

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COLORIZE="$SCRIPT_DIR/colorize.sh"
OUT_DIR="${1:-$SCRIPT_DIR}"
SIZE="1024x1024"
DIR="diag"
COUNT=0

# ── Helper ────────────────────────────────────────────────────────────────────
gen() {
  local folder="$1" name="$2" heart="$3" thick="$4" thin="$5" bubble="$6"
  local dir="$OUT_DIR/$folder"
  mkdir -p "$dir"
  local bg="white"
  [[ "$name" == *dark* ]] && bg="black"
  "$COLORIZE" \
    --heart "$heart" --thick-band "$thick" --thin-band "$thin" --bubble "$bubble" \
    --direction "$DIR" --size "$SIZE" --bg "$bg" \
    --output "$dir/$name" > /dev/null
  COUNT=$((COUNT + 1))
  echo "  ✓ $folder/$name"
}

echo "Generating helmet variants in $OUT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Black (monochrome) ────────────────────────────────────────────────────
echo "black/"
gen black helmet_light  "#000000" "#000000" "#000000" "#000000"
gen black helmet_dark   "#000000" "#000000" "#000000" "#000000"

# ── 2. White (monochrome) ────────────────────────────────────────────────────
echo "white/"
gen white helmet_light  "#FFFFFF" "#FFFFFF" "#FFFFFF" "#FFFFFF"
gen white helmet_dark   "#FFFFFF" "#FFFFFF" "#FFFFFF" "#FFFFFF"

# ── 3. Blue ──────────────────────────────────────────────────────────────────
# Light: deeper blues (for light backgrounds)
# Dark:  brighter blues (for dark backgrounds)
echo "blue/"
gen blue helmet_light \
  "#004080"                  "#004080:#0066CC:#0099FF" "#004080:#0066CC:#0099FF" "#004080"
gen blue helmet_dark \
  "#66CCFF"                  "#0099FF:#33BBFF:#66CCFF" "#0099FF:#33BBFF:#66CCFF" "#66CCFF"

# ── 4. Green ─────────────────────────────────────────────────────────────────
echo "green/"
gen green helmet_light \
  "#007A54"                  "#007A54:#00B377:#00E5A0" "#007A54:#00B377:#00E5A0" "#007A54"
gen green helmet_dark \
  "#80FFD4"                  "#00E5A0:#40EFBF:#80FFD4" "#00E5A0:#40EFBF:#80FFD4" "#80FFD4"

# ── 5. Purple ────────────────────────────────────────────────────────────────
echo "purple/"
gen purple helmet_light \
  "#4A0072"                  "#4A0072:#6C128E:#8E24AA" "#4A0072:#6C128E:#8E24AA" "#4A0072"
gen purple helmet_dark \
  "#CE93D8"                  "#8E24AA:#AE5CBC:#CE93D8" "#8E24AA:#AE5CBC:#CE93D8" "#CE93D8"

# ── 6. Blue + Green ──────────────────────────────────────────────────────────
# Thick=blue, thin=green, bubbles=indigo accent, heart=purple accent
echo "blue_green/"
gen blue_green helmet_light \
  "#4A0072"                  "#004080:#0066CC:#0099FF" "#007A54:#00B377:#00E5A0" "#1A237E"
gen blue_green helmet_dark \
  "#CE93D8"                  "#0099FF:#33BBFF:#66CCFF" "#00E5A0:#40EFBF:#80FFD4" "#7B8AFF"

# ── 7. 3 Colors (solid brand colors, one per class) ─────────────────────────
# Heart=blue (primary), thick=green, thin=indigo, bubbles=purple
echo "3_colors/"
gen 3_colors helmet_light \
  "#0066CC"                  "#00B377" "#1A237E" "#6A1B9A"
gen 3_colors helmet_dark \
  "#0099FF"                  "#80FFD4" "#7B8AFF" "#CE93D8"

# ── 8. 3 Colors Mixed (3 gradient sub-variants) ─────────────────────────────
echo "3_colors_mixed/"

# Aurora — Vert → Bleu → Indigo
gen 3_colors_mixed helmet_aurora_light \
  "#1A237E"                  "#007A54:#004080:#1A237E" "#007A54:#004080:#1A237E" "#1A237E"
gen 3_colors_mixed helmet_aurora_dark \
  "#7B8AFF"                  "#00E5A0:#0099FF:#304FFE" "#00E5A0:#0099FF:#304FFE" "#304FFE"

# Nebula — Indigo → Violet → Bleu
gen 3_colors_mixed helmet_nebula_light \
  "#4A0072"                  "#1A237E:#4A0072:#004080" "#1A237E:#4A0072:#004080" "#1A237E"
gen 3_colors_mixed helmet_nebula_dark \
  "#CE93D8"                  "#304FFE:#8E24AA:#0099FF" "#304FFE:#8E24AA:#0099FF" "#304FFE"

# Cosmic Wave — Vert → Violet → Bleu
gen 3_colors_mixed helmet_cosmic_light \
  "#4A0072"                  "#007A54:#4A0072:#004080" "#007A54:#4A0072:#004080" "#4A0072"
gen 3_colors_mixed helmet_cosmic_dark \
  "#CE93D8"                  "#00E5A0:#8E24AA:#0099FF" "#00E5A0:#8E24AA:#0099FF" "#8E24AA"

# ── 9. Red ──────────────────────────────────────────────────────────────────
echo "red/"
gen red helmet_light \
  "#8B0000"                  "#8B0000:#CC0000:#FF1A1A" "#8B0000:#CC0000:#FF1A1A" "#8B0000"
gen red helmet_dark \
  "#FF8A80"                  "#FF1A1A:#FF5252:#FF8A80" "#FF1A1A:#FF5252:#FF8A80" "#FF8A80"

# ── 10. Orange ──────────────────────────────────────────────────────────────
echo "orange/"
gen orange helmet_light \
  "#BF5700"                  "#BF5700:#E67300:#FF9933" "#BF5700:#E67300:#FF9933" "#BF5700"
gen orange helmet_dark \
  "#FFCC80"                  "#FF9933:#FFB347:#FFCC80" "#FF9933:#FFB347:#FFCC80" "#FFCC80"

# ── 11. Yellow / Gold ───────────────────────────────────────────────────────
echo "gold/"
gen gold helmet_light \
  "#B8860B"                  "#B8860B:#DAA520:#FFD700" "#B8860B:#DAA520:#FFD700" "#B8860B"
gen gold helmet_dark \
  "#FFE082"                  "#FFD700:#FFDF4A:#FFE082" "#FFD700:#FFDF4A:#FFE082" "#FFE082"

# ── 12. Pink ────────────────────────────────────────────────────────────────
echo "pink/"
gen pink helmet_light \
  "#AD1457"                  "#AD1457:#D81B60:#F06292" "#AD1457:#D81B60:#F06292" "#AD1457"
gen pink helmet_dark \
  "#F8BBD0"                  "#F06292:#F48FB1:#F8BBD0" "#F06292:#F48FB1:#F8BBD0" "#F8BBD0"

# ── 13. Teal ────────────────────────────────────────────────────────────────
echo "teal/"
gen teal helmet_light \
  "#00695C"                  "#00695C:#00897B:#26A69A" "#00695C:#00897B:#26A69A" "#00695C"
gen teal helmet_dark \
  "#80CBC4"                  "#26A69A:#4DB6AC:#80CBC4" "#26A69A:#4DB6AC:#80CBC4" "#80CBC4"

# ── 14. Cyan ────────────────────────────────────────────────────────────────
echo "cyan/"
gen cyan helmet_light \
  "#006064"                  "#006064:#00838F:#00BCD4" "#006064:#00838F:#00BCD4" "#006064"
gen cyan helmet_dark \
  "#80DEEA"                  "#00BCD4:#4DD0E1:#80DEEA" "#00BCD4:#4DD0E1:#80DEEA" "#80DEEA"

# ── 15. Indigo ──────────────────────────────────────────────────────────────
echo "indigo/"
gen indigo helmet_light \
  "#1A237E"                  "#1A237E:#283593:#3949AB" "#1A237E:#283593:#3949AB" "#1A237E"
gen indigo helmet_dark \
  "#9FA8DA"                  "#3949AB:#5C6BC0:#9FA8DA" "#3949AB:#5C6BC0:#9FA8DA" "#9FA8DA"

# ── 16. Coral ───────────────────────────────────────────────────────────────
echo "coral/"
gen coral helmet_light \
  "#BF360C"                  "#BF360C:#E64A19:#FF7043" "#BF360C:#E64A19:#FF7043" "#BF360C"
gen coral helmet_dark \
  "#FFAB91"                  "#FF7043:#FF8A65:#FFAB91" "#FF7043:#FF8A65:#FFAB91" "#FFAB91"

# ── 17. Lime ────────────────────────────────────────────────────────────────
echo "lime/"
gen lime helmet_light \
  "#558B2F"                  "#558B2F:#7CB342:#9CCC65" "#558B2F:#7CB342:#9CCC65" "#558B2F"
gen lime helmet_dark \
  "#C5E1A5"                  "#9CCC65:#AED581:#C5E1A5" "#9CCC65:#AED581:#C5E1A5" "#C5E1A5"

# ── 18. Amber ───────────────────────────────────────────────────────────────
echo "amber/"
gen amber helmet_light \
  "#FF6F00"                  "#FF6F00:#FF8F00:#FFA000" "#FF6F00:#FF8F00:#FFA000" "#FF6F00"
gen amber helmet_dark \
  "#FFE082"                  "#FFA000:#FFB300:#FFCA28" "#FFA000:#FFB300:#FFCA28" "#FFE082"

# ── 19. Rose ────────────────────────────────────────────────────────────────
echo "rose/"
gen rose helmet_light \
  "#880E4F"                  "#880E4F:#C2185B:#E91E63" "#880E4F:#C2185B:#E91E63" "#880E4F"
gen rose helmet_dark \
  "#F48FB1"                  "#E91E63:#EC407A:#F48FB1" "#E91E63:#EC407A:#F48FB1" "#F48FB1"

# ── 20. Slate ───────────────────────────────────────────────────────────────
echo "slate/"
gen slate helmet_light \
  "#37474F"                  "#37474F:#546E7A:#78909C" "#37474F:#546E7A:#78909C" "#37474F"
gen slate helmet_dark \
  "#B0BEC5"                  "#78909C:#90A4AE:#B0BEC5" "#78909C:#90A4AE:#B0BEC5" "#B0BEC5"

# ── 21. Brown ───────────────────────────────────────────────────────────────
echo "brown/"
gen brown helmet_light \
  "#4E342E"                  "#4E342E:#6D4C41:#8D6E63" "#4E342E:#6D4C41:#8D6E63" "#4E342E"
gen brown helmet_dark \
  "#BCAAA4"                  "#8D6E63:#A1887F:#BCAAA4" "#8D6E63:#A1887F:#BCAAA4" "#BCAAA4"

# ── 22. Magenta ─────────────────────────────────────────────────────────────
echo "magenta/"
gen magenta helmet_light \
  "#6A1B9A"                  "#6A1B9A:#9C27B0:#BA68C8" "#6A1B9A:#9C27B0:#BA68C8" "#6A1B9A"
gen magenta helmet_dark \
  "#E1BEE7"                  "#BA68C8:#CE93D8:#E1BEE7" "#BA68C8:#CE93D8:#E1BEE7" "#E1BEE7"

# ── 23. Violet ──────────────────────────────────────────────────────────────
echo "violet/"
gen violet helmet_light \
  "#4527A0"                  "#4527A0:#5E35B1:#7E57C2" "#4527A0:#5E35B1:#7E57C2" "#4527A0"
gen violet helmet_dark \
  "#B39DDB"                  "#7E57C2:#9575CD:#B39DDB" "#7E57C2:#9575CD:#B39DDB" "#B39DDB"

# ── 24. Sky ─────────────────────────────────────────────────────────────────
echo "sky/"
gen sky helmet_light \
  "#01579B"                  "#01579B:#0288D1:#03A9F4" "#01579B:#0288D1:#03A9F4" "#01579B"
gen sky helmet_dark \
  "#81D4FA"                  "#03A9F4:#29B6F6:#81D4FA" "#03A9F4:#29B6F6:#81D4FA" "#81D4FA"

# ── 25. Emerald ─────────────────────────────────────────────────────────────
echo "emerald/"
gen emerald helmet_light \
  "#1B5E20"                  "#1B5E20:#2E7D32:#43A047" "#1B5E20:#2E7D32:#43A047" "#1B5E20"
gen emerald helmet_dark \
  "#A5D6A7"                  "#43A047:#66BB6A:#A5D6A7" "#43A047:#66BB6A:#A5D6A7" "#A5D6A7"

# ══════════════════════════════════════════════════════════════════════════════
# Two-color combos
# ══════════════════════════════════════════════════════════════════════════════

# ── 26. Red + Orange (Fire) ─────────────────────────────────────────────────
# Thick=red, thin=orange, heart=deep red, bubble=amber
echo "fire/"
gen fire helmet_light \
  "#8B0000"                  "#8B0000:#CC0000:#FF1A1A" "#BF5700:#E67300:#FF9933" "#FF6F00"
gen fire helmet_dark \
  "#FF8A80"                  "#FF1A1A:#FF5252:#FF8A80" "#FF9933:#FFB347:#FFCC80" "#FFCA28"

# ── 27. Pink + Purple ───────────────────────────────────────────────────────
# Thick=pink, thin=purple, heart=deep rose, bubble=violet
echo "pink_purple/"
gen pink_purple helmet_light \
  "#880E4F"                  "#AD1457:#D81B60:#F06292" "#4A0072:#6C128E:#8E24AA" "#4527A0"
gen pink_purple helmet_dark \
  "#F8BBD0"                  "#F06292:#F48FB1:#F8BBD0" "#8E24AA:#AE5CBC:#CE93D8" "#B39DDB"

# ── 28. Teal + Blue (Ocean) ─────────────────────────────────────────────────
# Thick=teal, thin=blue, heart=deep cyan, bubble=sky
echo "ocean/"
gen ocean helmet_light \
  "#006064"                  "#00695C:#00897B:#26A69A" "#004080:#0066CC:#0099FF" "#01579B"
gen ocean helmet_dark \
  "#80DEEA"                  "#26A69A:#4DB6AC:#80CBC4" "#0099FF:#33BBFF:#66CCFF" "#81D4FA"

# ── 29. Orange + Yellow (Sunset) ────────────────────────────────────────────
# Thick=orange, thin=gold, heart=deep orange, bubble=amber
echo "sunset/"
gen sunset helmet_light \
  "#BF360C"                  "#BF5700:#E67300:#FF9933" "#B8860B:#DAA520:#FFD700" "#FF6F00"
gen sunset helmet_dark \
  "#FFAB91"                  "#FF9933:#FFB347:#FFCC80" "#FFD700:#FFDF4A:#FFE082" "#FFCA28"

# ── 30. Emerald + Gold (Forest) ─────────────────────────────────────────────
# Thick=emerald, thin=gold, heart=deep green, bubble=amber
echo "forest/"
gen forest helmet_light \
  "#1B5E20"                  "#1B5E20:#2E7D32:#43A047" "#B8860B:#DAA520:#FFD700" "#558B2F"
gen forest helmet_dark \
  "#A5D6A7"                  "#43A047:#66BB6A:#A5D6A7" "#FFD700:#FFDF4A:#FFE082" "#C5E1A5"

# ── 31. Indigo + Cyan (Arctic) ──────────────────────────────────────────────
# Thick=indigo, thin=cyan, heart=deep blue, bubble=teal
echo "arctic/"
gen arctic helmet_light \
  "#1A237E"                  "#1A237E:#283593:#3949AB" "#006064:#00838F:#00BCD4" "#00695C"
gen arctic helmet_dark \
  "#9FA8DA"                  "#3949AB:#5C6BC0:#9FA8DA" "#00BCD4:#4DD0E1:#80DEEA" "#80CBC4"

# ── 32. Red + Purple (Berry) ────────────────────────────────────────────────
# Thick=red, thin=purple, heart=crimson, bubble=violet
echo "berry/"
gen berry helmet_light \
  "#8B0000"                  "#8B0000:#CC0000:#FF1A1A" "#4A0072:#6C128E:#8E24AA" "#4527A0"
gen berry helmet_dark \
  "#FF8A80"                  "#FF1A1A:#FF5252:#FF8A80" "#8E24AA:#AE5CBC:#CE93D8" "#B39DDB"

# ── 33. Coral + Teal (Tropical) ─────────────────────────────────────────────
# Thick=coral, thin=teal, heart=deep orange, bubble=cyan
echo "tropical/"
gen tropical helmet_light \
  "#BF360C"                  "#BF360C:#E64A19:#FF7043" "#00695C:#00897B:#26A69A" "#006064"
gen tropical helmet_dark \
  "#FFAB91"                  "#FF7043:#FF8A65:#FFAB91" "#26A69A:#4DB6AC:#80CBC4" "#80DEEA"

# ── 34. Violet + Pink (Lavender) ────────────────────────────────────────────
# Thick=violet, thin=pink, heart=deep purple, bubble=rose
echo "lavender/"
gen lavender helmet_light \
  "#4527A0"                  "#4527A0:#5E35B1:#7E57C2" "#AD1457:#D81B60:#F06292" "#880E4F"
gen lavender helmet_dark \
  "#B39DDB"                  "#7E57C2:#9575CD:#B39DDB" "#F06292:#F48FB1:#F8BBD0" "#F48FB1"

# ── 35. Lime + Cyan (Mint) ──────────────────────────────────────────────────
# Thick=lime, thin=cyan, heart=green, bubble=teal
echo "mint/"
gen mint helmet_light \
  "#558B2F"                  "#558B2F:#7CB342:#9CCC65" "#006064:#00838F:#00BCD4" "#00695C"
gen mint helmet_dark \
  "#C5E1A5"                  "#9CCC65:#AED581:#C5E1A5" "#00BCD4:#4DD0E1:#80DEEA" "#80CBC4"

# ══════════════════════════════════════════════════════════════════════════════
# Multi-color gradient mixes
# ══════════════════════════════════════════════════════════════════════════════

# ── 36. Sunset Mix ──────────────────────────────────────────────────────────
echo "sunset_mix/"
# Flame — Red → Orange → Gold
gen sunset_mix helmet_flame_light \
  "#8B0000"                  "#8B0000:#BF5700:#B8860B" "#8B0000:#BF5700:#B8860B" "#BF5700"
gen sunset_mix helmet_flame_dark \
  "#FF8A80"                  "#FF5252:#FFB347:#FFD700" "#FF5252:#FFB347:#FFD700" "#FFB347"

# Dusk — Orange → Rose → Purple
gen sunset_mix helmet_dusk_light \
  "#880E4F"                  "#BF5700:#880E4F:#4A0072" "#BF5700:#880E4F:#4A0072" "#880E4F"
gen sunset_mix helmet_dusk_dark \
  "#FFCC80"                  "#FFB347:#EC407A:#CE93D8" "#FFB347:#EC407A:#CE93D8" "#EC407A"

# ── 37. Ocean Mix ───────────────────────────────────────────────────────────
echo "ocean_mix/"
# Deep — Teal → Blue → Indigo
gen ocean_mix helmet_deep_light \
  "#1A237E"                  "#00695C:#004080:#1A237E" "#00695C:#004080:#1A237E" "#004080"
gen ocean_mix helmet_deep_dark \
  "#9FA8DA"                  "#4DB6AC:#33BBFF:#5C6BC0" "#4DB6AC:#33BBFF:#5C6BC0" "#33BBFF"

# Reef — Cyan → Teal → Emerald
gen ocean_mix helmet_reef_light \
  "#006064"                  "#006064:#00695C:#1B5E20" "#006064:#00695C:#1B5E20" "#00695C"
gen ocean_mix helmet_reef_dark \
  "#80DEEA"                  "#4DD0E1:#4DB6AC:#66BB6A" "#4DD0E1:#4DB6AC:#66BB6A" "#4DB6AC"

# ── 38. Neon Mix ────────────────────────────────────────────────────────────
echo "neon_mix/"
# Electric — Cyan → Magenta → Yellow
gen neon_mix helmet_electric_light \
  "#006064"                  "#00BCD4:#9C27B0:#FFD700" "#00BCD4:#9C27B0:#FFD700" "#9C27B0"
gen neon_mix helmet_electric_dark \
  "#80DEEA"                  "#4DD0E1:#CE93D8:#FFE082" "#4DD0E1:#CE93D8:#FFE082" "#CE93D8"

# Plasma — Pink → Blue → Lime
gen neon_mix helmet_plasma_light \
  "#AD1457"                  "#D81B60:#0066CC:#7CB342" "#D81B60:#0066CC:#7CB342" "#0066CC"
gen neon_mix helmet_plasma_dark \
  "#F8BBD0"                  "#F06292:#33BBFF:#AED581" "#F06292:#33BBFF:#AED581" "#33BBFF"

# ── 39. Earth Mix ───────────────────────────────────────────────────────────
echo "earth_mix/"
# Terra — Brown → Amber → Lime
gen earth_mix helmet_terra_light \
  "#4E342E"                  "#4E342E:#FF6F00:#558B2F" "#4E342E:#FF6F00:#558B2F" "#FF6F00"
gen earth_mix helmet_terra_dark \
  "#BCAAA4"                  "#A1887F:#FFCA28:#AED581" "#A1887F:#FFCA28:#AED581" "#FFCA28"

# Stone — Slate → Brown → Teal
gen earth_mix helmet_stone_light \
  "#37474F"                  "#37474F:#4E342E:#00695C" "#37474F:#4E342E:#00695C" "#4E342E"
gen earth_mix helmet_stone_dark \
  "#B0BEC5"                  "#90A4AE:#A1887F:#4DB6AC" "#90A4AE:#A1887F:#4DB6AC" "#A1887F"

# ── 40. Rainbow Mix ─────────────────────────────────────────────────────────
echo "rainbow_mix/"
# Prism — Red → Green → Blue
gen rainbow_mix helmet_prism_light \
  "#8B0000"                  "#CC0000:#00B377:#0066CC" "#CC0000:#00B377:#0066CC" "#00B377"
gen rainbow_mix helmet_prism_dark \
  "#FF8A80"                  "#FF5252:#80FFD4:#33BBFF" "#FF5252:#80FFD4:#33BBFF" "#80FFD4"

# Spectrum — Orange → Violet → Cyan
gen rainbow_mix helmet_spectrum_light \
  "#BF5700"                  "#E67300:#5E35B1:#00838F" "#E67300:#5E35B1:#00838F" "#5E35B1"
gen rainbow_mix helmet_spectrum_dark \
  "#FFCC80"                  "#FFB347:#9575CD:#4DD0E1" "#FFB347:#9575CD:#4DD0E1" "#9575CD"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Done: $COUNT variants (PNG + JPG each)"
