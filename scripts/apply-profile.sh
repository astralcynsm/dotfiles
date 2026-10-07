#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# apply-profile.sh —— 在**目标机**（工作机）上运行
#
# 把仓库部署到 $HOME：先 configs/（通用层），再 machine/<profile>/（覆盖层，
# 后者同名文件覆盖前者）。
#
# 用法:
#   scripts/apply-profile.sh [profile] [--dry-run]
#     profile 默认 work；可用值 = machine/ 下的目录名（work / primary / …）
#
# 硬约束（见 CLAUDE.md、docs/known-issues.md R3、docs/rollback.md）:
#   * 绝不 rsync --delete —— 会删掉 ii 运行期生成的文件与上游带下来的文件
#   * 覆盖任何旧文件之前，先备份进 ~/.dotfiles-backup/<时间戳>/
#   * 只部署点开头的顶层条目（.config/ .local/ .zshrc …）；
#     README.md / *.toml / *.template 等是资料，永远不部署
#   * 不用 root 跑
# ════════════════════════════════════════════════════════════════════════════
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="work"
DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    -*) echo "未知参数: $arg" >&2; exit 2 ;;
    *)  PROFILE="$arg" ;;
  esac
done

if [[ $EUID -eq 0 ]]; then
  echo "别用 root 跑：这套东西部署进用户的 \$HOME。" >&2
  exit 2
fi

SRC_GEN="$REPO/configs"
SRC_M="$REPO/machine/$PROFILE"
if [[ ! -d "$SRC_GEN" ]]; then echo "缺少目录: $SRC_GEN" >&2; exit 2; fi
if [[ ! -d "$SRC_M" ]]; then
  echo "profile 不存在: machine/$PROFILE" >&2
  echo "可用: $(cd "$REPO/machine" && command ls -d */ 2>/dev/null | tr -d '/' | tr '\n' ' ')" >&2
  exit 2
fi

BK="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
LOG="$(mktemp)"; trap 'rm -f "$LOG" "$LOG.show"' EXIT

say()  { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }

RSYNC=(rsync -a --backup --backup-dir="$BK" --itemize-changes)
if (( DRY )); then RSYNC+=(--dry-run); fi

deploy_tree() {
  local src="$1" label="$2" entry base
  say "$label"
  shopt -s dotglob nullglob
  for entry in "$src"/.*; do
    base="$(basename "$entry")"
    if [[ "$base" == "." || "$base" == ".." || "$base" == ".git" ]]; then
      continue
    fi
    if ! "${RSYNC[@]}" "$entry" "$HOME/" >>"$LOG"; then
      warn "rsync 失败: $entry"
    fi
  done
}

echo "仓库:   $REPO"
echo "profile: $PROFILE$([[ $DRY == 1 ]] && echo '   [DRY-RUN: 不写盘]')"
echo "备份到: $BK"
echo "commit: $(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo '?')"

deploy_tree "$SRC_GEN" "1/2 通用层 configs/ → \$HOME"
deploy_tree "$SRC_M"   "2/2 覆盖层 machine/$PROFILE/ → \$HOME（同名文件覆盖通用层）"

# ── 变更清单 ────────────────────────────────────────────────────────────────
say "变更清单（去掉属性级噪音）"
if [[ -s "$LOG" ]]; then
  grep -vE '^\.[df]' "$LOG" | sort -u > "$LOG.show"
  head -80 "$LOG.show"
  N=$(wc -l < "$LOG.show")
  if (( N > 80 )); then echo "  …（共 $N 项）"; fi
  ok "共 $N 项变更"
else
  ok "没有任何变更（仓库与 \$HOME 已一致）"
fi

# ── 部署后自检 ──────────────────────────────────────────────────────────────
say "部署后自检"
if [[ -e "$HOME/.config/hypr/hyprland.lua" ]]; then
  ok "hyprland.lua 在"
fi
if [[ -e "$HOME/.config/hypr/machine.lua" ]]; then
  ok "machine.lua 在（机器层入口）"
  # 它 require 的文件必须都在，否则 Hyprland 起不来
  for mod in monitors workspaces; do
    if grep -q "require(\"$mod\")" "$HOME/.config/hypr/machine.lua" 2>/dev/null; then
      if [[ -e "$HOME/.config/hypr/$mod.lua" ]]; then
        ok "machine.lua 需要的 $mod.lua 在"
      else
        warn "machine.lua require(\"$mod\")，但没有 $HOME/.config/hypr/$mod.lua —— Hyprland 会起不来！"
      fi
    fi
  done
else
  warn "缺 machine.lua —— hyprland.lua 末尾 require(\"machine\") 会失败，Hyprland 起不来。"
  warn "看 machine/${PROFILE}/README.md 生成它。"
fi
if [[ -e "$HOME/.config/quickshell/ii/shell.qml" ]]; then
  ok "ii 树在（shell.qml）"
fi

# systemd 单元变动 → 给提示（不代跑）
if grep -q '\.config/systemd' "$LOG" 2>/dev/null; then
  warn "systemd 单元有变动，记得: systemctl --user daemon-reload"
fi

# ── 收尾 ─────────────────────────────────────────────────────────────────────
if (( DRY )); then
  say "DRY-RUN 结束：什么都没写。去掉 --dry-run 真跑。"
else
  if [[ -d "$BK" ]]; then
    say "完成。被覆盖的旧文件备份在: $BK"
  else
    say "完成。本次没有覆盖任何旧文件（无备份产生）。"
  fi
  echo "下一步建议: scripts/doctor.sh"
fi
