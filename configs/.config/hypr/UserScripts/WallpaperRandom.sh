#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)
#
# [ii 迁移] 原先走 awww + wallust，现统一交给 theme-switcher --wallpaper，
#           它会调用 ii 的 switchwall.sh 设壁纸并做配色收尾。

wallDIR="$HOME/Pictures/wallpapers"
THEME_SWITCHER="$HOME/.config/theme-switcher/switch.sh"

mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.gif" \) -print0)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send "E-R-R-O-R" "No wallpapers found in $wallDIR"
  exit 1
fi

RANDOMPICS="${PICS[$((RANDOM % ${#PICS[@]}))]}"

exec "$THEME_SWITCHER" --wallpaper "$RANDOMPICS"
