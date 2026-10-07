# 主题切换器

一次切换一整套配套：**foot 终端 · Hyprland 边框/装饰 · hyprlock 锁屏 · GTK 应用**。

## 用法

```bash
~/.config/theme-switcher/switch.sh            # 帮助
~/.config/theme-switcher/switch.sh --list     # 列出主题（* 标记当前）
~/.config/theme-switcher/switch.sh --current  # 当前主题名
~/.config/theme-switcher/switch.sh --type     # 当前主题类型（matugen | static）
~/.config/theme-switcher/switch.sh --next     # 切到下一个
~/.config/theme-switcher/switch.sh --reload   # 重新应用当前主题
~/.config/theme-switcher/switch.sh gruvbox-dark
~/.config/theme-switcher/switch.sh matugen /path/to/wallpaper.jpg

~/.config/theme-switcher/switch.sh --wallpaper ~/Pictures/wallpapers/x.jpg
~/.config/theme-switcher/switch.sh --toggle-mode        # 深色 ↔ 浅色
~/.config/theme-switcher/switch.sh --set-mode light

~/.config/theme-switcher/menu.sh              # rofi 菜单
```

`--wallpaper` 是**所有换壁纸入口的公共后端**：
`Super+W`（rofi 缩略图网格）、`Ctrl+Alt+W`（随机）、
`Super+Shift+W`（特效菜单）、`WallpaperAutoChange.sh`（定时）
最后都走到这里。

## 两类主题

| 类型 | 配色来源 | 壁纸的角色 |
|---|---|---|
| `matugen` | 从壁纸自动生成 | **输入** —— 换壁纸后 `--reload` 整套跟着变 |
| `static` | 预设里写死（gruvbox / kanagawa …） | 无关，但切主题时会把当前壁纸同步给锁屏 |

**壁纸由你自己选**，不写死在主题预设里。换壁纸统一走 `--wallpaper`：

```bash
switch.sh --wallpaper ~/Pictures/wallpapers/x.jpg
```

它内部调 ii 的 `switchwall.sh`（设置壁纸、写 `config.json`、跑 matugen、
往运行中的终端推转义序列），然后按**当前主题类型**收尾：

- 当前是 matugen 主题 → 一切由 ii 处理，再同步一次 `foot/current_theme.ini`；
- 当前是静态主题 → 把被 matugen 覆盖掉的配色用静态主题再盖回来。

## 目录结构

```
theme-switcher/
├── switch.sh              核心脚本
├── menu.sh                rofi 菜单入口
├── current                当前主题名（状态文件）
├── themes/<名字>.theme     主题定义（声明类型、描述、素材目录）
└── assets/<素材目录>/       各组件素材文件
    ├── hypr.colors.lua
    ├── hyprlock.colors.conf
    ├── foot.ini
    └── gtk.css
```

`.theme` 文件支持这些变量：

```sh
THEME_DESC="显示在菜单/通知里的描述"
THEME_TYPE="matugen"          # 或 static
THEME_ASSETS="素材目录名"       # 默认与主题名相同
THEME_MATUGEN_MODE="dark"     # matugen 专用：dark | light
THEME_MODE="dark"             # static 专用：dark | light（默认 dark）
```

`THEME_MATUGEN_MODE` / `THEME_MODE` 这两项除了决定配色，
还决定 **GTK 应用和系统走浅色还是深色**（详见下面「明暗模式」）。

## 加一个新主题（静态配色）

1. `themes/<名字>.theme`：

   ```sh
   THEME_DESC="Nord（固定配色）"
   THEME_TYPE="static"
   THEME_ASSETS="nord"
   ```

2. 在 `assets/nord/` 放 4 个文件，**文件名必须与 `switch.sh` 里的 `COMPONENT_MAP` 一致**：
   `hypr.colors.lua`、`hyprlock.colors.conf`、`foot.ini`、`gtk.css`

3. `switch.sh --list` 就会自动列出它，无需改脚本。

某套配色缺哪个组件就**不放进 `assets/`**——脚本会打印"本主题未提供，跳过"并继续。

> 注意"跳过"的含义是**不动该组件的现有文件**，而不是把它清空。
> 也就是说：主题 A 提供了 `kitty.conf`、主题 B 没提供，
> 那么从 A 切到 B 之后 kitty 会**停留在 A 配色**。
> 这是刻意的——没有该终端的配色就不去破坏它。
> 想让某组件每次都被覆盖，就保证每套主题都提供它。

## 加一个新组件 / 换终端

**这是唯一需要改脚本的地方**（`switch.sh` 顶部的 `COMPONENT_MAP`）：

```bash
COMPONENT_MAP="
hypr.colors.lua|$HOME/.config/hypr/colors.lua
hyprlock.colors.conf|$HOME/.config/hypr/hyprlock/colors.conf
foot.ini|$HOME/.config/foot/current_theme.ini
gtk.css|$HOME/.config/gtk-3.0/gtk.css
"
```

格式是 `素材文件名|目标绝对路径`，一行一个组件。**加一行即生效**，所有已写好的 `.theme` 和 `assets/` 都不用动。

### 例：从 foot 换到 kitty

假定你装了 kitty，且 `~/.config/kitty/kitty.conf` 里有 `include ~/.config/kitty/current_theme.conf`：

1. 在 `COMPONENT_MAP` 追加一行：

   ```
   kitty.conf|$HOME/.config/kitty/current_theme.conf
   ```

2. 每个主题的 `assets/<主题>/` 下加一个 `kitty.conf`（kitty 颜色语法）：

   ```
   background #282828
   foreground #ebdbb2
   color0     #282828
   color1     #cc241d
   ...
   ```

3. 想同时保留 foot 就**两行都留着**，各主题只提供自己想支持的终端即可。

> 之所以用"映射表 + 逐项 `cp`"而不是写死分支，就是为了这一步零逻辑改动。
> foot 是唯一的例外——因为 matugen 直接生成到 foot 的主题库，
> 需要在 `sync_foot_matugen()` 里再同步一次成"当前"（见脚本内注释）。

### ⚠ 换完 foot 配色还要 touch 一下主配置

**症状**：换主题/换壁纸后，边框、bar、桌面时钟全变了，**只有开着的 foot 窗口纹丝不动**，
新开的窗口才是新配色。

**根因**：foot 的配置热重载监视的是**主配置** `~/.config/foot/foot.ini`，
而配色是通过 `include=~/.config/foot/current_theme.ini` 引入的。
**只改被 include 的那份文件，foot 收不到通知，不会重读。**

实测（同一个 foot 窗口，换 matugen 主题后）：

```
touch 前  窗口背景 #221818（暖红棕，上一张壁纸的颜色）
touch 后  窗口背景 #323339（冷灰，跟着新壁纸走了）
```

色相整个翻转，证明重载确实生效。

**做法**：`reload_foot <mode>`（`switch.sh` 内）—— 先 `touch ~/.config/foot/foot.ini`，
**不重启 foot**（用户窗口里可能跑着长任务），再按 `<mode>` 给运行中的 foot 发信号。
两条路径都挂了：`sync_foot_matugen()`（matugen 主题）和 `apply_static()`
（static 主题，用 `foot_updated` 标志位判断 foot 那一项是否真的被更新）。

**foot 的 dark / light 两段**：matugen 生成的 `current_theme.ini` 里同时含
`[colors-dark]` 和 `[colors-light]` —— 这**不是重复内容**，是 foot 的正常语法。

⚠ **但 foot 不会自己挑用哪一段**（2026-10-08 更正，此前这里写的是错的）：
foot **不读 XDG Portal** —— 实测 foot 1.28.0 的二进制里 `portal` 出现 0 次、
也没链任何 portal 客户端库，`foot.ini(5)` 与 `foot(1)` 里同样 0 次提及。
它只看 `initial-color-theme`（**默认 `dark`**），运行期则靠信号切换：
`SIGUSR1` 切 `[colors-dark]`、`SIGUSR2` 切 `[colors-light]`（`foot(1)` 明载）。

所以这条链现在这样接：

| 谁 | 做什么 |
|---|---|
| 模板 `matugen/templates/foot/foot_theme.ini` | 顶部输出 `initial-color-theme={{mode}}`（`{{mode}}` 是 matugen 3.1.0 的合法变量，实测 dark/light 各回各的） |
| 静态素材 `assets/*/foot.ini` | 顶部钉 `initial-color-theme=dark`（四套的调色板都写在 `[colors-dark]` 里） |
| `switch.sh` 的 `reload_foot <mode>` | touch 主配置之外，再按 `<mode>` 发 `SIGUSR1`/`SIGUSR2`，让**已经在跑**的窗口也换段 |

⚠ `initial-color-theme` 必须写在**任何 `[section]` 之前**（即 `[main]` 段）。
放错段 foot 会直接拒绝解析：`[colors-dark].initial-color-theme: light: not valid option`
（实测报错原文）—— 好在是响亮失败，不会静默。

## 明暗模式（dark / light）

明暗有两处记录，**本脚本以主题文件为准**：

| 记录处 | 谁在写 |
|---|---|
| `themes/matugen.theme` 的 `THEME_MATUGEN_MODE`、主题的 `THEME_MODE` | 本脚本 |
| `gsettings` 的 `color-scheme` / `gtk-theme` | ii 自己的浅色深色切换，也会写这里 |

这两处会打架：ii 的切换把 `gsettings` 弄成 `prefer-light` 之后，
`switchwall.sh` 若不带 `--mode` 就会去读 `gsettings`，
于是**换一张壁纸就能把整个桌面偷偷刷成浅色**（边框/GTK/ii 界面全变，终端还是旧的）。

所以本脚本做两件事：

1. `sync_gtk_mode()` —— 每次套主题都把 `gsettings` 掰回主题该有的明暗；
2. `change_wallpaper()` —— 调 `switchwall.sh` 时**显式带上 `--mode`**，不信 `gsettings`。

`--toggle-mode` 走的是 ii 原生机制（`switchwall.sh --mode X --noswitch`，
保留壁纸只重算配色），同时会更新 `THEME_MATUGEN_MODE` 和 `gsettings`。
注意它切的是 **matugen 主题的明暗**；当前若是静态主题，桌面配色不变
（静态主题有自己的 `THEME_MODE`）。

## 自动明暗（日出日落）与手动优先

`theme-auto-mode.timer`（systemd user timer）每 5 分钟跑一次 `auto-mode.sh`，
按**上海**日出日落算出此刻该 dark 还是 light，与当前不一致才切
（所以一天里真正动 `switch.sh` 的只有日出 / 日落两次）。

它守两条不插手的规矩：

1. **只碰 matugen 主题** —— 静态主题（gruvbox / kanagawa …）是你明确挑的
   固定配色，时间逻辑不碰；
2. **手动优先** —— 你手动切过之后，本个「半天周期」内不再自动覆盖，
   到下一个转折点（日出 / 日落）自动逻辑重新接管。

「手动优先」靠一个时间戳文件：`.last-manual`（内容 = epoch 秒）。
`auto-mode.sh` 把它和周期起点比较，周期内手动动过就跳过。

⚠ **这个记录由 `switch.sh` 的 `toggle_mode()` 落，不是各入口自己落**
（2026-10-08 修正）。之前只有 `toggle-mode.sh`（SUPER+D）在记，
而 ii 界面的 `DarkLight.sh` 直接调 `switch.sh --toggle-mode`、
手敲命令行也一样 —— 这两条路切完不留痕，自动逻辑照旧会覆盖掉你的选择。

```
SUPER+D ─┐
ii 界面 ─┼─→ switch.sh --toggle-mode → toggle_mode() → 落 .last-manual
命令行  ─┘
```

`--set-mode` 是 `auto-mode.sh` 专用的纯 setter，**刻意不落记录** ——
落了等于把自动切换误标成手动，自动逻辑会把自己锁死。

想看自动逻辑此刻的判词（只读，不做任何改动）：

```bash
~/.config/theme-switcher/auto-mode.sh --status
# theme-auto-mode: 日出 05:52 / 日落 17:32 ｜ 现在 01:38(夜间) ｜ 目标 dark ｜ 当前 dark
```

## 与 matugen 的关系

`~/.config/matugen/config.toml` 里的模板会生成到这些位置：

| 目标 | 路径 |
|---|---|
| Hyprland 边框 | `~/.config/hypr/colors.lua` |
| hyprlock | `~/.config/hypr/hyprlock/colors.conf` |
| foot | `~/.config/foot/themes/matugen.ini`（再由切换器同步成 current） |
| GTK | `~/.config/gtk-3.0/gtk.css` |

静态主题的素材文件**故意导出与 matugen 版完全相同的变量名**
（`themePrimary` / `themeOutline` / `themeSurface` / `themeOnSurface` /
`$color11` / `$color12` / `$color13` / 同一批 `@define-color` 槽位），
所以引用方（`UserConfigs/UserDecorations.lua`、`hyprlock.conf`、GTK 应用）
**不需要知道当前是哪类主题**。

> ⚠ matugen 的 gtk4 模板已在 `config.toml` 里禁用。
> 原因：`~/.config/gtk-4.0/gtk.css` 是指向 `~/.themes/` 的**符号链接**，
> matugen 写文件会跟随链接毁掉主题源文件。详见该文件的注释。

## Qt 应用是怎么跟上的

**不用做额外的事 —— Qt 已经跟着本切换器变颜色了**，走的是 GTK 这条路：

```
QT_QPA_PLATFORMTHEME=gtk3   (~/.config/hypr/UserConfigs/ENVariables.lua:28)
        ↓
libqgtk3.so  (Qt5/Qt6 的 platformthemes 插件，已装)
        ↓ 只查这 11 个 legacy GTK3 颜色名
theme_bg_color / theme_fg_color / theme_base_color / theme_text_color /
theme_selected_bg_color / theme_selected_fg_color /
theme_unfocused_{bg,fg,text,selected_bg,selected_fg}_color
        ↓ adw-gtk3 把它们全部别名到 libadwaita 名字
        ↓   （/usr/share/themes/adw-gtk3-dark/gtk-3.0/gtk.css 里的 @define-color）
```

| Qt 查的名字 | adw-gtk3 的定义 | 本切换器覆盖的名字 |
|---|---|---|
| `theme_bg_color` | `@window_bg_color` | ✅ |
| `theme_fg_color` | `@window_fg_color` | ✅ |
| `theme_base_color` | `@view_bg_color` | ✅ |
| `theme_text_color` | `@view_fg_color` | ✅ |
| `theme_selected_bg_color` | `@accent_bg_color` | ✅ |
| `theme_selected_fg_color` | `@accent_fg_color` | ✅ |
| `theme_unfocused_*` | `mix(...)` / 直接引用上面几个 | ✅ |

也就是说 GTK 与 Qt 走的是**同一份 `~/.config/gtk-3.0/gtk.css`**，
天然同色，不需要第二套配置。

**代价 / 边界**：

- 只跟**颜色**。控件外观（圆角、阴影、动画、滚动条形状）是 `adw-gtk3` 的，
  主题切换器控制不到。
- Qt 应用**只在启动时读一次**，换完主题要重启应用才看得到。
- 明暗只有 `adw-gtk3` / `adw-gtk3-dark` 两档（由 `sync_gtk_mode()` 切）。
  想换成 Flat-Remix 之类，改 `sync_gtk_mode()` 里那两行字符串。

### 那条被关掉的 KDE 钩子

ii 的 `switchwall.sh` 里另有一条 Qt 配色钩子
（`post_process()` → `handle_kde_material_you_colors &`），
由 `config.json` 的 `appearance.wallpaperTheming.enableQtApps` 控制。
**它在本机完全跑不通**：venv 里装了 `kde-material-you-colors`，
但它最后要调 `plasma-apply-colorscheme`，本机没 Plasma，
于是每次换壁纸抛一个完整 Python traceback（外加 `stty` 报错和调试日志）。
它崩溃的位置很早（`apply_themes.py:45`），后面的 Kvantum / konsole / 标题栏
全部不会执行，`~/.config` 下没有任何产出。

既然颜色已经由上面的 GTK 通路覆盖，这条又跑不通，就关掉了：

```bash
jq '.appearance.wallpaperTheming.enableQtApps = false' \
   ~/.config/illogical-impulse/config.json > /tmp/c && mv /tmp/c ~/.config/illogical-impulse/config.json
```

> 顺带一提：`~/.config/qt5ct/` 与 `~/.config/qt6ct/` 里虽然配了
> `Catppuccin-Mocha` + `style=kvantum`，但 `QT_QPA_PLATFORMTHEME=gtk3`
> 意味着**这两个配置文件根本不会被读取**，目前是死配置。
> `DarkLight.sh` 里切换它们的逻辑同理不生效。
