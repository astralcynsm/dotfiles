#!/usr/bin/env bash
# ============================================================
#  主题切换器 —— rofi 菜单入口
#
#  用法: menu.sh
#  建议绑个键位，例如:
#    hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("$HOME/.config/theme-switcher/menu.sh"))
# ============================================================

set -uo pipefail

SWITCHER_DIR="$HOME/.config/theme-switcher"
SWITCH="$SWITCHER_DIR/switch.sh"
THEMES_DIR="$SWITCHER_DIR/themes"
STATE_FILE="$SWITCHER_DIR/current"

command -v rofi >/dev/null || { notify-send -a "主题切换" "rofi 未安装" 2>/dev/null; exit 1; }

cur="$(cat "$STATE_FILE" 2>/dev/null || echo '')"

# 菜单行格式: "<标记> <主题名>  —  <描述>"
# 主题名不含空格，所以选完取第 2 个字段即可还原
menu_lines=""
while read -r t; do
    [ -z "$t" ] && continue
    desc="$(
        unset THEME_DESC THEME_TYPE THEME_ASSETS THEME_MATUGEN_MODE
        # shellcheck disable=SC1090
        source "$THEMES_DIR/$t.theme" 2>/dev/null
        printf '%s' "${THEME_DESC:-$t}"
    )"
    if [ "$t" = "$cur" ]; then mark="  ●"; else mark="  ○"; fi
    menu_lines+="${mark}  ${t}   —   ${desc}"$'\n'
done < <(find "$THEMES_DIR" -maxdepth 1 -name '*.theme' -printf '%f\n' | sed 's/\.theme$//' | sort)

if [ -z "$menu_lines" ]; then
    notify-send -a "主题切换" "没有找到任何主题" 2>/dev/null
    exit 1
fi

selection="$(
    printf '%s' "$menu_lines" \
    | rofi -dmenu -i -no-custom -p "主题" \
           -theme-str 'window {width: 30%;} listview {lines: 8;}'
)" || exit 0

[ -z "$selection" ] && exit 0

theme="$(printf '%s' "$selection" | awk '{print $2}')"
[ -z "$theme" ] && exit 0
[ -f "$THEMES_DIR/$theme.theme" ] || exit 0

exec "$SWITCH" "$theme"
