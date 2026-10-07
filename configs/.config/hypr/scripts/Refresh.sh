#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for refreshing UI components after a theme/color change
#
# ============================================================
#  [ii 迁移] 三处修改，第一处是修 bug：
#
#  1. 删掉了 `pkill qs && qs &`
#     原写法会杀掉正在运行的 illogical-impulse，再用【默认配置】重启
#     （没有 -c ii），等于把整个 ii 打回原形。ii 自己监听配置文件变化，
#     不需要也不应该由外部重启它。
#  2. 删掉 waybar / wallust 相关行（均已废弃）
#  3. swaync 改成"仅在它确实在跑时才 reload"（通知由 ii 接管）
# ============================================================

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

# rofi 需要重启才会读到新配色（它只在启动时读配置）
if pidof rofi >/dev/null; then
    pkill rofi
fi

# swaync 只在它确实在跑的时候才 reload
if pidof swaync >/dev/null; then
    swaync-client --reload-config 2>/dev/null || true
fi

# 让 Hyprland 重新读取 colors.lua（边框/阴影配色）
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1
fi

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
    ${UserScripts}/RainbowBorders.sh &
fi

exit 0
