#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# doctor.sh —— 体检总入口：依次跑 scripts/verify/*.sh 并汇总
#
# 输出协议：每个 verify 脚本打印若干行
#     PASS <id> <描述>     检查通过
#     FAIL <id> <描述>     检查失败（阶段没做完 / 坏了）
#     WARN <id> <描述>     可疑但未必错（例如"组件还没装"）
# 本脚本把三种行着色汇总；只要出现 FAIL 就 exit 1。
#
# 用法: scripts/doctor.sh
# ════════════════════════════════════════════════════════════════════════════
set -uo pipefail   # 故意不用 -e：某个脚本炸了要继续跑下一个

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFY="$REPO/scripts/verify"

shopt -s nullglob
scripts=("$VERIFY"/*.sh)
if (( ${#scripts[@]} == 0 )); then
  echo "scripts/verify/ 里没有检查脚本" >&2
  exit 2
fi

echo "════════════════════════════════════════════════════════════"
echo " doctor —— $(date '+%F %T')   host=$(hostname)   repo@$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo '?')"
echo "════════════════════════════════════════════════════════════"

declare -i TP=0 TF=0 TW=0
FAILED_SCRIPTS=()

for s in "${scripts[@]}"; do
  name="$(basename "$s")"
  printf '\n\033[1;36m▸ %s\033[0m\n' "$name"

  out="$(bash "$s" 2>&1)" || true
  while IFS= read -r line; do
    case "$line" in
      PASS*) printf '\033[1;32m  %s\033[0m\n' "$line"; TP+=1 ;;
      FAIL*) printf '\033[1;31m  %s\033[0m\n' "$line"; TF+=1 ;;
      WARN*) printf '\033[1;33m  %s\033[0m\n' "$line"; TW+=1 ;;
      *)     printf '      %s\n' "$line" ;;
    esac
  done <<< "$out"
done

echo
echo "════════════════════════════════════════════════════════════"
printf " 合计:  \033[1;32mPASS %d\033[0m  \033[1;31mFAIL %d\033[0m  \033[1;33mWARN %d\033[0m\n" "$TP" "$TF" "$TW"
if (( TF > 0 )); then
  echo " 有 FAIL —— 阶段没过。对照 MIGRATION.md 当前阶段与 docs/known-issues.md。"
  exit 1
fi
echo " 全绿（WARN 自己读一遍，有的只是「还没装」）。"
exit 0
