#!/bin/bash
# 桌面缩放（原 SUPER+ALT+滚轮 内联命令的脚本化版本）
# 用法: CursorZoom.sh up | down
#
# [0.56 迁移] hyprctl keyword cursor:zoom_factor 已移除 → hl.config eval
#   读取无需改动：getoption 首行 `float: 1.000000`，$2 即数值（实测）
#   逻辑保持原样：下限 1（读取时 clamp），up ×2 / down ÷2

DIR="$1"

CUR=$(hyprctl getoption cursor:zoom_factor | head -1 | awk '{print $2}')
[ -z "$CUR" ] && CUR=1

NEW=$(awk -v f="$CUR" -v dir="$DIR" 'BEGIN { if (f < 1) f = 1; if (dir == "up") print f * 2.0; else print f / 2.0 }')

hyprctl eval "hl.config({ cursor = { zoom_factor = $NEW } })"
