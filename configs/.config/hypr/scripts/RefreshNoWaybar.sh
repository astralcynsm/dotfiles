#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
#
# [ii 迁移] 原为"自动换壁纸时的轻量刷新"（不碰 waybar）。
#          现在换壁纸统一走 theme-switcher，配色收尾也由它负责，
#          所以这里不再需要调 WallustSwww.sh。
#          同样删掉了 `pkill qs && qs &`（见 Refresh.sh 的注释）。
#
#          本脚本保留下来只是为了兼容可能的外部调用。

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# rofi 需要重启才会读到新配色
if pidof rofi >/dev/null; then
    pkill rofi
fi

# swaync 只在它确实在跑的时候才 reload
if pidof swaync >/dev/null; then
    swaync-client --reload-config 2>/dev/null || true
fi

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
    ${UserScripts}/RainbowBorders.sh &
fi

exit 0
