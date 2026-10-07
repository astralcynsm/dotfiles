# 这套桌面怎么运作

> 改任何东西之前先读这份。它回答"**为什么是这样**"。
> 具体操作手册在别处：ii 补丁 = `LOCAL-PATCHES.md` + `docs/upstream-sync.md`；
> 主题 = `configs/.config/theme-switcher/README.md`；雷区 = `docs/known-issues.md`。

---

## 1. 会话总览

```
GDM（未改动，GNOME 会话是全程保留的退路）
 └─ Hyprland 会话（Wayland compositor，Lua 配置，0.56）
     ├─ hyprland.lua
     │    ├─ require("configs/Keybinds")        预置键位
     │    ├─ require("UserConfigs/*")            用户键位/装饰/动画/启动项/环境变量
     │    └─ require("machine")                  ★机器特定层（最后加载 = 优先级最高）
     ├─ hl.on("hyprland.start") → hl.exec_cmd("systemctl --user start hyprland-session.target")
     │    → quickshell-ii.service（bar / 左右栏 / overview / 锁屏 / Super 搜索）
     │    → ii-stats.service、rime_counter.service（数据采集 daemon）
     ├─ hypridle（idle 守护）+ hyprlock（锁屏）
     ├─ fcitx5 + rime（输入法，Super+Space 触发）
     └─ 主题链（第 4 节，最复杂的一条）
```

Hyprland 会话不在时，大部分东西（quickshell/主题/输入法）都不会自己起来 —— 这是设计，
它们全部挂在 `graphical-session.target` 上（见第 6 节）。

---

## 2. `~/.config` 目录地图

| 目录 | 一句话 | 需要上游同步? |
|---|---|---|
| `hypr/` | Hyprland 全部配置（Lua）| 否（自维护） |
| `quickshell/ii/` | ii 本体（QML，951 文件）| **是**，见 LOCAL-PATCHES.md |
| `illogical-impulse/` | ii 的用户数据（config.json / 外观 preset / 翻译）| 否 |
| `theme-switcher/` | 主题切换器（静态主题 + 壁纸 + 明暗）| 否 |
| `matugen/` | 配色生成（config.toml + 16 个模板）| 否 |
| `darkman/` | 系统明暗仲裁 + 钩子 | 否 |
| `fcitx5/` | 输入法配置 | 否 |
| `ghostty/`、`foot/` | 终端（工作机只用 ghostty）| 否 |
| `systemd/user/` | 用户单元（白名单导出）| 否 |
| `~/.local/bin/` | 自写脚本（第 7 节）| 否 |
| `~/.local/share/fcitx5/rime/` | rime 用户数据（userdb 是多年词频，**丢不起**）| 上游数据靠 plum 重装 |

---

## 3. Hyprland 配置结构

**入口**：`~/.config/hypr/hyprland.lua`，依次 require 各模块。全部是 Lua
（Hyprland 0.55 起弃用 hyprlang；0.56 起 `hyprctl dispatch` 只认 Lua 表达式，见 known-issues R7）。

**键位是三层**：

| 层 | 文件 | 条数 | 机器无关? |
|---|---|---|---|
| 预置 | `configs/Keybinds.lua` | 97 | ✅ 通用 |
| 用户 | `UserConfigs/UserKeybinds.lua` | 115（其中 17 条走 quickshell IPC） | ✅ 通用 |
| 笔记本 | `machine/primary/…/Laptops.lua`（经 machine.lua 加载） | 17 | ❌ work 剥离 |

主力机运行期实测：`hyprctl binds -j | jq length` = **203**。
work 上剥离 Laptops.lua 后预期 ≈ 186，以实测为准（差异要能解释，见 MIGRATION P3）。

**`machine.lua` 机制**：`hyprland.lua` **最后** require `machine`，所以机器特定配置
优先级最高。`machine.lua` 里再 require `monitors` / `workspaces`（以及笔记本机的
`Laptops` / `LaptopDisplay`）。换机器 = 替换 `machine.lua` 及其指向的文件。

⚠ 仓库里 `configs/.config/hypr/machine.lua` 当前是**主力机版本**（require 了笔记本
文件）。work 覆盖层必须自带自己的 `machine.lua`（只 require monitors/workspaces），
否则 require 到不存在的笔记本文件会**整个配置加载失败**。

**生成物 vs 源头**（改错地方等于没改）：

| 是生成物（勿手改） | 源头在哪 |
|---|---|
| `~/.config/hypr/colors.lua` | matugen 模板 `hyprland/colors.lua` |
| `~/.config/hypr/hyprlock/colors.conf` | matugen 模板 `hyprland/hyprlock-colors.conf` |
| `~/.local/state/quickshell/user/generated/*` | matugen 模板（colors.json 等） |
| `~/.config/foot/current_theme.ini`、`ghostty/active-theme` | 由 theme-switcher 从"主题库"里搬运 |

---

## 4. 主题链（三个系统叠在一起，各管一段）

| 系统 | 管什么 | 谁触发 |
|---|---|---|
| **matugen** | 从壁纸**生成**配色：16 个模板 → colors.json / colors.lua / gtk.css / foot / ghostty / fcitx5 / KDE / rofi / hyprlock | ii 的 `switchwall.sh` |
| **theme-switcher** | 静态主题（death-stranding / gruvbox-* / kanagawa-dark 四套固定配色）+ 把配色**投放**到各组件 + 让**运行中**的程序重载 | `Super+D` / ii 界面 / 命令行 |
| **darkman** | 系统级明暗的**仲裁者**（XDG portal 的 color-scheme 来源，浏览器/QQ 跟它变） | 自身定时（日出日落）或手动 |

### 4.1 换壁纸的数据流

所有换壁纸入口（`Super+W` rofi 网格 / `Ctrl+Alt+W` 随机 / `Super+Shift+W` 特效 /
定时器）最后都走 `theme-switcher/switch.sh --wallpaper`，它内部调 ii 的 `switchwall.sh`：

```
switchwall.sh <图片> --mode <dark|light>
  ├─ 写 ~/.config/illogical-impulse/config.json → QML Background.qml 重绘壁纸
  ├─ matugen 跑 16 个模板，产物见下
  └─ 往运行中的终端推 ANSI 转义序列
```

matugen 的 16 个模板（`matugen/config.toml`，完整注释在文件里）：

| 产物 | 用途 |
|---|---|
| `~/.local/state/quickshell/user/generated/colors.json` | **ii 界面全部配色的来源**（最关键的一个） |
| `…/generated/color.txt`、`wallpaper/path.txt` | ii 的次级数据 |
| `~/.config/hypr/colors.lua` | Hyprland 边框/背景 |
| `~/.config/hypr/hyprlock/colors.conf` | 锁屏 |
| `~/.config/foot/themes/matugen.ini` | foot（再由 switch.sh 搬成 current） |
| `~/.config/ghostty/themes/matugen-{dark,light}` | ghostty（**单模式文件，两份**；switch.sh 按当前明暗选一份搬成 active-theme） |
| `~/.config/gtk-3.0/gtk.css` + `~/.config/gtk-4.0/gtk.css` | GTK3/4（Qt 经 `QT_QPA_PLATFORMTHEME=gtk3` 走同一条路） |
| `~/.local/share/fcitx5/themes/matugen-{dark,light}/` | 输入法候选框（两套，fcitx5 自己按 color-scheme 选） |
| `~/.local/share/color-schemes/MaterialYou{Dark,Light}.colors` | KDE（Dolphin）—— 由 switch.sh 改写 kdeglobals 选明暗 |
| `~/.config/rofi/wallust/colors-rofi.rasi` | rofi |
| `~/.config/fuzzel/fuzzel_theme.ini` | fuzzel |

### 4.2 明暗（dark / light）的权威链

**三处记录，一处仲裁**：

| 位置 | 谁写 | 地位 |
|---|---|---|
| 主题文件（`THEME_MATUGEN_MODE` / `THEME_MODE`）| theme-switcher | **权威** |
| `gsettings color-scheme` / kdeglobals | `sync_system_mode()` 掰齐 | 派生 |
| darkman（portal 来源） | darkman 自己 | 系统侧；钩子会同步 GTK/foot/ii |

自动逻辑：`theme-auto-mode.timer`（每 5 分钟）→ `auto-mode.sh` 按**上海**日出日落
算目标模式 —— 但守两条规矩：**只碰 matugen 主题** + **手动优先**（`.last-manual`
时间戳由 `switch.sh` 的 `toggle_mode()` 落；三个手动入口共用那一处）。
详见 `configs/.config/theme-switcher/README.md` 的「自动明暗」一节。

### 4.3 foot 与 ghostty：同为终端，接法完全不同

| | foot | ghostty |
|---|---|---|
| theme 文件 | **一份含明暗两段**（`[colors-dark]`+`[colors-light]`）| 单模式，**必须两份文件** |
| 选明暗 | `initial-color-theme`（默认 dark！）+ 运行期 `SIGUSR1/2` | 由 switch.sh 按明暗**选一份搬**到 active-theme |
| 读 portal? | **不读**（实测：二进制里 0 处 portal） | 不依赖 |
| 运行中重载 | `touch` 主配置 + 发信号 | D-Bus `org.gtk.Actions.Activate reload-config`（`+reload-config` 子命令不存在） |

⚠ 两个共同坑：① 只改被 include 的文件不会触发热重载（foot 只监视主 `foot.ini`）；
② ghostty 的 theme 文件**不能写行尾注释**（整行被静默丢弃，退出码 0、无报错）。

---

## 5. ii / quickshell

**入口**：`qs -c ii`（systemd 单元 `quickshell-ii.service`）。版本钉死
`0.2.1 revision 7511545e`（quickshell-git，`dnf versionlock`）。

**结构**：bar（顶栏）+ sidebarLeft（左栏 5 页）+ sidebarRight（右栏）+ overview +
lock + Super 搜索。左栏页签栏**已满**（5 个占 406px / 可用 425px），加第六页前要重新设计。

**本地改动登记册**：`configs/.config/quickshell/ii/LOCAL-PATCHES.md`
（13 个新增文件 + 11 个改动文件；§1–§13 每节都有实测数据与验证方法）。
**上游同步会覆盖这些改动** —— 同步流程见 `docs/upstream-sync.md`。

**界面数据的来源**（排障时按这张表找上游）：

| 界面 | 数据 | 来源 |
|---|---|---|
| bar 的字数 widget | `/tmp/rime_status.json` | `rime_counter_rs`（`rime_counter.service`）|
| 左栏「字数」页 | `~/.local/share/ii-stats/` 的 CSV | `ii-stats-daemon`（`ii-stats.service`）|
| 左栏「监控」页 | `~/.local/share/ii-stats/` 的指标 JSON | 同上 |
| 左栏「音乐」页 + 右栏 tab | 在播 = MPRIS / 历史 = last.fm | `services/LastFm.qml`（apiKey 在 config.json，**导出时被擦除，工作机要重填**）|
| 左栏「维护」页 | 系统维护命令 | `Maintenance.qml`（**含 Arch 命令，工作机 P7.7 改 dnf**）|
| 左栏「翻译」页 | `translate-shell` | `Translator.qml`（语言列表已收窄为 13 项常用）|

---

## 6. systemd 用户单元

| 单元 | 作用 | 备注 |
|---|---|---|
| `quickshell-ii.service` | ii 主进程 | ★ 四个设置不能丢：`QSG_RENDER_LOOP=threaded`（帧率）、`PATH=%h/.local/bin:…`、`QT_IM_MODULE=fcitx`（**只给这个服务**）、`KillMode=process`（防 cgroup 连坐）+ `Restart=always` |
| `hyprland-session.target` | 会话 target | 由 `Startup_Apps.lua` 在导入环境变量后 start；`BindsTo=graphical-session.target` 防止它被 StopWhenUnneeded 停掉 |
| `ii-stats.service` / `rime_counter.service` | 数据 daemon | 同样 `PartOf=graphical-session.target` |
| `theme-auto-mode.{service,timer}` | 自动明暗 | 每 5 分钟轮询（抗挂起），见 §4.2 |
| `db-sync.service` | 双库同步 | （用户自写）|
| `rescrobbled.service` | last.fm scrobble | |
| `xdg-desktop-portal.service` | portal | |

`configs/.config/systemd/user/ENABLED.txt` 是主力机 enable 状态快照，供工作机参照。

---

## 7. 自写脚本（`configs/.local/bin/`）

| 脚本 | 作用 |
|---|---|
| `ii-stats-daemon` | 系统指标 + 打字明细采集（Python3 标准库），产出在 `~/.local/share/ii-stats/` |
| `vault-commit` | Obsidian 双库 → GitHub（`Super+Alt+G` 提交 / `Super+Alt+S` 速记）；路径在 `machine/<profile>/.config/vault-commit/vaults.json` |
| `rime_counter_rs` | rime 字数统计（Rust；**仓库只带源码**，工作机 `cargo build --release`）|
| `term-exec` | 向运行中的终端发命令（工作机要改终端名：`EXEC=foot` → ghostty）|
| `mkprompt` / `db-sync` / `plymouth-ii-theme` / `osu-wine` / `steam` | 各自的辅助脚本 |

---

## 8. 输入法链

**组成**：fcitx5 + rime（`rime_ice` 方案为主）+ 自拼候选框主题（matugen 双套 + 9-patch PNG 圆角）。

**环境变量分工**（这三条是硬约束，别"顺手"改）：

| 变量 | 放哪 | 为什么 |
|---|---|---|
| `XMODIFIERS` / `SDL_IM_MODULE` / `FC_LANG` | `~/.config/environment.d/90-fcitx.conf`（Fedora 惯例；主力机放 `/etc/environment`）| 全局、无害 |
| `QT_IM_MODULE` | **只给 `quickshell-ii.service`** | quickshell 是 Qt 又不走 text-input，没有它面板里打不出中文 |
| `GTK_IM_MODULE` | **哪都不放** | Wayland 下设它会绕过 text-input 协议，fcitx5 官方不建议 |

**字数统计链**：`rime_counter.service`（rime_counter_rs 常驻）→ `/tmp/rime_status.json`
→ bar 的 WordCount widget。

---

## 9. 机器特定层（两层覆盖模型）

```
configs/                  通用层，镜像 $HOME 结构
machine/<profile>/        覆盖层，同结构，部署时后应用、覆盖前者
```

**什么算机器特定**（必须进 `machine/<profile>/`）：
显示器配置（`monitors.lua` / `workspaces.lua` / `Monitor_Profiles/`）、笔记本特有
（`Laptops.lua` / `LaptopDisplay.lua`）、挂载路径（`vault-commit/vaults.json`）、
**`machine.lua`（决定 require 哪些机器特定文件）**。

**部署**：`scripts/apply-profile.sh <profile>` = 两条 rsync（先 configs 后 machine），
**从不使用 `--delete`**（见 known-issues R3）。

---

## 10. 已验证版本（2026-10-08，主力机）

| 组件 | 版本 |
|---|---|
| Hyprland | 0.56.2（commit `efb5099`）|
| Quickshell | 0.2.1 revision `7511545ee20664e3b8b8d3322c0ffe7567c56f7a` |
| matugen | 3.1.0（模板语法按此版本写）|
| foot | 1.28.0 |
| 当前主题 | matugen（另有 death-stranding / gruvbox-dark / gruvbox-light / kanagawa-dark）|

Fedora 侧的对应版本与获取途径在 `docs/fedora-notes.md` + `inventory/mapping.toml`。
