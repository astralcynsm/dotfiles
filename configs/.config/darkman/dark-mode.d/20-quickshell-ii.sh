#!/usr/bin/env sh

# Sync desktop GUI + quickshell ii theme when darkman enters dark mode.
"$HOME/.config/darkman/theme-sync.sh" dark

# 本地改：当前若是「静态主题」（固定配色，如 gruvbox / kanagawa / death-stranding），
# 就不能再调 switchwall.sh —— 它会重新生成 matugen 配色，把主题写好的 colors.json 冲掉，
# 结果 ii 界面还停在主题色、窗口/终端却跟着壁纸变了。
# 只跳过 ii 配色这一项：上面的 theme-sync.sh（GTK/foot 明暗同步）照常执行。
CURRENT="$(cat "$HOME/.config/theme-switcher/current" 2>/dev/null)"
if [ -n "$CURRENT" ] && grep -q '^THEME_TYPE="static"' \
        "$HOME/.config/theme-switcher/themes/$CURRENT.theme" 2>/dev/null; then
    echo "  · 当前主题 $CURRENT 是静态配色，跳过 ii 配色重算"
    exit 0
fi

exec "$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh" --mode dark --noswitch
