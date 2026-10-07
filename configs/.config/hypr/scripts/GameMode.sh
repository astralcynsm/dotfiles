#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations
#
# [ii 迁移] 原先靠 `awww kill` 把壁纸抹掉、退出时再拉起 awww 并重跑 wallust。
#          壁纸现在是 ii 的 QML 图层（不是独立守护进程），没有"杀掉再拉起"这回事；
#          配色也改由 theme-switcher 管理，不需要在游戏模式里重新生成。
#          退出时统一用 `hyprctl reload` 把 Lua 配置里的设置全部还原。

notif="$HOME/.config/swaync/images/ja.png"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"

	hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    exit
else
    # 从 Lua 配置重新加载所有设置（动画/阴影/间隙/边框/圆角一并还原）
    hyprctl reload
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
