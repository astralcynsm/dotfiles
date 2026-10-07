#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly
#
# [0.56 迁移] hyprctl keyword 字符串形式已移除 → hyprctl eval + hl.config
#   状态读取无需改动：`getoption -j` 的 JSON 里 blur:passes 仍是 .int（实测）

notif="$HOME/.config/swaync/images"

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "2" ]; then
	hyprctl eval 'hl.config({ decoration = { blur = { size = 2, passes = 1 } } })'
	notify-send -e -u low -i "$notif/note.png" " Less Blur"
else
	hyprctl eval 'hl.config({ decoration = { blur = { size = 5, passes = 2 } } })'
	notify-send -e -u low -i "$notif/ja.png" " Normal Blur"
fi
