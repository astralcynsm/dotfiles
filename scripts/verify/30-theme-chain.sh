#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# 30-theme-chain —— 主题链验收（P5 的闸门）
#   链路：theme-switcher/switch.sh（总控）→ matugen（生成配色）→ darkman（明暗仲裁）
#   见 docs/ARCHITECTURE.md、docs/known-issues.md R8
# ════════════════════════════════════════════════════════════════════════════
set -uo pipefail
F=0
pass() { printf 'PASS %s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s %s\n' "$1" "$2"; F=$((F+1)); }
warn() { printf 'WARN %s %s\n' "$1" "$2"; }

SW="$HOME/.config/theme-switcher/switch.sh"

# ── 30.1 matugen ───────────────────────────────────────────────────────────
if command -v matugen >/dev/null 2>&1; then
  MV="$(matugen --version 2>/dev/null | head -1)"
  if grep -qE '3\.[0-9]' <<<"$MV"; then
    pass 30.1 "matugen: $MV"
  else
    warn 30.1 "matugen 版本非 3.x: '$MV' —— 模板语法可能有出入（源机 3.1.0）"
  fi
else
  fail 30.1 "matugen 没装（P5 未完成；Fedora 见 docs/package-map.md）"
fi

# ── 30.2 switch.sh ─────────────────────────────────────────────────────────
if [[ -x "$SW" ]]; then
  pass 30.2 "switch.sh 在且可执行"
elif [[ -e "$SW" ]]; then
  fail 30.2 "switch.sh 在但**不可执行** —— chmod +x $SW"
else
  fail 30.2 "缺 $SW（P5 未完成）"
fi

# ── 30.3 switch.sh -l 非交互列主题（脚本可用的硬信号）───────────────────────
if [[ -x "$SW" ]]; then
  OUT="$(cd "$HOME" && timeout 15 "$SW" -l 2>/dev/null)"; RC=$?
  N=$(wc -l <<<"$OUT")
  if (( RC == 0 )) && (( N >= 5 )); then
    pass 30.3 "switch.sh -l: exit 0，$N 个主题"
  elif (( RC == 124 )); then
    fail 30.3 "switch.sh -l **超时**（15s）—— 大概率卡在交互提示上"
  else
    fail 30.3 "switch.sh -l 行为异常：exit=$RC，$N 行输出"
  fi
  echo "     当前主题标记: $(cat "$HOME/.config/theme-switcher/current" 2>/dev/null || echo '(无)')"
fi

# ── 30.4 关键产物 ──────────────────────────────────────────────────────────
# 仓库里就带着的（部署完就该在）→ 缺 = FAIL
must_have=(
  "$HOME/.config/hypr/colors.lua"
  "$HOME/.config/hypr/hyprlock/colors.conf"
)
for f in "${must_have[@]}"; do
  if [[ -e "$f" ]]; then
    pass 30.4 "产物在: ${f/#$HOME/\~}"
  else
    fail 30.4 "缺 ${f/#$HOME/\~}（Hyprland/hyprlock 的配色来源，仓库里带着它的）"
  fi
done
# 换主题时才重新生成 → 缺 = WARN
gen_maybe=(
  "$HOME/.local/state/quickshell/user/generated/colors.json"
  "$HOME/.config/gtk-3.0/gtk.css"
  "$HOME/.config/gtk-4.0/gtk.css"
)
for f in "${gen_maybe[@]}"; do
  [[ -e "$f" ]] || warn 30.4 "还没有 ${f/#$HOME/\~} —— 跑一次 switch.sh 才生成"
done

# ── 30.5 darkman（明暗的真正仲裁者；R8）────────────────────────────────────
if ! command -v darkman >/dev/null 2>&1; then
  warn 30.5 "darkman 没装（P5 未完成；Fedora 无包，要 Go 源码编译）"
elif systemctl --user is-active --quiet darkman 2>/dev/null; then
  pass 30.5 "darkman.service: active"
else
  fail 30.5 "darkman 装了但服务不是 active —— 明暗不会自动切"
fi

# ── 30.6 darkman 钩子（真实生效的那两个目录）───────────────────────────────
for m in dark light; do
  D="$HOME/.local/share/${m}-mode.d"
  if [[ -d "$D" ]]; then
    H="$(find "$D" -maxdepth 1 -type f -perm -u+x 2>/dev/null | wc -l)"
    if (( H > 0 )); then
      pass 30.6 "${m}-mode.d: $H 个可执行钩子"
    else
      warn 30.6 "${m}-mode.d 存在但**没有可执行钩子** —— 明暗切换不会动任何东西"
    fi
  else
    warn 30.6 "缺 $D（P5 未完成）"
  fi
done

# ── 30.7 R8 陷阱：放错目录的钩子（darkman **不读**它）──────────────────────
TRAP="$(find "$HOME/.config/darkman" -path '*-mode.d/*' -name '*.sh' -perm -u+x 2>/dev/null || true)"
if [[ -n "$TRAP" ]]; then
  warn 30.7 "R8 陷阱：~/.config/darkman/*-mode.d/ 下有可执行钩子，但 darkman **不读**这个目录（只读 ~/.local/share/{dark,light}-mode.d/）："
  sed 's/^/     /' <<<"$TRAP"
  warn 30.7 "要么删，要么 chmod -x —— 留在那只会让人以为它在生效。见 known-issues R8"
else
  pass 30.7 "没有放错目录的 darkman 钩子"
fi

# ── 30.8 自动明暗 timer ────────────────────────────────────────────────────
if systemctl --user is-enabled --quiet theme-auto-mode.timer 2>/dev/null; then
  pass 30.8 "theme-auto-mode.timer: enabled"
else
  warn 30.8 "theme-auto-mode.timer 没 enabled（日落日出自动切换不会跑）"
fi

exit "$F"
