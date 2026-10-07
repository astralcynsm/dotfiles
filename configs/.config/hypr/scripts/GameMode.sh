#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations
#
# [ii 迁移] 原先靠 `awww kill` 把壁纸抹掉、退出时再拉起 awww 并重跑 wallust。
#          壁纸现在是 ii 的 QML 图层（不是独立守护进程），没有"杀掉再拉起"这回事；
#          配色也改由 theme-switcher 管理，不需要在游戏模式里重新生成。
#          退出时统一用 `hyprctl reload` 把 Lua 配置里的设置全部还原。

notif="$HOME/.config/swaync/images/ja.png"

# [0.56 迁移] getoption 首行格式变为 `bool: true|false`（旧版 `int: 1`），取 $2 比较
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | head -1 | awk '{print $2}')
if [ "$HYPRGAMEMODE" = "true" ] ; then
    # [0.56 迁移] keyword / --batch 字符串形式已移除 → Lua eval
    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 } })'

    hyprctl eval 'hl.window_rule({ match = { class = ".*" }, opacity = "1 override 1 override 1 override" })'
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    exit
else
    # 从 Lua 配置重新加载所有设置（动画/阴影/间隙/边框/圆角一并还原）
    hyprctl reload
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
