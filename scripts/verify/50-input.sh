#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# 50-input —— 输入法验收（P7 的闸门）
#   R4 是本节最要紧的一条：QT_IM_MODULE / GTK_IM_MODULE **不许**进 /etc/environment，
#   全局打开会让不支持的 Qt 应用崩；只给 quickshell-ii.service 单独加。
#   见 docs/known-issues.md R4、docs/machine-diff.md
# ════════════════════════════════════════════════════════════════════════════
set -uo pipefail
F=0
pass() { printf 'PASS %s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s %s\n' "$1" "$2"; F=$((F+1)); }
warn() { printf 'WARN %s %s\n' "$1" "$2"; }

# ── 50.1 fcitx5 进程 ───────────────────────────────────────────────────────
if pgrep -x fcitx5 >/dev/null 2>&1; then
  pass 50.1 "fcitx5 在跑 (pid $(pgrep -x fcitx5 | tr '\n' ' '))"
elif command -v fcitx5 >/dev/null 2>&1; then
  fail 50.1 "fcitx5 装了但没在跑 —— fcitx5 -r -d 或检查自启"
else
  fail 50.1 "fcitx5 没装（P7 未完成；Fedora 官方仓有）"
fi

# ── 50.2 默认输入法 = rime ─────────────────────────────────────────────────
PROF="$HOME/.config/fcitx5/profile"
if [[ -e "$PROF" ]]; then
  if grep -q '^DefaultIM=rime' "$PROF"; then
    pass 50.2 "fcitx5 profile: DefaultIM=rime"
  else
    warn 50.2 "profile 里 DefaultIM 不是 rime：$(grep -m1 '^DefaultIM=' "$PROF" || echo '(没这行)')"
  fi
else
  fail 50.2 "缺 $PROF"
fi

# ── 50.3 rime 用户词典（多年词频，不可再生！）──────────────────────────────
RIME="$HOME/.local/share/fcitx5/rime"
if [[ -d "$RIME" ]]; then
  for db in rime_ice.userdb luna_pinyin.userdb; do
    if [[ -d "$RIME/$db" ]]; then
      pass 50.3 "$db 在"
    else
      fail 50.3 "缺 $db —— 词频历史丢了（rollback.md：userdb 永不删、单独备份）"
    fi
  done
  # 大件该被排除（靠 plum 重装），在 = 说明带了不该带的
  for big in build sync cn_dicts; do
    if [[ -e "$RIME/$big" ]]; then
      echo "     （注：$RIME/$big 在，属大件；仓库里按 .gitignore 排除了）"
    fi
  done
else
  fail 50.3 "缺 $RIME（P7 未完成）"
fi

# ── 50.4 ★R4：/etc/environment 不许有活跃的 QT/GTK_IM_MODULE ───────────────
if [[ -r /etc/environment ]]; then
  HIT="$(grep -nE '^\s*(QT|GTK)_IM_MODULE' /etc/environment || true)"
  if [[ -z "$HIT" ]]; then
    pass 50.4 "R4 守住：/etc/environment 没有活跃的 QT/GTK_IM_MODULE"
    # 被注释掉的那两行应当在（那是刻意的记号），提一句方便肉眼核对
    grep -qE '^\s*#\s*(QT|GTK)_IM_MODULE' /etc/environment \
      && pass 50.4b "注释掉的 QT/GTK_IM_MODULE 记号在（刻意如此，别动）" \
      || warn 50.4b "连注释掉的记号都没有 —— 确认下是不是整段被改过"
  else
    fail 50.4 "R4 破了！/etc/environment 有活跃的 QT/GTK_IM_MODULE（全局开会让不支持的 Qt 应用崩）："
    sed 's/^/     /' <<<"$HIT"
  fi
  # 该活跃的三行
  for v in XMODIFIERS SDL_IM_MODULE FC_LANG; do
    if grep -qE "^\s*$v=" /etc/environment; then
      pass 50.4 "活跃环境变量 $v 在"
    else
      warn 50.4 "缺 $v（P7 的一部分）：$(grep -m1 "^.*$v" /etc/environment || echo '(连注释都没有)')"
    fi
  done
else
  warn 50.4 "读不到 /etc/environment"
fi

# ── 50.5 environment.d（P7.4 要在工作机建的）───────────────────────────────
if [[ -d "$HOME/.config/environment.d" ]]; then
  N=$(find "$HOME/.config/environment.d" -maxdepth 1 -type f 2>/dev/null | wc -l)
  if (( N > 0 )); then
    pass 50.5 "~/.config/environment.d 有 $N 个文件"
  else
    warn 50.5 "~/.config/environment.d 是空的（P7.4）"
  fi
else
  warn 50.5 "没有 ~/.config/environment.d —— P7.4 要建（源机也没有，属工作机补齐项）"
fi

# ── 50.6 R4 的正确落点：只有 quickshell-ii.service 单独带 ──────────────────
SVC="$HOME/.config/systemd/user/quickshell-ii.service"
if [[ -e "$SVC" ]]; then
  if grep -q '^Environment=QT_IM_MODULE=fcitx' "$SVC"; then
    pass 50.6 "quickshell-ii.service 单独带 QT_IM_MODULE=fcitx（R4 的正确姿势）"
  else
    fail 50.6 "quickshell-ii.service 没有 QT_IM_MODULE=fcitx —— 面板里打不了中文"
  fi
else
  warn 50.6 "缺 $SVC（看 P4）"
fi

# ── 50.7 候选框主题（matugen 双套）─────────────────────────────────────────
for t in matugen-dark matugen-light; do
  if [[ -d "$HOME/.local/share/fcitx5/themes/$t" ]]; then
    pass 50.7 "fcitx5 主题 $t 在"
  else
    warn 50.7 "缺 fcitx5 主题 $t —— 候选框不跟明暗走（跑一次主题即生成）"
  fi
done

exit "$F"
