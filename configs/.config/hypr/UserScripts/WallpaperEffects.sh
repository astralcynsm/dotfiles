#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Wallpaper Effects using ImageMagick (SUPER SHIFT W)
#
# ============================================================
#  [ii 迁移] 壁纸入口统一
#
#  .wallpaper_current 始终是"原图"（由 theme-switcher 的 sync_lock_background 维护），
#  所以效果永远叠加在原图上，不会层层套娃。
#  应用效果后把「修改图」交给 ii 当壁纸——配色也会跟着修改图重新生成，
#  "No Effects" 则把原图还回去。
# ============================================================

# Variables
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_output="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
iDIR="$HOME/.config/swaync/images"

# 主题切换器：设壁纸 + 配色收尾
THEME_SWITCHER="$HOME/.config/theme-switcher/switch.sh"
II_CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"

# .wallpaper_current 还没建立时，退回 ii 记录的那张
if [ ! -f "$wallpaper_current" ] && [ -f "$II_CONFIG_FILE" ]; then
    fallback="$(jq -r '.background.wallpaperPath // empty' "$II_CONFIG_FILE" 2>/dev/null)"
    if [ -n "$fallback" ] && [ -f "$fallback" ]; then
        mkdir -p "$(dirname "$wallpaper_current")"
        cp -f "$fallback" "$wallpaper_current"
    fi
fi

if [ ! -f "$wallpaper_current" ]; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "找不到当前壁纸:\n$wallpaper_current"
    exit 1
fi

# Define ImageMagick effects
declare -A effects=(
    ["No Effects"]="no-effects"
    ["Black & White"]="magick $wallpaper_current -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
    ["Blurred"]="magick $wallpaper_current -blur 0x10 $wallpaper_output"
    ["Charcoal"]="magick $wallpaper_current -charcoal 0x5 $wallpaper_output"
    ["Edge Detect"]="magick $wallpaper_current -edge 1 $wallpaper_output"
    ["Emboss"]="magick $wallpaper_current -emboss 0x5 $wallpaper_output"
    ["Frame Raised"]="magick $wallpaper_current +raise 150 $wallpaper_output"
    ["Frame Sunk"]="magick $wallpaper_current -raise 150 $wallpaper_output"
    ["Negate"]="magick $wallpaper_current -negate $wallpaper_output"
    ["Oil Paint"]="magick $wallpaper_current -paint 4 $wallpaper_output"
    ["Posterize"]="magick $wallpaper_current -posterize 4 $wallpaper_output"
    ["Polaroid"]="magick $wallpaper_current -polaroid 0 $wallpaper_output"
    ["Sepia Tone"]="magick $wallpaper_current -sepia-tone 65% $wallpaper_output"
    ["Solarize"]="magick $wallpaper_current -solarize 80% $wallpaper_output"
    ["Sharpen"]="magick $wallpaper_current -sharpen 0x5 $wallpaper_output"
    ["Vignette"]="magick $wallpaper_current -vignette 0x3 $wallpaper_output"
    ["Vignette-black"]="magick $wallpaper_current -background black -vignette 0x3 $wallpaper_output"
    ["Zoomed"]="magick $wallpaper_current -gravity Center -extent 1:1 $wallpaper_output"
)

# Function to apply no effects —— 把原图还回去
no-effects() {
    "$THEME_SWITCHER" --wallpaper "$wallpaper_current"
    notify-send -u low -i "$iDIR/ja.png" "No wallpaper" "effects applied"
    # copying wallpaper for rofi menu
    cp "$wallpaper_current" "$wallpaper_output"
}

# Function to run rofi menu
main() {
    # Populate rofi menu options
    options=("No Effects")
    for effect in "${!effects[@]}"; do
        [[ "$effect" != "No Effects" ]] && options+=("$effect")
    done

    choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | rofi -dmenu -i -config "$HOME/.config/rofi/config-wallpaper-effect.rasi")

    # Process user choice
    if [[ -n "$choice" ]]; then
        if [[ "$choice" == "No Effects" ]]; then
            no-effects
        elif [[ "${effects[$choice]+exists}" ]]; then
            # Apply selected effect
            notify-send -u normal -i "$iDIR/ja.png"  "Applying:" "$choice effects"
            eval "${effects[$choice]}"

            if [ ! -f "$wallpaper_output" ]; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "特效生成失败: $choice"
                exit 1
            fi

            # 把修改图设为壁纸；配色会跟着修改图重新生成
            "$THEME_SWITCHER" --wallpaper "$wallpaper_output"
            notify-send -u low -i "$iDIR/ja.png" "$choice" "effects applied"
        else
            echo "Effect '$choice' not recognized."
        fi
    fi
}

# Check if rofi is already running and kill it
if pidof rofi > /dev/null; then
    pkill rofi
fi

main

sleep 1

if [[ -n "$choice" ]]; then
  sddm_simple="/usr/share/sddm/themes/simple_sddm_2"
  if [ -d "$sddm_simple" ]; then

	# Check if yad is running to avoid multiple yad notification
	if pidof yad > /dev/null; then
	  killall yad
	fi

	if yad --info --text="Set current wallpaper as SDDM background?\n\nNOTE: This only applies to SIMPLE SDDM v2 Theme" \
    --text-align=left \
    --title="SDDM Background" \
    --timeout=5 \
    --timeout-indicator=right \
    --button="yad-yes:0" \
    --button="yad-no:1" \
    ; then
	exec "$HOME/.config/hypr/scripts/sddm_wallpaper.sh" --effects
    fi
  fi
fi
