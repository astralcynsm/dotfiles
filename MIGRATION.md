# 迁移计划与进度账本

> **这份文件是活的。** 每完成一步就勾选，每停下就更新顶部状态块。
> 工作机的 Claude Code 每次会话**先读状态块**再动手。

---

## 状态块

<!-- 工作机 agent：每次停止工作前必须更新这一段 -->

```
当前阶段:     P1
阶段状态:     未开始
上次更新:     2026-10-08
下一步:       在工作机上跑 scripts/doctor.sh 建立基线，并执行 P1 的全部摸底命令
已完成阶段:   P0
阻塞:         无
```

---

## 阶段总览

| 阶段 | 做什么 | 回退代价 | 状态 |
|---|---|---|---|
| **P0** | 主力机建仓与导出 | — | ✅ 完成 |
| **P1** | 工作机摸底（**纯只读**） | 无 | ⬜ |
| **P2** | 仓库落地 + 包基座（含 NVIDIA） | 低 | ⬜ |
| **P3** | Hyprland 最小可跑 | 中 | ⬜ |
| **P3.5** | `hyprctl` 字符串形式现代化（**29 处 dispatch + 21 处 keyword**） | 低 | ⬜ |
| **P4** | ii / quickshell 起来 | 中 | ⬜ |
| **P5** | 主题链打通 | 低 | ⬜ |
| **P6** | ghostty 配色接入 | 低 | ⬜ |
| **P7** | 输入法 + 收尾验收 | 低 | ⬜ |

**排序原则**：会让系统变得难以回退的放后面；桌面无关、能独立验证的放前面。
**回退原则**：出事退到**上一个阶段**，不是修当前阶段。

---

## P0 —— 主力机建仓与导出 ✅

**已完成的**（这些都是事实记录，工作机不需要重做）：

- [x] 归档旧裸仓库 `~/.dotfiles` → `~/.dotfiles.bare.bak`（内容停在 2026-03-17，hyprlang 时代，README 里已声明废弃）
- [x] 克隆 `git@github.com:astralcynsm/dotfiles.git` 到 `~/.dotfiles`
- [x] **机器特定层剥离**：新建 `~/.config/hypr/machine.lua`，`hyprland.lua` 改为最后 `require("machine")`
      - 验证无损：改造前后 `hyprctl binds -j | jq length` 均为 **203**，`hyprctl configerrors` 为空
- [x] 删除 `hyprland.lua` 里对 `initial-boot.sh` 的引用（该脚本从不存在，是空操作）
- [x] `scripts/export-from-arch.sh` —— 14 步导出 + 密钥擦除 + 安全闸门，支持 `--dry-run`
- [x] 导出全部资产到 `configs/` 与 `machine/primary/`
- [x] **擦除真实密钥**：`config.json` 里的 last.fm `apiKey` 已置空（工作机在 P7 重填）

---

## P1 —— 工作机摸底（纯只读）

**目标**：搞清楚这台机器现在是什么状态，为后面每个阶段提供事实依据。
**这一阶段不装任何东西、不改任何文件。**

### 步骤

- [ ] 1.1 硬件与显卡实况
- [ ] 1.2 Hyprland 残留测绘
- [ ] 1.3 GNOME 现状记录（要保留的东西）
- [ ] 1.4 GDM 与 SELinux 现状
- [ ] 1.5 显示器实况 → 填写 `machine/work/profile.toml`
- [ ] 1.6 跑 `scripts/doctor.sh` 建立基线（此时会全红，正常）
- [ ] 1.7 把结论写进下方「摸底结论」节

### 命令

```bash
# 1.1 硬件与显卡
lspci -nn | grep -iE 'vga|3d|display'
ls /dev/dri/
nvidia-smi
cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "nvidia_drm 未加载"
lsmod | grep -E 'nvidia|nouveau'

# 1.2 Hyprland 残留（用户明说试装过但放弃了）
rpm -qa | grep -iE 'hypr|quickshell|waybar|swaync|nwg|greetd|matugen|darkman'
ls -la ~/.config/{hypr,quickshell,illogical-impulse,waybar,swaync,matugen,darkman,theme-switcher} 2>/dev/null
ls -la ~/.config/systemd/user/ 2>/dev/null
systemctl --user list-unit-files 2>/dev/null | grep -iE 'hypr|quickshell|theme|rime'
grep -rn 'hypr\|quickshell' ~/.config/environment.d/ /etc/environment 2>/dev/null
ls /usr/share/wayland-sessions/ /usr/share/xsessions/ 2>/dev/null
ls /etc/xdg/autostart/ | grep -iE 'hypr|quickshell'
dnf copr list 2>/dev/null
dnf repolist --all 2>/dev/null | grep -i hypr

# 1.3 GNOME 现状（之后别被覆盖）
gsettings list-recursively org.gnome.desktop.interface
gsettings get org.gnome.desktop.input-sources sources

# 1.4 GDM 与 SELinux
cat /etc/gdm/custom.conf
getenforce

# 1.5 显示器
ls /sys/class/drm/ | grep -E '^card[0-9]+-'
# 若当前在 GNOME 下，用 gnome-randr 或：
for f in /sys/class/drm/*/modes; do echo "── $f"; head -3 "$f"; done

# 1.6 基线体检
scripts/doctor.sh
```

### 验证

摸底没有"成功/失败"——验证的是**报告完整性**。
每一项残留都必须有「删 / 留 / 隔离 / 改」的结论，写进 `docs/known-issues.md`。

### 失败退

无副作用（全只读）。

### ⚠️ 关键决策：残留的处置

**先隔离，后删除。** 不要直接删：

```bash
mv ~/.config/hypr ~/.config/hypr.pre-migration-$(date +%F)
mv ~/.config/quickshell ~/.config/quickshell.pre-migration-$(date +%F)
rpm -qa > /tmp/rpm-before.txt          # 卸载前的清单
```

保留 30 天再删。

### 完成后要更新

- [ ] `machine/work/profile.toml`（硬件实况）
- [ ] `docs/known-issues.md` 的「工作机残留清单」节
- [ ] 本文件的「摸底结论」节 + 状态块
- [ ] `machine/work/.config/hypr/monitors.lua`（按真实输出名）

---

## P2 —— 仓库落地 + 包基座（含 NVIDIA）

**目标**：一个可用的 CLI 环境 + 输入法 + 字体 + 主题工具，**且 NVIDIA 驱动跑通**。
**不含 Hyprland 与 quickshell** —— 它们分别属于 P3 / P4，要能独立验证。

**前置**：P1 完成；`inventory/cli-candidates.md` **已经用户勾选确认**。

### 步骤

- [ ] 2.1 按 `inventory/mapping.toml` 启用 COPR（**顺序有讲究**）
- [ ] 2.2 装 L1 CLI + L2 输入法 + L3 字体 + L4 主题工具
- [ ] 2.3 **L0.5 NVIDIA**：RPM Fusion + `akmod-nvidia` + 内核参数 + **重启验证**
- [ ] 2.4 逐项填 `mapping.toml` 的 `status`
- [ ] 2.5 跑 `scripts/doctor.sh`，`50-input` 应为绿

### 命令

```bash
# 2.1 COPR（详见 inventory/mapping.toml 与 docs/fedora-notes.md）
#     ★ 同时只启用一个提供 hyprland 的 COPR。本阶段不装 hyprland。
sudo dnf copr enable ririko66z/dots-hyprland      # 字体（ii 需要）
# ... 其余按 mapping.toml

# 2.3 NVIDIA —— 必须在 P3 之前做完并重启验证过
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
sudo dnf install kernel-devel kernel-headers akmods
# 等 akmods 编完模块（`systemctl status akmods` 或看 journalctl -u akmods），再：
sudo akmods --force && sudo dracut --force
# 内核参数：先看现状，再决定加什么
grubby --info=ALL | grep args
# sudo grubby --update-kernel=ALL --args='nvidia_drm.modeset=1'
sudo reboot
```

### 验证

```bash
# 分组装完逐个查
for p in fcitx5 fcitx5-rime fcitx5-chinese-addons ydotool wtype cliphist \
         wl-clip-persist grim slurp satty hyprlock hypridle hyprpicker \
         matugen jq yq ImageMagick rsync createrepo_c; do
  rpm -q "$p" >/dev/null 2>&1 || echo "MISSING: $p"
done

# 字体到位（ii 缺字体会整片豆腐块）
fc-list | grep -ciE 'Google Sans Flex|Readex Pro|Space Grotesk|JetBrainsMono.*Nerd|Material Symbols'

# 输入法（在 GNOME 里就能测）
fcitx5 -d --replace; sleep 1; fcitx5-remote -t

# ★ NVIDIA 闸门（三项全过才继续）
nvidia-smi
lsmod | grep -E '^nouveau' && echo "❌ nouveau 还在" || echo "✓ nouveau 已排除"
cat /sys/module/nvidia_drm/parameters/modeset      # 期望 Y
```

### 失败退

```bash
sudo dnf history undo last        # 撤销最近一次事务
dnf copr disable <repo>           # 某 COPR 有问题时
```

**任何情况下不要 `dnf upgrade`（不带参数）。**

### 完成后要更新

- [ ] `inventory/mapping.toml` 的 status 列（装完的把 `assumed` 改成 `verified`）
- [ ] 本文件状态块

---

## P3 —— Hyprland 最小可跑

**目标**：一个能起、能开终端、键位响应的裸 Hyprland 会话。

**前置**：P1 完成（残留已隔离）；P2 的 NVIDIA 闸门三项全过。

### 步骤

- [ ] 3.1 启用 `copr:sdegler/hyprland`，装 hyprland 及周边
- [ ] 3.2 **版本闸门**：`hyprctl version` ≥ 0.56.0，随即 `dnf versionlock`
- [ ] 3.3 按 P1 摸到的真实输出名重写 `machine/work/.config/hypr/{monitors,workspaces}.lua`
- [ ] 3.4 `scripts/apply-profile.sh work`
- [ ] 3.5 **从 TTY 首跑**（不经 GDM），stderr 直接可见
- [ ] 3.6 跑 `scripts/verify/10-hyprland.sh`

### 命令

```bash
sudo dnf copr enable sdegler/hyprland
sudo dnf install hyprland hyprland-guiutils hyprland-qt-support \
                 xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# 3.2 ★ 版本闸门 —— 不达标就停
hyprctl version | head -1                       # 必须 >= 0.56.0
sudo dnf install python3-dnf-plugin-versionlock
sudo dnf versionlock add hyprland hyprland-guiutils hyprland-qt-support \
     hyprlock hypridle aquamarine hyprutils hyprlang hyprwire \
     xdg-desktop-portal-hyprland

# 3.5 从 TTY 首跑（Ctrl+Alt+F2 登录）
Hyprland 2>&1 | tee ~/hypr-first-run.log
```

### 验证

```bash
hyprctl version | head -1                          # >= 0.56.0
hyprctl configerrors                               # 必须为空
hyprctl monitors -j | jq -r '.[].name'             # 应为本机真实输出名
hyprctl binds -j | jq 'length'                     # 工作机预期 ≈186（源机 203 − Laptops 的 17）
# ⚠ 注册数 ≠ 可用数：另有 50 处「注册了但静默失效」的调用在等着 P3.5
#   （29 dispatch + 21 keyword，见 docs/known-issues.md R7）
```

★ **必测四条**（针对 P3.5 的已知伤）：

```bash
# 1. 运行时派发的 Lua 形式能通
hyprctl dispatch 'hl.dsp.dpms("on")'
# 2. 旧 dispatch 写法**会报错** —— 这是预期的，说明确实需要 P3.5
hyprctl dispatch dpms on          # 期望：error: ... ')' expected near 'on'（exit 7）
# 3. keyword 的坑更阴：报错但 exit 0
hyprctl keyword __nope__ 1; echo "exit=$?"   # 期望：打印 "Use eval." 但 exit=0
# 4. 随机抽 5 条键位实际按一遍
```

### 失败退

1. **回 GDM 选 GNOME** —— GDM 全程未改动，这条路一定在
2. `mv ~/.config/hypr ~/.config/hypr.broken && scripts/apply-profile.sh work`
3. 从 TTY 重跑

### 完成后要更新

- [ ] `machine/work/.config/hypr/monitors.lua`（若摸底值与初版不符）
- [ ] `inventory/mapping.toml`（hyprland 的实测版本号）
- [ ] 本文件状态块

---

## P3.5 —— `hyprctl` 字符串形式现代化（29 处 dispatch + 21 处 keyword）

**为什么单独一个阶段**：删掉旧写法不难，难的是**确认改写后行为一致**。
混在 P3 里会让"Hyprland 起不来"和"某个键位坏了"两种故障混在一起，无法二分。

**背景**：Hyprland 0.56 起，`hyprctl dispatch <字符串>` 会把参数当 **Lua 表达式**解析，
只接受 `HL.Dispatcher` 对象，没有 legacy 字符串兜底；`hyprctl keyword` 更阴 ——
**报错但 exit 0**（调用方查退出码都发现不了）。本仓库里仍有 **29 处 dispatch + 21 处 keyword**
是旧写法，**这些在源机上就是坏的**（不是迁移引入的）。完整清单、逐字错误原文、
两条修复配方（都已在源机实测）见 `docs/known-issues.md` **R7** —— P3.5 就照那张表逐条勾。

### 步骤

- [ ] 3.5.1 打开 `docs/known-issues.md` R7 的清单表逐条勾（它是权威账目）
- [ ] 3.5.2 改写 `hypridle.conf` 的 3 处（**最要紧**：屏幕永不关 + 唤醒后不亮）
- [ ] 3.5.3 改写 `hypr/configs/Keybinds.lua` 的 2 处 —— ⚠ 都嵌在
      `hl.dsp.exec_cmd("hyprctl dispatch …")` 里（壳套壳，双重报废）：
      L20 `exit 0` → 直接换 `hl.dsp.exit()`；L40 `splitratio 0.3` → **API 无对应**，见下
- [ ] 3.5.4 改写 `UserKeybinds.lua` 的 1 处（L65，同样嵌在 exec_cmd 里：
      `workspaceopt allfloat` → **API 无对应**，见下）
- [ ] 3.5.5 改写 `scripts/Dropterminal.sh` 的 18 处（下拉终端整条链路）
- [ ] 3.5.6 改写 `Tak0-Autodispatch.sh` 的 4 处（`scripts/` 与 `UserScripts/` 各有一份拷贝）
- [ ] 3.5.7 改写 5 个脚本里的 21 处 `keyword`：`ChangeLayout.sh` 12、
      `ChangeBlur.sh` 4、`UserKeybinds.lua` 2（SUPER+ALT+滚轮缩放）、
      `TouchPad.sh` 2（笔记本功能，工作机最后顺手处理）、`GameMode.sh` 1
- [ ] 3.5.8 `.zshrc:86` 的 `hrun` 别名（`hyprctl dispatch exec`）→ 改成函数
      `hrun() { hyprctl dispatch "hl.dsp.exec_cmd('$*')"; }`，或删掉
- [ ] 3.5.9 **逐一实测**，不批量 sed

### 已知映射

| 旧 | 新 |
|---|---|
| `hyprctl dispatch dpms off\|on` | `hyprctl dispatch 'hl.dsp.dpms("off")'` |
| `hyprctl dispatch exit 0` | `hyprctl dispatch 'hl.dsp.exit()'` |
| `hyprctl dispatch exec "..."` | `hyprctl dispatch 'hl.dsp.exec_cmd("...")'` |
| `hyprctl dispatch submap reset` | `hyprctl dispatch 'hl.dsp.submap("reset")'` |
| `hyprctl dispatch focuswindow "address:X"` | `hl.dsp.focus({window=X})` — **要实测** |
| `hyprctl dispatch movetoworkspacesilent "N,address:X"` | `HL.DspWindowNamespace.move` — **读 stub 实测签名** |
| `hyprctl dispatch workspace N` | `hl.dsp.workspace.change_id({workspace=?, id=N})` — 报错原文要求 table |
| `hyprctl keyword X Y` | `hyprctl eval 'hl.config({ … })'` — **已在源机实测**（写原值 → ok/exit 0；写错键名 → 响亮报错 exit 7）。改写前先 `hyprctl getoption X` 读原值，改完再读一遍比对 |
| `hyprctl keyword X Y -r`（runtime 标志） | `TouchPad.sh` 用到；`hl.config` 是否有 runtime 语义**未实测** —— 试完把结论记回 R7 |
| `hyprctl keyword unbind/bind …` | 桩里有 `hl.unbind(key)`；**运行时行为未实测**（ChangeLayout.sh 大面积用到）—— 先拿废弃键位试，别拿真键 |
| `hl.dsp.exec_cmd("hyprctl dispatch …")`（嵌套） | **把 shell 层整个删掉**，直接写 `hl.dsp.…()` |

⚠️ **`workspaceopt` 与 `splitratio` 在 0.56 的 Lua API 里找不到对应**
（以 `/usr/share/hypr/stubs/hl.meta.lua` 为准，它是官方自动生成的权威 API 面；
别的仓/博客里写的 `hl.dsp.split_ratio` 之类**全是编的**）。它们不是"改写"，是"消失"——
现场分别是 `Keybinds.lua:40`（SUPER+M）与 `UserKeybinds.lua:65`（SUPER+ALT+SPACE）。
候选替代（都要现场试，试完记结论）：
- `allfloat` → `hl.dsp.window.float()`（stub 确认存在）逐窗循环，看语义差多少
- `splitratio` → stub 里**没有任何 ratio 类动词**；`hl.dsp.layout(...)` 只是旧
  `layoutmsg` 的转发 dispatcher，试试它能不能带到 ratio：不能就如实标
  「0.56 无对应，功能搁置」并告诉用户这两条键位没了。

### 验证

```bash
# dispatch：改完后除注释/文档外应为 0
grep -rn 'hyprctl dispatch' configs/ | grep -vE "dispatch ['\"]?hl\.dsp" | grep -v '\.bak' \
  | grep -v 'LOCAL-PATCHES.md'
#   ↑ 剩下的应该只有 hypridle.conf 2 行注释 + hyprland.lua 1 行警示（说明文字，无害）

# keyword：改完后应为 0 处活跃调用（UserKeybinds 里 2 行注释不算）
grep -rn 'hyprctl keyword' configs/ | grep -v '\.bak'

# 逐条实测（至少这几条）
hyprctl dispatch 'hl.dsp.dpms("off")' && sleep 1 && hyprctl dispatch 'hl.dsp.dpms("on")'
hyprctl eval 'hl.config({ decoration = { blur = { size = 6 } } })'   # 原值回写 → ok / exit 0
systemctl --user start hypridle && journalctl --user -u hypridle -n 20   # 无 dispatch 报错
# SUPER+SHIFT+Return 下拉终端能弹出（18 处修完后）
# CTRL+ALT+DELETE 能退出 Hyprland（小心：会退出会话）
# SUPER+ALT+O 模糊开关、SUPER+ALT+L 布局切换：按两下看状态变化
# SUPER+M 与 SUPER+ALT+SPACE：若走替代实现，重点验证语义（见上面「无对应」）
```

### 失败退

逐文件提交，`git revert <sha>` 回单条。

---

## P4 —— ii / quickshell 起来

**目标**：能显示 bar、左右栏能开、Super 搜索能出的 ii。

**前置**：P3 完成（Hyprland 能跑）。

### 步骤

- [ ] 4.1 按 ii 上游的 Fedora 路径装 `quickshell-git` + `versionlock`
- [ ] 4.2 **★ 二进制核对**：`qs --version` 的 revision 与 `ii-patches/quickshell.lock` 比对
- [ ] 4.3 `scripts/apply-profile.sh work` 铺 ii 全树 + `illogical-impulse/`
- [ ] 4.4 部署 systemd 单元 + `daemon-reload`
- [ ] 4.5 重建 python venv（switchwall 需要）
- [ ] 4.6 **前台首跑** `qs -c ii`，QML 报错直接可见
- [ ] 4.7 切 systemd，跑 `scripts/verify/20-quickshell.sh`

### 命令

```bash
# 4.1 ii 上游的 Fedora 路径（详见 docs/fedora-notes.md）
#     从 GitHub packages-fedora release 下预编译 rpm → createrepo_c → dnf install
#     然后再 clone ii 源码取 quickshell 的 PKGBUILD/spec 逻辑

# 4.2 ★ 闸门
rpm -ql quickshell-git | grep -E 'bin/'
command -v qs quickshell
qs --version        # 必须含 revision 7511545ee20664e3b8b8d3322c0ffe7567c56f7a（对照 ii-patches/quickshell.lock）
sudo dnf versionlock add quickshell-git

# 4.5 venv
sudo dnf install python3.12 python3.12-devel
python3.12 -m venv ~/.local/state/quickshell/.venv
~/.local/state/quickshell/.venv/bin/pip install materialyoucolor pillow

# 4.6 前台首跑（别用 systemd，这样报错直接可见）
QSG_RENDER_LOOP=threaded qs -c ii 2>&1 | tee ~/ii-first-run.log
```

### 验证

```bash
systemctl --user start hyprland-session.target
systemctl --user status quickshell-ii.service --no-pager
journalctl --user -u quickshell-ii -n 200 | grep -iE 'TypeError|ReferenceError|is not a function|Cannot read'
# 期望：无输出
qs list        # 确认实例唯一

# ★ 保活验证（这是 quickshell-ii.service 存在的理由）
kill -9 $(systemctl --user show -p MainPID --value quickshell-ii.service)
sleep 6; systemctl --user is-active quickshell-ii.service     # 期望 active

# ★ cgroup 隔离验证（2026-09-25「kill 带走 Steam + 游戏」事故的回归测试）
# 从 bar 启动一个应用，然后 kill quickshell 主进程
# 期望：bar 几秒后回来，从 bar 启动的应用没死
```

### 失败退

```bash
systemctl --user stop quickshell-ii && systemctl --user disable quickshell-ii
# Hyprland 仍可用，只是没 bar
mv ~/.config/quickshell/ii{,.broken} && scripts/apply-profile.sh work
```

### 完成后要更新

- [ ] 状态块
- [ ] `docs/known-issues.md`（若发现新的 QML 报错）

---

## P5 —— 主题链打通

**目标**：换壁纸 → 边框/GTK/fcitx5/KDE 全套跟着变。

**前置**：P4 完成。

### 步骤

- [ ] 5.1 装 matugen（**版本必须是 3.x**，源机补丁按 3.1.0 写的）
- [ ] 5.2 铺 `matugen/config.toml` + `templates/**`
- [ ] 5.3 逐个确认 18 个 `output_path` 在 Fedora 上成立（`foot` 与 `ghostty` 两条：ghostty 已在本机打通，见 P6）
- [ ] 5.4 铺 `theme-switcher/`，改 `COMPONENT_MAP`
- [ ] 5.5 darkman（Go 源码编译）+ `theme-auto-mode.timer`
      ⚠ 钩子必须放 `~/.local/share/{dark,light}-mode.d/`（放 `~/.config/darkman/` =
      静默永不跑），且**只认执行位**：停用 = `chmod -x`，改 `.disabled` 文件名无效。
      验证：`journalctl --user -u darkman | grep -E "Found|Running script"`。见 known-issues R8
- [ ] 5.6 跑 `scripts/verify/30-theme-chain.sh`

### 验证

```bash
~/.config/theme-switcher/switch.sh -l          # 列出全部主题
~/.config/theme-switcher/switch.sh gruvbox-dark && sleep 1

# ★ 核心判据：换主题后这些产物的 mtime 都该动
for f in ~/.config/hypr/colors.lua ~/.config/hypr/hyprlock/colors.conf \
         ~/.local/state/quickshell/user/generated/colors.json \
         ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css; do
  find "$f" -mmin -1 -print 2>/dev/null
done
# 期望：5 行全有

# ★ 最关键的一条：colors.json 的 mtime
#    它是 ii 整个界面配色的来源，它不更新 = 主题链断在最有价值的一环
ls -l --time-style=full-iso ~/.local/state/quickshell/user/generated/colors.json

# matugen 那步不能报错（源机已知坑：报错后脚本不中止，
# 结果是「换了壁纸但 ii 配色纹丝不动」）
~/.config/theme-switcher/switch.sh matugen ~/Pictures/wallpapers/<某张>.png
sleep 3; journalctl --user -n 50 | grep -i matugen
```

### 失败退

```bash
~/.config/theme-switcher/switch.sh <之前的主题名>   # current 文件里记着上一个
git checkout configs/.config/matugen/config.toml
```

---

## P6 —— ghostty 配色接入

**目标**：换主题/换壁纸时 ghostty 跟着变。

**前置**：P5 完成。

**背景**：`~/.config/ghostty/config` 最后一行是 `config-file = ~/.config/ghostty/active-theme`，
与 foot 的 `current_theme.ini` 机制**完全同构**。所以接法与 foot 一致。

### 步骤

- [ ] 6.1 新建 `matugen/templates/ghostty/{dark,light}` 模板（**ghostty 的 theme 文件是单模式文件**，
      不像 foot 有 `[colors-dark]` 段，所以必须两个条目两个文件）
- [ ] 6.2 `matugen/config.toml` 加 `[templates.ghostty_dark]` / `[templates.ghostty_light]`
      → 输出到 `~/.config/ghostty/themes/matugen-{dark,light}`（**不直接覆盖 active-theme**）
- [ ] 6.3 `switch.sh`：`COMPONENT_MAP` 加一行 + 仿 `sync_foot_matugen()` 加 `sync_ghostty_matugen()`
- [ ] 6.4 `switch.sh`：仿 `reload_foot()` 加 `reload_ghostty()`
- [ ] 6.5 把 `themes/{dark,light}` 作为静态主题素材搬进 `theme-switcher/assets/<主题名>/`
- [ ] 6.6 **保留 `background-opacity = 0.85`** —— 模板里要带上，否则换主题透明度就没了
- [ ] 6.7 跑 `scripts/verify/40-ghostty.sh`

### 热重载机制（已实测）

`ghostty +reload-config` **不存在**。但 `reload-config` 是注册的 GTK action，走 D-Bus：

```bash
gdbus call --session --dest com.mitchellh.ghostty \
  --object-path /com/mitchellh/ghostty \
  --method org.gtk.Actions.Activate reload-config [] {}
```

⚠️ 要挂进 `set_terminal_theming()` 的 static/matugen 分工开关，否则和静态主题打架。

### 验证

```bash
ghostty +show-config | grep -E '^(background|foreground|palette|selection)'
~/.config/theme-switcher/switch.sh kanagawa-dark
diff <(cat ~/.config/ghostty/themes/kanagawa-dark) <(cat ~/.config/ghostty/active-theme)
# 期望：无差异
grep -c '^palette' ~/.config/ghostty/active-theme      # 期望 16
```

★ **必测**：`background-opacity` 在 matugen 主题下仍在。

### 失败退

```bash
cp ~/.config/ghostty/themes/dark ~/.config/ghostty/active-theme
git checkout configs/.config/matugen/config.toml configs/.config/theme-switcher/switch.sh
```

---

## P7 —— 输入法 + 收尾验收

### 步骤

- [ ] 7.1 rime 用户数据（userdb + 用户配置，**不带 90M 上游数据**）
- [ ] 7.2 用 plum 重装 rime-ice 上游方案数据
- [ ] 7.3 `fcitx5/profile` + `fcitx5/config`
- [ ] 7.4 环境变量写进 `~/.config/environment.d/`（**不写 `/etc/environment`**）
- [ ] 7.5 `term-exec` 的 `EXEC=foot` → `ghostty`；`01-UserDefaults.lua` 的 `term`
- [ ] 7.6 `Startup_Apps.lua` 逐条清理（Arch 专属启动项、Fedora 路径核对、`XDG_MENU_PREFIX`）
- [ ] 7.7 ii 维护页的 8 条 Arch 命令改 dnf
- [ ] 7.8 **重填 last.fm apiKey**（导出时被擦除了，见下）
- [ ] 7.9 跑 `scripts/doctor.sh` 全绿
- [ ] 7.10 **键位逐项过一遍**（照 `SUPER+SHIFT+H` 速查表；工作机预期 ≈186 = 203 − Laptops 17。
      **先确认 P3.5 已清零**——否则数出来的是「注册 ≠ 能用」的假数）

### ★ 7.8 last.fm apiKey

导出时从 `config.json` 里**擦除**了真实的 last.fm API key（安全约定：真 token 不进仓库）。
工作机上需要在 ii 的设置界面（或直接编辑 `~/.config/illogical-impulse/config.json`
的 `stats.lastFm.apiKey`）重新填入。

**key 的值由用户提供**（它只存在于主力机的活配置里，仓库里没有）。

⚠️ 注意 ii 里有**两处**同名 key：`stats.lastFm.apiKey`（个人 key）和
`services/LastFm.qml` 的 `placeholderCoverHash`（那是 last.fm 官方的占位封面哈希，
公开的，**不是密钥**，别动）。

### 命令

```bash
# 7.1
rsync -a ~/.dotfiles/configs/.local/share/fcitx5/rime/ ~/.local/share/fcitx5/rime/

# 7.2 重装上游方案数据（仓库里没带那 90M）
sudo dnf install fcitx5-rime
# 用 plum 装 rime-ice —— 具体命令见 docs/fedora-notes.md

# 7.4 环境变量（Fedora 用 environment.d，不污染 /etc/environment）
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/90-fcitx.conf <<'EOF'
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
FC_LANG=und
EOF
# ⚠️ 不要写 QT_IM_MODULE / GTK_IM_MODULE —— 见 CLAUDE.md 硬约束 3

# 7.6 XDG_MENU_PREFIX：先看实况再定
ls /etc/xdg/menus/
```

### 验证

```bash
scripts/doctor.sh

# 输入法
fcitx5-remote -t; sleep 1
# 随便找个能打字的地方按 Super+Space，出中文候选框

# 锁屏
loginctl lock-session && sleep 2 && pidof hyprlock

# 挂起前后（对应 hypridle 的 after_sleep_cmd；若 P3.5 没改这条，这里会黑屏）
systemctl suspend

# 应用菜单（验证 XDG_MENU_PREFIX 对不对）
# ii 的 Super 搜索里应能列出应用，不是 0 个
```

---

## 摸底结论

<!-- Phase 1 完成后填写 -->

_（待填：工作机硬件实况、残留清单及处置、显示器真实输出名）_

---

## 阻塞

<!--
格式：
### YYYY-MM-DD 阶段 PN —— 一句话现象
- 已试过什么
- 需要什么信息 / 什么决定
-->

_（无）_
