# 已知问题与雷区（R1–R8）

> 改任何东西之前把这份扫一遍。每条都是**主力机上真实踩过的**，带证据与验证手法。
> 格式：症状 / 根因 / 证据 / 修法与验证。
> 工作机遇到新坑请追加为 R9+，并保持同样格式 —— 这份文档的价值全在"证据"上。

**证据时间是 2026-10-08（主力机）。** 引用行号/统计的地方，用每节附的复现命令重新数一遍再信。

---

## R1 三个组件的版本是钉死的（漂移 = 整套桌面碎掉）

| 组件 | 钉死的版本 | 为什么不能随便升 |
|---|---|---|
| Hyprland | **0.56.2**（commit `efb50993780079460b0cbed1363e2166a2de1d9f`）| 全套配置是 Lua（0.55 起弃用 hyprlang，0.56 移除 `hyprctl dispatch` 字符串形式 → 见 R7）。换版本可能直接加载失败 |
| Quickshell | **0.2.1 revision `7511545ee20664e3b8b8d3322c0ffe7567c56f7a`** | ii 的本地补丁是按此版本写的；此版本**没有 `keepAlive` 属性**（bar 保活靠 systemd，见 R5）|
| matugen | **3.1.0** | `config.toml` 的 16 个模板按此版本语法写（`{{mode}}` 等）；Fedora 官方源没有，别图省事直接拉最新 |

验证：

```bash
hyprctl version | head -2        # 实测输出 0.56.2 / commit efb5099… / Tag v0.56.2
qs --version                     # 0.2.1，revision 见 MIGRATION.md P3
matugen --version                # 3.1.0
```

Fedora 侧装完立刻锁：`sudo dnf versionlock add hyprland quickshell-git matugen`
（Fedora 的 Hyprland 走 COPR `sdegler/hyprland`，COPR 更新不受你控）。

---

## R2 ii 的上游同步会覆盖本地补丁

`~/.config/quickshell/ii/` 树里有一批**新增 + 改动文件**是本地补丁（**别在别处记数** ——
准确清单以登记册为准），上游（end-4/dots-hyprland）或安装器一旦整体覆盖就会丢。
登记册是 `configs/.config/quickshell/ii/LOCAL-PATCHES.md`（§1–§13，每节带实测数据；
文件清单 = 顶部总表 + 各节内的补充表）。

- **部署后不要再跑 ii 安装器的 files 阶段**（它按上游树覆盖）。
- 同步上游的流程与冲突清单见 `docs/upstream-sync.md`。
- 判据：`diff -rq 仓库版ii 运行版ii`，差异只允许出现在 LOCAL-PATCHES 登记过的文件里。

---

## R3 rsync 方向：导出用 `--delete`，部署**绝不**用

| 方向 | 用 --delete？ | 理由 |
|---|---|---|
| 主力机导出 → 仓库（`scripts/export-from-arch.sh`）| ✅ 用 | 仓库要忠实反映活配置，不留陈旧文件；**git 是安全网**，导错 `git checkout .` 就回来 |
| 仓库部署 → 工作机（`scripts/apply-profile.sh`）| ❌ **绝不用** | 会删掉 ii 运行期生成的文件与上游带下来的文件 —— 目标目录不是纯净的 `$HOME` |

`apply-profile.sh` 除了不 `--delete`，还会先把将被覆盖的文件备份到
`~/.dotfiles-backup/<时间戳>/`。

---

## R4 `QT_IM_MODULE` 只给一个服务加；GTK 那个哪都不放

环境变量分工（三条都是硬约束，别"顺手"改）：

| 变量 | 放哪 | 为什么 |
|---|---|---|
| `XMODIFIERS` / `SDL_IM_MODULE` / `FC_LANG` | 全局（Fedora: `~/.config/environment.d/90-fcitx.conf`）| 无害，通用 |
| `QT_IM_MODULE=fcitx` | **只给 `quickshell-ii.service`**（unit 的 Environment=）| quickshell 是 Qt 又不走 text-input 协议，没有它**面板里打不出中文**；全局加它会连累其他 Qt 应用（用户刻意不做）|
| `GTK_IM_MODULE` | **哪里都不放** | Wayland 下设它会绕过 text-input 协议，fcitx5 官方不建议 |

主用机 `/etc/environment` 里 `QT_IM_MODULE` / `GTK_IM_MODULE` 两行是**故意注释掉的**
（注释里的说明别删）。工作机对应物是 `environment.d/90-fcitx.conf`，同样不放这两条。

验证（qs 吃没吃 fcitx）：

```bash
PID=$(systemctl --user show -p MainPID --value quickshell-ii)
grep -ci fcitx /proc/$PID/maps     # 有 QT_IM_MODULE 时 ≈10，没有 = 0
```

---

## R5 NVIDIA：一层崩溃 + 一层连坐（工作机也是 N 卡，全款高危）

### (a) 崩溃根因在 nvidia EGL，不在 QML

2026-09-25 事故：quickshell 渲染线程 SIGSEGV。带符号 core 的栈是
`#0 0x0 ← libnvidia-eglcore.so → libQt6Gui → QRhi::endFrame()`
—— **NVIDIA EGL 核心里调了个空函数指针，在 swap 帧时炸的**。诱因是显存+内存双向挤压
（NMS + gamescope + QQ×3 @ 4060 Laptop 8G 显存 / 15G 内存），前兆日志：

```
eglSwapBuffers failed with 0x3003          ← EGL_BAD_ALLOC
Failed to allocate NVKMS memory for GEM object   ← 显存满 → sysmem 回退 → 也满 → 硬失败
```

即：不是 ii/QML 写错了，**改成 QML 无用**。能做的只有压力管理与重启策略（(c)）。

排查手法（可复用）：

```bash
coredumpctl list                                     # 找 quickshell 的 core
coredumpctl dump <pid> --output=/tmp/x.core
gdb -batch -nx -ex "bt 30" -ex "info thread" /usr/bin/quickshell /tmp/x.core
# quickshell-git 是 RelWithDebInfo **带符号**，栈比 systemd-coredump 自带的可信得多
```

qs 自己的日志：`/run/user/1000/quickshell/by-id/<id>/log.log`（纯文本好 grep）；
崩溃报告 `~/.cache/quickshell/crashes/<旧id>/report.txt`。
⚠ qs 的 crash handler 会**内部重启**，一次崩溃留两个 by-id 目录，别看错。

### (b) 连坐：qs 崩 → 从 bar 启动的 app 全灭

ii 的应用是 qs 进程 `desktopEntry.execute()` 直接 fork 的（10 处调用点），子进程
cgroup 就是 `quickshell-ii.service`；systemd 默认 `KillMode=control-group`，qs 一死
systemd 停 unit 时**把整个 cgroup 清场** —— QQ×3 / Steam / GameScope / 无人深空 /
Proton 全部陪葬（2026-09-25 实况）。

**修法（已落地，不能丢）**：unit 里 `KillMode=process` —— 只杀主进程，孤儿留着。
差分实验（零风险复现手法，值得照抄）：

```bash
systemd-run --user --unit=killtest-proc --property=KillMode=process       -- /bin/sh -c 'sleep 311 & sleep 4'
systemd-run --user --unit=killtest-ctrl --property=KillMode=control-group -- /bin/sh -c 'sleep 313 & sleep 4'
sleep 9; pgrep -af "sleep 31[13]"    # process 的活、control-group 的死
systemctl --user reset-failed killtest-proc killtest-ctrl
```

副作用：孤儿 app 从此不会被 `systemctl --user stop/restart quickshell-ii` 带走。

### (c) 重启配额：撞限后 bar 不会自己回来

2026-09-29 复发：启动期就 `Could not create EGL surface (EGL error 0x3003)` → 崩 →
gs 内部拒绝自重启 → 循环 12 次只花 4 秒 → **`start-limit-hit`**，此后 systemd
**不再拉起**，GPU 压力早过去了 bar 也回不来。修后的四个值（原样保留）：

```ini
Restart=always
RestartSec=3                 # 原 1s 太急
StartLimitIntervalSec=300    # 原 60
StartLimitBurst=20           # 原 10
```

人工恢复：`systemctl --user reset-failed quickshell-ii && systemctl --user start quickshell-ii`

⚠ 两个查错坑：`systemctl show` 里属性名是 **`RestartUSec` / `StartLimitIntervalUSec`**
（写 `RestartSec` 查不到，**静默无输出**，看着像"没生效"）。

### (d) 顺带：通知名会被 swaync 抢

崩溃瞬间 DrKonqi 发通知 → D-Bus 激活拉起 `swaync` → 它抢 `org.freedesktop.Notifications`
→ qs 重启后注册不上通知服务。`systemctl --user stop/disable` **都挡不住**
（swaync 的包自带 D-Bus activation 文件，绕开 systemd enablement），
**唯一可靠解法 `systemctl --user mask swaync`**（工作机若装了 swaync 同理）。

---

## R6 matugen：版本固定 + 两个已知坑

- 版本见 R1。模板 16 个的对照表在 `docs/ARCHITECTURE.md` §4.1。
- `matugen --mode` 的默认值是 **dark** —— 曾经有个 bug 是调用方没显式传 `--mode`，
  换壁纸时把浅色主题算成深色（foot 的 `initial-color-theme` 是另一处同类坑，
  见 `configs/.config/theme-switcher/README.md` 的 foot 一节）。
  **规则：任何调 matugen 的地方都要显式 `--mode`。**
- Fedora 获取：COPR `avengemedia/danklinux` 或 `cargo install matugen --version 3.1.0`；
  装完先整体跑一遍 config.toml，把 16 个产物与主力机的对一遍（模板语法是版本敏感的）。

---

## R7 ★ `hyprctl` 的字符串形式在 0.56 全灭（dispatch + keyword）

**这是全套配置里最大的一批"静默失效"**，工作机必须整批修，否则会以为"键位都迁过去了"
而实际一堆键按了没反应。

### 机制与实测原文（2026-10-08 在 0.56.2 上实测）

`hyprctl dispatch <旧式字符串>` 会把参数**包装成 Lua 表达式** `return hl.dispatch(<你的参数>)`
去解析 —— 旧式多词字符串必然语法错误：

```
$ hyprctl dispatch movewindowpixel "exact 0 0,address:0xdeadbeef"
error: [string "return hl.dispatch(movewindowpixel exact 0 0,..."]:1: ')' expected near 'exact'

 → Note: dispatch in lua is a shorthand for hl.dispatch(...), your syntax might need to be updated.
（exit 7）
```

`hyprctl keyword` 更阴 —— **exit 0**，脚本连退出码都查不出来：

```
$ hyprctl keyword __this_key_does_not_exist__ 1
keyword can't work with non-legacy parsers. Use eval.
（exit 0）
```

共同症状：**调用方不查退出码 → "这个键没反应"**。
（`hl.dsp.*` 形式是好的：`hyprctl dispatch 'hl.dsp.focus({monitor="…"})'` → 语义层正常执行。）

### 活跃调用清单（主力机实测 29 处 dispatch + 21 处 keyword）

复现命令：

```bash
grep -rn 'hyprctl dispatch' ~/.config/hypr ~/.config/quickshell/ii ~/.zshrc ~/.local/bin \
  | grep -vE "dispatch ['\"]?hl\.dsp" | grep -v '\.bak'
grep -rn 'hyprctl keyword'  ~/.config/hypr ~/.config/quickshell/ii ~/.zshrc ~/.local/bin \
  | grep -v '\.bak'
```

| 文件 | 处数 | 类型 | 受影响的键/功能 |
|---|---|---|---|
| `hypr/scripts/Dropterminal.sh` | 18 | dispatch | `SUPER+SHIFT+Return` 下拉终端 —— **整条功能是坏的** |
| `hypr/hypridle.conf` | 3 活 + 2 注释 | dispatch | 空闲 DPMS 关屏/亮屏 |
| `hypr/UserConfigs/UserKeybinds.lua:65` | 1 | dispatch | `SUPER+ALT+SPACE` allfloat |
| `hypr/configs/Keybinds.lua:20` | 1 | dispatch | `CTRL+ALT+DELETE` 退出 Hyprland |
| `hypr/configs/Keybinds.lua:40` | 1 | dispatch | `SUPER+M` splitratio |
| `hypr/scripts/Tak0-Autodispatch.sh` | 2 | dispatch | 自动派窗（`UserScripts/` 下另有一份拷贝同样坏）|
| `.zshrc:86` | 1 | dispatch | `hrun` 别名（`hyprctl dispatch exec`）|
| `hypr/UserConfigs/UserKeybinds.lua:69,70` | 2 | keyword | `SUPER+ALT+滚轮` 光标缩放 |
| `hypr/scripts/GameMode.sh` | 1 | keyword | `SUPER+SHIFT+G` 动画开关 |
| `hypr/scripts/ChangeBlur.sh` | 4 | keyword | `SUPER+ALT+O` 模糊开关 |
| `hypr/scripts/ChangeLayout.sh` | 12 | keyword（含 bind/unbind）| `SUPER+ALT+L` 布局切换 |
| `hypr/scripts/TouchPad.sh` | 2 | keyword | 触摸板开关（笔记本特有，machine/primary）|

不在账上的：`.bak-*` 备份文件（导出时排除）、`LOCAL-PATCHES.md` 里的说明文字、
`.local/bin/hyde-shell`（HyDE 遗留，仓库不收）。

### 修复配方（两条都已在主力机实测通过）

```bash
# dispatch：参数写成 hl.dsp.* 表达式
hyprctl dispatch 'hl.dsp.exec_cmd("foot")'

# keyword：走 eval + hl.config（实测：原值回写 → ok / exit 0；写错键名 → 响亮报错 exit 7）
hyprctl eval 'hl.config({ decoration = { blur = { size = 6 } } })'
```

⚠ 两个**没有现代对应项**的：

- `workspaceopt allfloat` —— `hl.dsp` 全部子命名空间里都没有（以
  `/usr/share/hypr/stubs/hl.meta.lua` 为准，这份是官方自动生成的权威 API 面）；
- `splitratio` —— 同样不存在。

这两个只能用 `hyprctl eval` 自己迭代窗口实现（或改成相近的 `hl.dsp.window.float` 语义），
**别的仓/博客里的 `hl.dsp.split_ratio` 之类名字全是编的**，别信。

`hl.unbind("SUPER + J")` 在桩里存在（ChangeLayout.sh 的 `keyword unbind` 对应它），
但**运行时行为未实测** —— 改 ChangeLayout 时先在一个废弃键位上验证，别拿真键试。

### 对迁移的含义（重要）

「键位一个不能丢」不能只数 `hyprctl binds -j | jq length`（注册 ≠ 能用）。
工作机 P3 装完、P7 收尾时，**必须把上面这张表逐条修掉并实测按键**，
否则迁过去的是一批"看着在、按了没反应"的键。
`hyprland.lua` 顶部已有一条警告注释，可以对照。

---

## R8 ★ darkman 钩子：只认执行位；放错目录 = 静默永不跑

darkman 是明暗的**系统级仲裁者**（portal `color-scheme` 的来源 —— Firefox / QQ /
Electron 跟它变），它和 theme-switcher 各有一套日出日落逻辑（darkman 配置在杭州、
auto-mode 在上海，触发点差 ~2 分钟；auto-mode 先到，所以没炸）。

### 三条铁律（全部实测）

1. **只认执行位，不看文件名**（二进制内错误串原文 `File not executable; ignoring.`）。
   - 停用钩子 = `chmod -x`；恢复 = `chmod +x`；
   - **改名 `.disabled` 完全无效** —— 2026-09-20 就是这么"禁"的，实际一直在跑，
     直到 2026-10-07 出事（见下）才发现，2026-10-08 改 `chmod -x` 才真正停。
2. **放错目录 = 静默永不运行**。darkman **不读** `~/.config/darkman/`。本机实测生效的是：
   - `~/.local/share/dark-mode.d/` 与 `~/.local/share/light-mode.d/`（legacy 格式，
     脚本无参数，按文件名排序执行）—— journal 原文 `Found legacy script path=…`；
   - （现代格式是 `~/.local/share/darkman/` 单脚本收 `$1` = dark|light，
     man page 只写这个；本机没用。**Fedora 侧若编译了更新版 darkman 而 legacy 不认了，
     就把钩子搬去现代路径**，判据都在下面的 journal 命令里。）
3. **验证只信 journal，别信文件**：

   ```bash
   journalctl --user -u darkman | grep -E "Found|Running script" | tail -20
   ```

   ⚠ 没发生真实明暗切换时，日志只有 `No transition necessary`，什么都不跑 ——
   别把"没日志"当成"配置对了"。

### 2026-10-07 事故链（「终端颜色变了」）

新开的 foot 是 gruvbox 色、早开的窗口还是 matugen 色（同屏两色）。顺着 mtime 摸出来：
auto-mode 17:35:21 日落切 matugen-dark → darkman 17:37:37 日落转移，
跑起 `10-term-theme.disabled`（当时带着 `.disabled` 后缀但**可执行**）→
`current_theme.ini` 被刷成 gruvbox；同一次还跑了 `20-gtk-theme.disabled`，
把 gtk-theme 设成 `Catppuccin-Mocha`（switch.sh 要的是 `adw-gtk3-dark`）。

### 当前四个钩子的状态（主力机，2026-10-08）

| 文件（`~/.local/share/{dark,light}-mode.d/`）| 执行位 | 干什么 |
|---|---|---|
| `10-term-theme.disabled` | ✗ 已停（chmod -x）| （旧）切 foot 主题 —— 事故主角 |
| `15-fcitx5-theme` | ✓ 在跑 | 只 `gsettings set color-scheme prefer-dark/light`（fcitx5 的 UseDarkTheme、foot 选段都读它）|
| `20-gtk-theme.disabled` | ✗ 已停 | （旧）切 gtk-theme —— 同事故 |
| `90-quickshell-ii` | ✓ 在跑 | `exit 0` 空桩 |

### 仓库里的两处留档（别搞混）

| 仓库路径 | 实际地位 |
|---|---|
| `configs/.local/share/{dark,light}-mode.d/` | **活的那套**，工作机要部署的就是它 |
| `configs/.config/darkman/` | config.yaml + `theme-sync.sh` + 两个钩子 —— 那两个钩子**从没跑过**（2026-09-23 放的，位置错了）。里面「静态主题就跳过 ii 配色重算」的护栏逻辑如果要复活，得先搬去正确的目录 |

两处都放了 README 说明，别当死文件删了也不知道为什么。

---

## 附：工作机残留清单（P0/P1 填写）

> 工作机装过 Hyprland 又放弃过（还有半年 GNOME 使用史），以下各项在 P0 摸底时逐个确认，
> 结果填进这张表，再决定 P1 的清理动作。

| 项 | 检查命令 | 结论 | 处理 |
|---|---|---|---|
| COPR 残留（hyprland 相关）| `dnf copr list` | （待填）| |
| `~/.config/hypr` 残留 | `ls ~/.config/hypr`（对照本仓库 diff）| （待填）| |
| 旧 Hyprland 包 | `rpm -qa \| grep -i hypr` | （待填）| |
| 显示器实况 | `hyprctl monitors` 或登录 GNOME 跑 `wlr-randr` | （待填）| → 生成 `machine/work/monitors.lua` |
| NVIDIA 驱动现状 | `nvidia-smi` / `rpm -qa \| grep nvidia` | （待填）| RPM Fusion akmod-nvidia |
| GDM 里的会话列表 | `ls /usr/share/wayland-sessions/` | （待填）| 保留 GNOME，追加 Hyprland |
| 旧 dotfiles / chezmoi 残留 | `ls ~/.dotfiles ~/.local/share/chezmoi` | （待填）| |
