#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# 40-ghostty —— ghostty 配色接入验收（P6 的闸门）
#   本件是**在主力机上做好并实测过**的（工作机的 ghostty 只需接上同一条链）。
#   机制：matugen 双模板 → themes/matugen-{dark,light} → active-theme →
#         switch.sh 热重载（D-Bus org.gtk.Actions reload-config）
# ════════════════════════════════════════════════════════════════════════════
set -uo pipefail
F=0
pass() { printf 'PASS %s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s %s\n' "$1" "$2"; F=$((F+1)); }
warn() { printf 'WARN %s %s\n' "$1" "$2"; }

GC="$HOME/.config/ghostty/config"
SW="$HOME/.config/theme-switcher/switch.sh"
MT="$HOME/.config/matugen/config.toml"

# ── 40.1 ghostty 本体 ──────────────────────────────────────────────────────
if command -v ghostty >/dev/null 2>&1; then
  pass 40.1 "ghostty: $(command -v ghostty)（$(ghostty +version 2>/dev/null | head -1)）"
else
  fail 40.1 "ghostty 没装（工作机应当已有；P6 未完成）"
fi

# ── 40.2 config 里的包含行 ─────────────────────────────────────────────────
if [[ -e "$GC" ]]; then
  if grep -qE '^\s*config-file\s*=\s*~?/?.*active-theme' "$GC"; then
    pass 40.2 "ghostty config 包含 active-theme"
  else
    fail 40.2 "ghostty config 里没有 config-file = ...active-theme（配色接不上）"
  fi
else
  fail 40.2 "缺 $GC"
fi

# ── 40.3 主题文件（仓库带着，缺 = FAIL）────────────────────────────────────
for f in \
  "$HOME/.config/ghostty/active-theme" \
  "$HOME/.config/ghostty/themes/matugen-dark" \
  "$HOME/.config/ghostty/themes/matugen-light" ; do
  if [[ -e "$f" ]]; then
    pass 40.3 "在: ${f/#$HOME/\~}"
  else
    fail 40.3 "缺 ${f/#$HOME/\~}（matugen 双模板的产物，仓库里带着）"
  fi
done

# ── 40.4 matugen 双模板 ────────────────────────────────────────────────────
if [[ -e "$MT" ]]; then
  grep -q '^\[templates\.ghostty_dark\]'  "$MT" && pass 40.4 "matugen 有 [templates.ghostty_dark]"  || fail 40.4 "matugen config.toml 缺 [templates.ghostty_dark]"
  grep -q '^\[templates\.ghostty_light\]' "$MT" && pass 40.4 "matugen 有 [templates.ghostty_light]" || fail 40.4 "matugen config.toml 缺 [templates.ghostty_light]"
else
  fail 40.4 "缺 $MT"
fi

# ── 40.5 switch.sh 的两个新函数（接入点）───────────────────────────────────
if [[ -e "$SW" ]]; then
  grep -q '^sync_ghostty_matugen()' "$SW" && pass 40.5 "switch.sh 有 sync_ghostty_matugen()" || fail 40.5 "switch.sh 缺 sync_ghostty_matugen()（matugen 配色同步不到 ghostty）"
  grep -q '^reload_ghostty()'       "$SW" && pass 40.5 "switch.sh 有 reload_ghostty()"       || fail 40.5 "switch.sh 缺 reload_ghostty()（热重载没了，要重开窗口才变色）"
else
  fail 40.5 "缺 $SW"
fi

# ── 40.6 重载用的 gdbus（reload_ghostty 的实现依赖）─────────────────────────
if command -v gdbus >/dev/null 2>&1; then
  pass 40.6 "gdbus 在（reload_ghostty 走 D-Bus org.gtk.Actions.Get…Activate）"
else
  fail 40.6 "没有 gdbus —— reload_ghostty 会失灵（装 glib2）"
fi

# ── 40.7 ghostty 是否在跑（只有跑着才能即时验证换色）──────────────────────
# ghostty +reload-config **不存在**；正确方式是 D-Bus：
#   gdbus call --session --dest com.mitchellh.ghostty --object-path /com/mitchellh/ghostty \
#     --method org.gtk.Actions.Activate reload-config [] {}
if busctl --user list 2>/dev/null | grep -q 'com\.mitchellh\.ghostty'; then
  pass 40.7 "ghostty 正在运行（总线名在，可用 gdbus 实测热重载）"
else
  warn 40.7 "ghostty 没在跑 —— 热重载无法现场验证（开一个再试）"
fi

exit "$F"
