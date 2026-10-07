#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
#
# ============================================================
#  [ii 迁移] 本脚本已掏空成兼容垫片（shim）。
#
#  原来它做三件事：
#    1. 把壁纸路径写到 ~/.config/rofi/.current_wallpaper（6 个 rofi 主题拿它当背景图）
#    2. 把壁纸复制到 ~/.config/hypr/wallpaper_effects/.wallpaper_current（锁屏背景）
#    3. 跑 wallust 生成一堆配色模板
#
#  现在 1 和 2 由 theme-switcher 的 sync_wallpaper_links() 负责，
#  3 已废弃（配色全归 matugen + theme-switcher 管）。
#
#  保留这个文件是为了不让任何遗留调用报错。真正的入口是：
#      ~/.config/theme-switcher/switch.sh --wallpaper <图>
# ============================================================

set -uo pipefail

wallpaper_path="${1:-}"

# 没传路径就找当前壁纸（config.json 优先，path.txt 兜底）
if [[ -z "$wallpaper_path" || ! -f "$wallpaper_path" ]]; then
    cfg="$HOME/.config/illogical-impulse/config.json"
    if [[ -f "$cfg" ]] && command -v jq >/dev/null 2>&1; then
        wallpaper_path="$(jq -r '.background.wallpaperPath // empty' "$cfg" 2>/dev/null)"
    fi
fi
if [[ -z "$wallpaper_path" || ! -f "$wallpaper_path" ]]; then
    pf="$HOME/.local/state/quickshell/user/generated/wallpaper/path.txt"
    [[ -f "$pf" ]] && wallpaper_path="$(cat "$pf")"
fi

# 什么都不做，只同步那两个下游文件（不重设壁纸，避免调用方只是想刷新配色时误触发重绘）
if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
    ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper" 2>/dev/null || true
    mkdir -p "$HOME/.config/hypr/wallpaper_effects"
    cp -f "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current" 2>/dev/null || true
fi

exit 0
