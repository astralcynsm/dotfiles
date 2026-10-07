#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# 10-hyprland —— Hyprland 层验收（P2 / P3 / P3.5 的闸门）
# 输出协议见 scripts/doctor.sh 头部。退出码 = FAIL 条数。
# ════════════════════════════════════════════════════════════════════════════
set -uo pipefail
F=0
pass() { printf 'PASS %s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s %s\n' "$1" "$2"; F=$((F+1)); }
warn() { printf 'WARN %s %s\n' "$1" "$2"; }

CFG="$HOME/.config/hypr"

# ── 10.1 hyprctl 存在 ───────────────────────────────────────────────────────
if command -v hyprctl >/dev/null 2>&1; then
  pass 10.1 "hyprctl: $(command -v hyprctl)"
else
  fail 10.1 "hyprctl 不存在 —— Hyprland 未装（P2/P3 未完成）"
  exit "$F"
fi

# ── 10.2 版本 ≥ 0.56（Lua 配置所需）────────────────────────────────────────
V="$(hyprctl version 2>/dev/null | head -1)"
NU="$(sed -nE 's/^Hyprland ([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/p' <<<"$V")"
if [[ -n "$NU" ]] && [[ "$(printf '%s\n0.56\n' "$NU" | sort -V | head -1)" == "0.56" ]]; then
  pass 10.2 "版本 $NU（≥0.56）"
else
  fail 10.2 "版本 < 0.56 或解析失败: '$V' —— Lua 配置不会工作"
fi

# ── 10.3 configProvider = lua（运行时权威信号）─────────────────────────────
if hyprctl status 2>/dev/null | grep -q 'configProvider: lua'; then
  pass 10.3 "configProvider: lua"
else
  fail 10.3 "configProvider 不是 lua —— Lua 配置没被启用"
fi

# ── 10.4 configerrors 空 ────────────────────────────────────────────────────
# 注意：hyprctl eval 写错键名的**探针残留**也会出现在这里，重启 Hyprland 才清；
# 判断时看内容是不是真配置错误（探针残留形如 "totally_bogus_key"）。
CE="$(hyprctl configerrors 2>/dev/null | sed '/^[[:space:]]*$/d')"
if [[ -z "$CE" ]]; then
  pass 10.4 "configerrors 为空"
else
  fail 10.4 "configerrors 非空："
  sed 's/^/      /' <<<"$CE"
fi

# ── 10.5 monitors ──────────────────────────────────────────────────────────
M="$(hyprctl monitors 2>/dev/null | grep -c '^Monitor ')"
if (( M > 0 )); then
  NAMES="$(hyprctl monitors 2>/dev/null | sed -nE 's/^Monitor ([^ ]+).*/\1/p' | tr '\n' ' ')"
  pass 10.5 "monitors ($M): $NAMES"
else
  fail 10.5 "没检测到 monitor —— 显示配置有问题"
fi

# ── 10.6 binds 计数（参考量，不设硬门槛）───────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  B="$(hyprctl binds -j 2>/dev/null | jq length 2>/dev/null)"
  if [[ -n "$B" && "$B" -ge 150 ]]; then
    pass 10.6 "binds: $B（工作机预期 ≈186 = 源机 203 − Laptops 17）"
  else
    warn 10.6 "binds: ${B:-?} —— 低于 150 可疑"
  fi
else
  warn 10.6 "没有 jq，跳过 binds 计数（sudo dnf install jq）"
fi

# ── 10.7 / 10.8 失效的旧式 hyprctl 调用（R7；P3.5 的闸门）──────────────────
# 注释行不数（行内容以 # 或 -- 开头）；.bak 与 *.md 不数；
# dispatch 的现代形式（参数含 hl.dsp）不算失效，会被过滤掉。
dead() { # $1 = dispatch|keyword  $2.. = 额外排除正则（可选）
  local kind="$1"; shift
  { grep -rn "hyprctl $kind" "$CFG" "$HOME/.zshrc" 2>/dev/null || true; } \
    | grep -v '\.bak' | grep -v '\.md:' \
    | grep -vE ':[0-9]+:[[:space:]]*(#|--)' \
    | { if (($#)); then grep -vE "$@"; else cat; fi; }
}

DD="$(dead dispatch "dispatch ['\"]?hl\.dsp")"
if [[ -z "$DD" ]]; then
  pass 10.7 "没有失效的 dispatch 旧写法"
else
  fail 10.7 "还有 $(wc -l <<<"$DD") 处失效 dispatch（P3.5 没做完）："
  sed 's/^/      /' <<<"$DD"
fi

DK="$(dead keyword)"
if [[ -z "$DK" ]]; then
  pass 10.8 "没有失效的 keyword 旧写法"
else
  fail 10.8 "还有 $(wc -l <<<"$DK") 处失效 keyword（P3.5 没做完）："
  sed 's/^/      /' <<<"$DK"
fi

# ── 10.9 machine.lua 链完整（hyprland.lua 末尾 require 它）──────────────────
if [[ -e "$CFG/machine.lua" ]]; then
  MISSING=()
  while IFS= read -r mod; do
    [[ -z "$mod" ]] && continue
    [[ -e "$CFG/$mod.lua" ]] || MISSING+=("$mod.lua")
  done < <(grep -oE 'require\("[^"]+"\)' "$CFG/machine.lua" 2>/dev/null \
             | sed -E 's/require\("([^"]+)"\)/\1/')
  if (( ${#MISSING[@]} == 0 )); then
    pass 10.9 "machine.lua 在，require 链完整"
  else
    fail 10.9 "machine.lua require 了但文件缺失: ${MISSING[*]} —— Hyprland 会起不来"
  fi
else
  fail 10.9 "缺 $CFG/machine.lua（hyprland.lua 末尾 require(\"machine\") 会失败）"
fi

# ── 10.10 hyprland.lua 本体 ─────────────────────────────────────────────────
if [[ -e "$CFG/hyprland.lua" ]]; then
  pass 10.10 "hyprland.lua 在"
else
  fail 10.10 "缺 $CFG/hyprland.lua —— 配置没部署（先 scripts/apply-profile.sh）"
fi

exit "$F"
