# 回退手册

**总原则**：出事退到**上一个阶段**，不是修当前阶段（修是在修明白之后才做的事）。
三级退路从轻到重：**会话级 → 文件级 → 系统级**。GDM 的 GNOME 会话全程未动，永远是最后一张底牌。

---

## 第 0 级：会话级（30 秒）

任何"桌面炸了"的场景，先回能用的会话再说：

1. `Ctrl+Alt+F3` 切 TTY，登录
2. 回 GDM 的图形会话：`sudo systemctl restart gdm`（会杀掉当前图形会话）
3. 在 GDM 登录界面齿轮里选 **GNOME** —— 这是不变的退路

不要在这一步纠结 Hyprland 为什么炸。先活着，再分析。

## 第 1 级：文件级（分钟级）

### 自动备份（apply-profile.sh 的产物）

每次 `apply-profile.sh` 运行会把**被覆盖的旧文件**备份到：

```
~/.dotfiles-backup/<时间戳>/
```

内部目录结构与 `$HOME` 一致。恢复某个文件：

```bash
cp -a ~/.dotfiles-backup/20261009-120000/.config/hypr/machine.lua ~/.config/hypr/machine.lua
```

恢复整个被覆盖的子树（示例：整个 hypr 配置）：

```bash
rsync -a --backup-dir=~/.dotfiles-backup/manual-$(date +%Y%m%d-%H%M%S) \
  ~/.dotfiles-backup/20261009-120000/.config/hypr/ ~/.config/hypr/
```

### 手动改系统文件前（纪律）

改 `/etc/environment`、`/etc/gdm/*`、systemd 单元这类文件前，先：

```bash
sudo cp -a /etc/environment /etc/environment.bak-$(date +%F)
```

### Hyprland 配置炸到起不来

```bash
# 从 TTY：
mv ~/.config/hypr ~/.config/hypr.broken
cd ~/.dotfiles && scripts/apply-profile.sh work
# 还不行 → 回 GNOME（第 0 级），把 ~/.config/hypr.broken 里的日志/报错拿出来分析
```

### quickshell / bar 炸

```bash
systemctl --user stop quickshell-ii          # 停
qs -c ii                                     # 前台跑，报错直接可见（Ctrl+C 退出）
journalctl --user -u quickshell-ii -n 100 --no-pager   # 看历史崩溃
# 配置坏了：
mv ~/.config/quickshell/ii ~/.config/quickshell/ii.broken
cd ~/.dotfiles && scripts/apply-profile.sh work
```

### repo 级回退

```bash
git -C ~/.dotfiles log --oneline -10         # 找到坏提交
git -C ~/.dotfiles revert <sha>              # 生成反向提交
git -C ~/.dotfiles push                      # 推上去（绝不 --force）
```

工作机拿到回退：`git pull && scripts/apply-profile.sh work`。

## 第 2 级：系统级（装错了东西）

### dnf 包

```bash
sudo dnf history list | head              # 找到装 Hyprland/驱动的那个 transaction id
sudo dnf history undo <id>
```

### COPR 源

```bash
sudo dnf copr disable sdegler/hyprland    # 停用（保留已装包）
sudo dnf copr remove  sdegler/hyprland    # 连包删除（危险，确认后再做）
```

### versionlock

```bash
dnf versionlock list                      # 看锁了什么
sudo dnf versionlock delete hyprland      # 解一个
```

### systemd 用户单元

```bash
systemctl --user disable --now quickshell-ii
systemctl --user daemon-reload
```

### 输入法环境变量

改 `/etc/environment` 前如果按纪律备份了：

```bash
sudo cp -a /etc/environment.bak-<日期> /etc/environment   # 然后重新登录
```

## 各阶段的"失败退"（MIGRATION.md 里也各有一份，此处总览）

| 阶段 | 出事退法 | 备注 |
|---|---|---|
| P2 包基座 | `dnf history undo`；COPR disable | NVIDIA 驱动出问题：回 GNOME（GNOME 也用它，一般没问题）|
| P3 Hyprland | 回 GDM→GNOME；`mv ~/.config/hypr{,.broken}` + 重新 apply-profile；从 TTY 重跑 | 配置全在文件层，好退 |
| P3.5 hyprctl 修复 | 逐文件提交，`git revert` 单条 | 不批量 sed 的理由之一就是好退 |
| P4 ii | `systemctl --user stop quickshell-ii`；`mv ~/.config/quickshell/ii{,.broken}` | 停了只是没 bar，Hyprland 还能用 |
| P5 主题链 | 恢复备份的 matugen/theme-switcher/darkman 配置 | 生成物（colors.*）重跑一次主题就回来了 |
| P6 ghostty | `~/.config/ghostty/active-theme` 指回静态主题 | 纯文件 |
| P7 输入法 | 恢复 `/etc/environment.bak-*`；`fcitx5 -r`；userdb 有单独备份 | **userdb 永不删** |

## 绝对不做的事

- ❌ `git push --force`（任何情况）
- ❌ 删 rime userdb（多年词频，不可再生）
- ❌ 动 GDM / 系统登录器（它是退路本身）
- ❌ 对 `~/.config` 里任何目录用 `rsync --delete`
