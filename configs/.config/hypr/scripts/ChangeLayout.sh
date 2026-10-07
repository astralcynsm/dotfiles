#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master or Dwindle) on the fly
#
# [0.56 迁移] hyprctl keyword/unbind/bind 字符串形式已移除 → hyprctl eval（Lua）
#   - general:layout              → hl.config({ general = { layout = ... } })
#   - unbind SUPER,X              → hl.unbind("SUPER + X")
#   - bind SUPER,X,cyclenext      → hl.bind(..., hl.dsp.window.cycle_next())
#   - bind SUPER,X,layoutmsg,msg  → hl.bind(..., hl.dsp.layout("msg"))
#   runtime bind/unbind 在 hyprctl reload 后失效（与旧 keyword 行为一致）
#   状态读取无需改动：getoption -j 的 .str 仍存在（实测）

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str')

case $LAYOUT in
"master")
	hyprctl eval 'hl.config({ general = { layout = "dwindle" } })'
	hyprctl eval 'hl.unbind("SUPER + J"); hl.unbind("SUPER + K")'
	hyprctl eval 'hl.bind("SUPER + J", hl.dsp.window.cycle_next()); hl.bind("SUPER + K", hl.dsp.window.cycle_next({ prev = true })); hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'
	notify-send -e -u low -i "$notif" " Dwindle Layout"
	;;
"dwindle")
	hyprctl eval 'hl.config({ general = { layout = "master" } })'
	hyprctl eval 'hl.unbind("SUPER + J"); hl.unbind("SUPER + K"); hl.unbind("SUPER + O")'
	hyprctl eval 'hl.bind("SUPER + J", hl.dsp.layout("cyclenext")); hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))'
	notify-send -e -u low -i "$notif" " Master Layout"
	;;
*) ;;

esac
