#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
# export-from-arch.sh —— 在**主力机**（Arch / EndeavourOS）上运行
#
# 把当前桌面的活配置导出进本仓库：
#   configs/          ← 与机器无关的通用配置（镜像 $HOME 的目录结构）
#   machine/primary/  ← 主力机特有部分（显示器分配、笔记本键位）
#
# 这个脚本只在主力机上跑。工作机是反方向（scripts/apply-profile.sh）。
#
# 用法:
#   scripts/export-from-arch.sh             # 导出
#   scripts/export-from-arch.sh --dry-run   # 只看会动什么，不写盘
#
# ── 设计说明 ───────────────────────────────────────────────────────────────
# 1. 导出方向**用 --delete**：仓库要忠实反映活配置，不留陈旧文件。
#    git 是安全网 —— 导错了 `git checkout .` 就回来了。
# 2. 部署方向（apply-profile.sh）**绝不用 --delete**：会删掉 ii 运行期生成的
#    文件和上游带下来的文件。这条是硬约束，见 docs/known-issues.md。
# 3. 二进制（ELF）一律不进仓库 —— rime_counter_rs 只带源码，工作机 cargo build。
# 4. rime 的 187M 里只带**不可再生**的部分：userdb（多年词频）+ 用户配置。
#    上游方案数据（cn_dicts 等）约 90M，靠 plum 重装，见 MIGRATION.md Phase 7。
# ════════════════════════════════════════════════════════════════════════════
set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY=0
if [[ "${1:-}" == "--dry-run" ]]; then DRY=1; fi

RSYNC=(rsync -a --delete --quiet)
if (( DRY )); then RSYNC+=(--dry-run); fi

# 通用排除：备份、编辑器残留、运行期状态
EXCL=(
  --exclude='*.bak' --exclude='*.bak-*' --exclude='*.bak.*'
  --exclude='*.old' --exclude='*~' --exclude='*.orig' --exclude='*.rej'
  --exclude='.claude/'        # Claude Code 本地设置（含权限清单，机器特定 + 安全隐患面）
  --exclude='__pycache__/'
  --exclude='.DS_Store'
)

say()  { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }

# ★ 关键：dry-run 时**什么都不做**。所有写操作都要经过 run / put。
run() {
  if (( DRY )); then printf '\033[1;35m    would: %s\033[0m\n' "$*"; return 0; fi
  "$@"
}

# 复制一个目录并报告体积
sync_dir() {
  local src="$1" dst="$2"; shift 2
  if [[ ! -d "$src" ]]; then warn "不存在，跳过: $src"; return 0; fi
  run mkdir -p "$dst"
  "${RSYNC[@]}" "${EXCL[@]}" "$@" "$src/" "$dst/"
  local size="(dry-run)"
  if (( ! DRY )); then size="$(du -sh "$dst" 2>/dev/null | cut -f1)"; fi
  ok "$(basename "$src")/  $size"
}

# 复制单个文件
put() {
  local src="$1" dst_dir="$2"
  if [[ ! -e "$src" ]]; then warn "不存在，跳过: $src"; return 0; fi
  run mkdir -p "$dst_dir"
  run cp -a "$src" "$dst_dir/"
  ok "$(basename "$src")"
}

# 只复制文本文件（ELF / 二进制跳过）
put_text() {
  local src="$1" dst_dir="$2"
  if [[ ! -e "$src" ]]; then warn "不存在，跳过: $src"; return 0; fi
  if file -b "$src" | grep -qiE 'ELF|Mach-O|binary'; then
    warn "二进制，跳过（工作机重编）: $(basename "$src")"
    return 0
  fi
  put "$src" "$dst_dir"
}

echo "════════════════════════════════════════════════════════════════"
echo " 导出到: $REPO"
if (( DRY )); then echo " 模式: DRY-RUN（不写盘）"; fi
echo "════════════════════════════════════════════════════════════════"

# ── 1 ───────────────────────────────────────────────────────────────────
say "1/14  Hyprland 通用配置 → configs/.config/hypr/"
# 机器特定项（machine / monitors / workspaces / Laptops / LaptopDisplay / Monitor_Profiles）
# 在这里排除，下一步单独进 machine/primary/
# ⚠ machine.lua 是**机器层的入口**（hyprland.lua 末尾 require("machine")），
#   它明确写着自己属于 machine/<profile>/；漏掉排除会让笔记本的 require 链
#   装进通用层 → 工作机部署后加载 Laptops.lua。2026-10-08 修正。
sync_dir "$HOME/.config/hypr" "$REPO/configs/.config/hypr" \
  --exclude='wallpaper_effects/' \
  --exclude='wallust/' \
  --exclude='.initial_startup_done' \
  --exclude='v2.3.*' \
  --exclude='indowrule' \
  --exclude='Monitor_Profiles/' \
  --exclude='machine.lua' \
  --exclude='monitors.lua' \
  --exclude='workspaces.lua' \
  --exclude='UserConfigs/Laptops.lua' \
  --exclude='UserConfigs/LaptopDisplay.lua'

# ── 2 ───────────────────────────────────────────────────────────────────
say "2/14  主力机特有部分 → machine/primary/.config/hypr/"
D="$REPO/machine/primary/.config/hypr"
run mkdir -p "$D/UserConfigs"
for f in machine.lua monitors.lua workspaces.lua; do
  put "$HOME/.config/hypr/$f" "$D"
done
for f in Laptops.lua LaptopDisplay.lua; do
  put "$HOME/.config/hypr/UserConfigs/$f" "$D/UserConfigs"
done
if [[ -d "$HOME/.config/hypr/Monitor_Profiles" ]]; then
  run cp -a "$HOME/.config/hypr/Monitor_Profiles" "$D/"
  ok "Monitor_Profiles/"
fi

# ── 3 ───────────────────────────────────────────────────────────────────
say "3/14  ii / quickshell → configs/.config/quickshell/ii/"
# 整树快照（6.1M / 954 文件）。不做 git patch —— 理由见 docs/upstream-sync.md
sync_dir "$HOME/.config/quickshell/ii" "$REPO/configs/.config/quickshell/ii"

# ── 4 ───────────────────────────────────────────────────────────────────
say "4/14  ii 用户数据 → configs/.config/illogical-impulse/"
sync_dir "$HOME/.config/illogical-impulse" "$REPO/configs/.config/illogical-impulse" \
  --exclude='installed_listfile' \
  --exclude='*.pre-stage3' \
  --exclude='*.stage3-hold'

# ── 5 ───────────────────────────────────────────────────────────────────
say "5/14  主题切换器 → configs/.config/theme-switcher/"
sync_dir "$HOME/.config/theme-switcher" "$REPO/configs/.config/theme-switcher" \
  --exclude='current' \
  --exclude='.last-manual'

# ── 6 ───────────────────────────────────────────────────────────────────
say "6/14  matugen → configs/.config/matugen/"
sync_dir "$HOME/.config/matugen" "$REPO/configs/.config/matugen"

# ── 7 ───────────────────────────────────────────────────────────────────
say "7/14  ghostty → configs/.config/ghostty/"
# ⚠️ 工作机上若已有自己的 ghostty 配置，**不要整体覆盖**：
#    只需要 themes/ 与 config 里 `config-file = ...active-theme` 那一行机制。
#    见 docs/machine-diff.md 与 MIGRATION.md Phase 6。
sync_dir "$HOME/.config/ghostty" "$REPO/configs/.config/ghostty"

# ── 8 ───────────────────────────────────────────────────────────────────
say "8/14  fcitx5 → configs/.config/fcitx5/"
sync_dir "$HOME/.config/fcitx5" "$REPO/configs/.config/fcitx5" --exclude='*.log'

# ── 9 ───────────────────────────────────────────────────────────────────
say "9/14  darkman → configs/（配置 + 活钩子目录，两处都收）"
# ⚠ darkman 只扫 $XDG_DATA_HOME 下的钩子目录；本机实测跑的是
#   ~/.local/share/{dark,light}-mode.d/（journal 原文 `Found legacy script path=…`），
#   而 ~/.config/darkman/{dark,light}-mode.d/ 里的钩子**从来没有执行过**。
#   2026-10-08 查实，机制与验证方法见 docs/known-issues.md R8。
#   两处都导出：config 侧留档（含静态主题护栏逻辑），.local/share 侧才是真正生效的那套。
sync_dir "$HOME/.config/darkman" "$REPO/configs/.config/darkman" \
  --exclude='README.md'          # 仓库侧警示牌，别让 --delete 抹掉
for m in dark light; do
  sync_dir "$HOME/.local/share/$m-mode.d" "$REPO/configs/.local/share/$m-mode.d" \
    --exclude='README.md'
done

# ── 10 ──────────────────────────────────────────────────────────────────
say "10/14 systemd 用户单元（只取白名单）"
SD="$REPO/configs/.config/systemd/user"
run mkdir -p "$SD"
UNITS=(
  quickshell-ii.service
  ii-stats.service
  rime_counter.service
  hyprland-session.target
  theme-auto-mode.service
  theme-auto-mode.timer
  db-sync.service
  rescrobbled.service
  xdg-desktop-portal.service
)
for u in "${UNITS[@]}"; do
  put "$HOME/.config/systemd/user/$u" "$SD"
done
# 不复制 *.wants/ 符号链接 —— 启用状态由 systemctl --user enable 重建。
# 这里只快照「哪些是启用的」，供工作机参照。
if (( ! DRY )); then
  {
    echo "# 主力机上处于 enabled 状态的 systemd user 单元（快照，供工作机参照）"
    echo "# 由 scripts/export-from-arch.sh 生成于 $(date -Iseconds)"
    echo
    systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null | awk '{print $1}'
  } > "$SD/ENABLED.txt"
fi
ok "ENABLED.txt"

# ── 11 ──────────────────────────────────────────────────────────────────
say "11/14 shell 与 CLI 配置"
# ⚠️ 这一层是「常用 CLI 使用习惯」。工作机上装之前先看 inventory/cli-candidates.md，
#    并备份已有的同名文件（apply-profile.sh 会先备份）。
for f in .zshrc .p10k.zsh .gitconfig; do
  put "$HOME/$f" "$REPO/configs"
done
sync_dir "$HOME/.config/zshrc.d"       "$REPO/configs/.config/zshrc.d"
put "$HOME/.config/starship.toml"      "$REPO/configs/.config"
sync_dir "$HOME/.config/atuin"         "$REPO/configs/.config/atuin"
sync_dir "$HOME/.config/git"           "$REPO/configs/.config/git"
# ⚠️ vault-commit/vaults.json 里是 /mnt/Storage/... 这类**挂载路径**，机器特定
#    → 进 machine/primary/，不污染通用层。工作机的库路径另填。
sync_dir "$HOME/.config/vault-commit"  "$REPO/machine/primary/.config/vault-commit"

# ── 12 ──────────────────────────────────────────────────────────────────
say "12/14 自写脚本 → configs/.local/bin/（仅文本）"
BIN="$REPO/configs/.local/bin"
run mkdir -p "$BIN"
for f in ii-stats-daemon vault-commit term-exec steam db-sync mkprompt plymouth-ii-theme osu-wine; do
  put_text "$HOME/.local/bin/$f" "$BIN"
done

# rime_counter_rs 是 1.1M 的 Rust 二进制 —— 带源码不带二进制
SRC_RS=""
for cand in \
  /mnt/Storage/files/ricing/rime_counter_rs \
  /mnt/Storage/files/coding/Rust/rime_counter_rs \
  "$HOME/.local/src/rime_counter_rs" \
; do
  if [[ -d "$cand" && -f "$cand/Cargo.toml" ]]; then SRC_RS="$cand"; break; fi
done
if [[ -n "$SRC_RS" ]]; then
  sync_dir "$SRC_RS" "$REPO/configs/.local/src/rime_counter_rs" \
    --exclude='target/' --exclude='.git/'
  warn "工作机需要: dnf install rust cargo && cargo build --release"
else
  warn "没找到 rime_counter_rs 源码（二进制 1.1M 不进仓库）—— 需手工定位"
fi

# ── 13 ──────────────────────────────────────────────────────────────────
say "13/14 Rime 用户数据 → configs/.local/share/fcitx5/rime/"
# 用户实际用的是 rime_ice（见 default.custom.yaml 的 schema_list），不是 luna_pinyin。
# 只带不可再生的：userdb + 用户配置 + 小巧的 plum 状态。
# **不带** cn_dicts(45M) / build(69M) / sync(19M) / py_wordscounter(38M) /
# SouGouDicts(3.9M) / radical_pinyin(900K) —— 这些是上游数据或生成物，
# 工作机上用 plum 重装 rime-ice 即可，见 MIGRATION.md Phase 7。
RT="$REPO/configs/.local/share/fcitx5/rime"
run mkdir -p "$RT"
for d in rime_ice.userdb luna_pinyin.userdb opencc lua plum; do
  if [[ -d "$HOME/.local/share/fcitx5/rime/$d" ]]; then
    sync_dir "$HOME/.local/share/fcitx5/rime/$d" "$RT/$d" \
      --exclude='.git/'        # plum 是 git clone 来的，嵌套 .git 不进仓库
  fi
done
# 早期导出误带进来的 plum/.git —— --exclude 只防新复制，防不了已存在的残留
if [[ -d "$RT/plum/.git" ]]; then
  run rm -rf "$RT/plum/.git"
  ok "清掉残留的 plum/.git"
fi
for f in custom_phrase.txt default.custom.yaml installation.yaml user.yaml t9.schema.yaml; do
  put "$HOME/.local/share/fcitx5/rime/$f" "$RT"
done

# ── 14 ──────────────────────────────────────────────────────────────────
say "14/14 密钥擦除 + 安全闸门"
# ★ 真 token 不进仓库（本机既有约定）。这里对**仓库副本**做定向擦除，
#   不动活配置。工作机部署后在 ii 设置里重新填 last.fm apiKey。
CFG="$REPO/configs/.config/illogical-impulse/config.json"
if [[ -f "$CFG" ]]; then
  if (( DRY )); then
    printf '\033[1;35m    would: 擦除 config.json 里的 last.fm apiKey\033[0m\n'
  else
    if grep -qE '"apiKey": "[0-9a-f]{32}"' "$CFG"; then
      sed -i -E 's/("apiKey": ")[0-9a-f]{32}(")/\1\2/' "$CFG"
      ok "已擦除 last.fm apiKey（工作机上重新填，见 MIGRATION.md Phase 7）"
    else
      ok "config.json 里没有待擦除的密钥"
    fi
  fi
fi

# 最终闸门：扫仓库副本里像密钥的东西
if (( ! DRY )); then
  HITS="$(grep -rnE '\b[0-9a-f]{32}\b' "$REPO/configs" 2>/dev/null \
          | grep -v '\.userdb/' \
          | grep -vE 'LOCAL-PATCHES\.md|LastFm\.qml|placeholderCoverHash' || true)"
  if [[ -n "$HITS" ]]; then
    warn "发现可疑的 32 位十六进制串，逐个确认后再提交："
    printf '%s\n' "$HITS" | sed 's/^/    /'
  else
    ok "安全闸门通过：无未处理的密钥形态字符串"
  fi
fi

# ── 汇总 ────────────────────────────────────────────────────────────────
echo
if (( DRY )); then
  echo "════════════════════════════════════════════════════════════════"
  echo " DRY-RUN 结束，未写盘。去掉 --dry-run 正式执行。"
  echo "════════════════════════════════════════════════════════════════"
else
  echo "════════════════════════════════════════════════════════════════"
  echo " 导出完成。仓库总体积：$(du -sh --exclude=.git "$REPO" | cut -f1)"
  echo "════════════════════════════════════════════════════════════════"
  echo " 下一步："
  echo "   git -C $REPO status --short | head -20"
  echo " ⚠️ 提交前必跑敏感信息扫描："
  echo "   grep -rniE 'token|secret|password|api[_-]?key' $REPO/configs | grep -v '\.git/'"
fi
