#!/usr/bin/env bash
# ============================================================
#  按上海日出日落自动切换明暗模式
#
#  由 systemd user timer（theme-auto-mode.timer）每 5 分钟触发一次。
#  逻辑是「算出此刻应该是什么模式，和当前不一致才切」——
#  所以一天里真正调 switch.sh --set-mode 的次数只有 2 次（日出、日落）。
#
#  两条不插手的规则：
#    1. 当前不是 matugen 主题时完全不动。static 主题（gruvbox / kanagawa）
#       是你明确挑的固定配色，不该被时间逻辑改掉。
#    2. 手动优先。按过切换快捷键之后，本个「半天周期」内不再自动覆盖，
#       到下一个转折点自动逻辑重新接管。
#       （周期起点 = 最近一次转折点：今天日出 / 今天日落 / 昨天日落）
#
#  用法:
#    auto-mode.sh           正常自动判断
#    auto-mode.sh --status  只打印判断结果，不做任何改动
# ============================================================

set -uo pipefail

DIR="$HOME/.config/theme-switcher"
SWITCH="$DIR/switch.sh"
SUN="$DIR/sun-times.py"
THEME_FILE="$DIR/themes/matugen.theme"
STATE="$DIR/.last-manual"

# 日出日落按上海算，比较时刻也用上海时间，免得系统时区不是东八区时错位
CN_TZ="Asia/Shanghai"

log() { printf 'theme-auto-mode: %s\n' "$*"; }

status_only=0
[ "${1:-}" = "--status" ] && status_only=1

# ---------- 1. 当前主题类型 ----------
[ -x "$SWITCH" ] || { log "找不到 $SWITCH"; exit 1; }
cur_theme_type="$("$SWITCH" --type 2>/dev/null | tail -n1 | tr -d '[:space:]')"

if [ "$cur_theme_type" != "matugen" ]; then
    [ "$status_only" = 1 ] && log "当前主题类型是 '${cur_theme_type:-未知}'，不归自动逻辑管"
    exit 0
fi

# ---------- 2. 今天的日出日落 ----------
sun_line="$(python3 "$SUN" 2>/dev/null)" || { log "算日出日落失败"; exit 1; }
read -r sunrise sunset <<< "$sun_line"
[ -n "${sunrise:-}" ] && [ -n "${sunset:-}" ] || { log "日出日落输出异常: '$sun_line'"; exit 1; }

# ---------- 3. 现在的目标模式 ----------
now_ts=$(date +%s)
now_hm=$(TZ="$CN_TZ" date +%H:%M)

sunrise_ts=$(TZ="$CN_TZ" date -d "today $sunrise" +%s 2>/dev/null) || { log "解析日出时间失败"; exit 1; }
sunset_ts=$(TZ="$CN_TZ" date -d "today $sunset" +%s 2>/dev/null) || { log "解析日落时间失败"; exit 1; }
yesterday_sunset_ts=$(( sunset_ts - 86400 ))

if [ "$now_ts" -ge "$sunrise_ts" ] && [ "$now_ts" -lt "$sunset_ts" ]; then
    target="light"
    cycle_start="$sunrise_ts"
    phase="白天"
else
    target="dark"
    # 还没到今天日出 → 本周期从昨天日落算起；已过今天日落 → 从今天日落算起
    if [ "$now_ts" -lt "$sunrise_ts" ]; then
        cycle_start="$yesterday_sunset_ts"
    else
        cycle_start="$sunset_ts"
    fi
    phase="夜间"
fi

# ---------- 4. 手动优先 ----------
last_manual=$(cat "$STATE" 2>/dev/null || echo 0)
case "$last_manual" in ''|*[!0-9]*) last_manual=0 ;; esac

if [ "$last_manual" -ge "$cycle_start" ]; then
    [ "$status_only" = 1 ] && log "本周期内($phase)手动切换过，跳过（等下个转折点）"
    exit 0
fi

# ---------- 5. 当前 matugen 模式 ----------
cur_mode="$(sed -n 's/^THEME_MATUGEN_MODE="\{0,1\}\([a-z]*\)"\{0,1\}.*/\1/p' "$THEME_FILE" 2>/dev/null | tail -n1)"
cur_mode="${cur_mode:-dark}"

if [ "$status_only" = 1 ]; then
    log "日出 $sunrise / 日落 $sunset ｜ 现在 $now_hm($phase) ｜ 目标 $target ｜ 当前 $cur_mode"
    exit 0
fi

# ---------- 6. 需要就切 ----------
if [ "$cur_mode" = "$target" ]; then
    exit 0
fi

# ⚠ 两步缺一不可：`--set-mode` 只改 matugen.theme 里的值（外加同步 gsettings），
# **不会**重新生成配色；必须再跟一个 `-r`（重新应用当前主题）才真的跑 matugen
# 把整套颜色换掉。这是 switch.sh 里 --set-mode 和 --toggle-mode 的不对等之处：
# 后者自带应用步骤，前者只是个 setter。
if "$SWITCH" --set-mode "$target" >/dev/null 2>&1 \
   && "$SWITCH" -r >/dev/null 2>&1; then
    log "日出 $sunrise / 日落 $sunset ｜ $now_hm 进入$phase，已切到 $target"
else
    log "切到 $target 失败（switch.sh --set-mode 或 -r 返回非 0）"
    exit 1
fi
