#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# source https://wiki.archlinux.org/title/Hyprland#Using_a_script_to_change_wallpaper_every_X_minutes
#
# This script will randomly go through the files of a directory, setting it
# up as the wallpaper at regular intervals
#
# NOTE: this script uses bash (not POSIX shell) for the RANDOM variable
#
# [ii 迁移] 原先走 awww + wallust + RefreshNoWaybar，现统一交给 theme-switcher。
#           注意：如果当前是静态主题，每次换壁纸都会把配色抢回静态那套，
#           也就是说这个脚本在静态主题下只会换图、不变色。

# 主题切换器：设壁纸 + 配色收尾（内部会调 ii 的 switchwall.sh）
THEME_SWITCHER="$HOME/.config/theme-switcher/switch.sh"

if [[ $# -lt 1 ]] || [[ ! -d $1   ]]; then
	echo "Usage:
	$0 <dir containing images>"
	exit 1
fi

# This controls (in seconds) when to switch to the next image
INTERVAL=1800

while true; do
	find "$1" -type f \
		\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			"$THEME_SWITCHER" --wallpaper "$img"
			sleep "$INTERVAL"
		done
done
