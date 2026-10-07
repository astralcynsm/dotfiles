#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# 20-quickshell —— ii / quickshell 层验收（P4 的闸门）
# ════════════════════════════════════════════════════════════════════════════
set -uo pipefail
F=0
pass() { printf 'PASS %s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s %s\n' "$1" "$2"; F=$((F+1)); }
warn() { printf 'WARN %s %s\n' "$1" "$2"; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCK="$REPO/ii-patches/quickshell.lock"
SVC="$HOME/.config/systemd/user/quickshell-ii.service"

# ── 20.1 qs 二进制 ─────────────────────────────────────────────────────────
if command -v qs >/dev/null 2>&1; then
  pass 20.1 "qs: $(command -v qs)"
elif command -v quickshell >/dev/null 2>&1; then
  warn 20.1 "只有 quickshell，没有 qs 包装（ii 的脚本多按 qs 调）"
else
  fail 20.1 "quickshell 没装（P4 未完成）"
fi

# ── 20.2 revision 必须命中 ii-patches/quickshell.lock ──────────────────────
SHA="$(grep -oE '^[0-9a-f]{40}$' "$LOCK" 2>/dev/null | head -1)"
VER="$( { qs --version 2>/dev/null || quickshell --version 2>/dev/null; } | head -1)"
if [[ -z "$SHA" ]]; then
  warn 20.2 "lock 文件里没有 40 位 sha: $LOCK"
elif grep -q "$SHA" <<<"$VER"; then
  pass 20.2 "qs --version 命中锁定 revision（${SHA:0:12}…）"
else
  fail 20.2 "revision 不匹配！期望 ${SHA:0:12}…，实际: '$VER'（见 known-issues R1）"
fi

# ── 20.3 ii 树 ─────────────────────────────────────────────────────────────
if [[ -e "$HOME/.config/quickshell/ii/shell.qml" ]]; then
  N=$(find "$HOME/.config/quickshell/ii" -type f 2>/dev/null | wc -l)
  pass 20.3 "ii 树在（$N 个文件；源机 954）"
else
  fail 20.3 "缺 ~/.config/quickshell/ii/shell.qml —— 先 scripts/apply-profile.sh"
fi

# ── 20.4 ii 用户数据 ───────────────────────────────────────────────────────
if [[ -e "$HOME/.config/illogical-impulse/config.json" ]]; then
  pass 20.4 "illogical-impulse/config.json 在"
else
  fail 20.4 "缺 illogical-impulse/config.json（ii 的设置数据）"
fi

# ── 20.5 service 文件里的四个保命设置（R4/R5）──────────────────────────────
if [[ -e "$SVC" ]]; then
  ok=1
  grep -q '^Environment=QSG_RENDER_LOOP=threaded' "$SVC" || { fail 20.5a "service 缺 QSG_RENDER_LOOP=threaded（帧率会掉到 62.5）"; ok=0; }
  grep -q '^Environment=QT_IM_MODULE=fcitx' "$SVC"        || { fail 20.5b "service 缺 QT_IM_MODULE=fcitx（中文输入没了；R4：只该加在这里）"; ok=0; }
  grep -q '^KillMode=process' "$SVC"                      || { fail 20.5c "service 缺 KillMode=process（qs 崩会连带杀 QQ/Steam；R5b）"; ok=0; }
  grep -q '^Restart=always' "$SVC"                        || { fail 20.5d "service 缺 Restart=always（崩了不自动回来）"; ok=0; }
  if (( ok )); then pass 20.5 "service 四个保命设置齐全"; fi
else
  warn 20.5 "没有 $SVC（P4 还没部署 systemd 单元）"
fi

# ── 20.6 服务状态 ──────────────────────────────────────────────────────────
if systemctl --user is-active --quiet quickshell-ii 2>/dev/null; then
  pass 20.6 "quickshell-ii.service: active"
  systemctl --user is-enabled --quiet quickshell-ii 2>/dev/null \
    && pass 20.6b "已 enabled（开机自起）" \
    || warn 20.6b "没 enabled —— 开机不会自己起"
else
  fail 20.6 "quickshell-ii.service 不是 active（systemctl --user status quickshell-ii 看原因）"
fi

# ── 20.7 最近 journal 里的错误（可能有噪音，只 WARN）───────────────────────
if command -v journalctl >/dev/null 2>&1; then
  J="$(journalctl --user -u quickshell-ii -n 200 --no-pager 2>/dev/null \
        | grep -icE 'error|failed|crash' || true)"
  if [[ "${J:-0}" -eq 0 ]]; then
    pass 20.7 "近 200 行 journal 无 error/failed"
  else
    warn 20.7 "journal 近 200 行里有 $J 行 error/failed —— 人工看一眼（可能有噪音）"
  fi
fi

# ── 20.8 主题生成物（ii 配色的来源）────────────────────────────────────────
GEN="$HOME/.local/state/quickshell/user/generated/colors.json"
if [[ -e "$GEN" ]]; then
  pass 20.8 "colors.json 在（ii 配色链路产物）"
else
  warn 20.8 "还没有 colors.json —— P5 主题链跑过一次后才会出现"
fi

exit "$F"
