# 本地补丁总记录（ii 上游代码）

这里记的是**对 ii 上游文件的本地修改**。
从上游重新同步（rsync / git pull + 复制 dots）会**覆盖**这些改动，届时按本文重新施加。

> `scripts/colors/` 下有另一份专门的记录（matugen ≥3 兼容等），见
> [`scripts/colors/LOCAL-PATCHES.md`](scripts/colors/LOCAL-PATCHES.md)。

**同步上游时要注意的**：

| 文件 | 状态 | 上游有同名文件吗 |
|---|---|---|
| `services/WordCount.qml` | 新增 | 没有 → 只做覆盖式 rsync 的话会留下 |
| `modules/ii/bar/WordCountWidget.qml` | 新增 | 没有 → 同上 |
| `modules/ii/bar/WordCountPopup.qml` | 新增 | 没有 → 同上 |
| `services/TypingStats.qml` | 新增 | 没有 → 同上 |
| `modules/ii/sidebarLeft/TypingStatsPage.qml` | 新增 | 没有 → 同上 |
| `services/SystemMetrics.qml` | 新增 | 没有 → 同上 |
| `modules/ii/sidebarLeft/SystemMonitorPage.qml` | 新增 | 没有 → 同上 |
| `services/LastFm.qml` | 新增 | 没有 → 同上 |
| `modules/ii/sidebarLeft/MusicPage.qml` | 新增 | 没有 → 同上 |
| `modules/ii/sidebarRight/musicstats/MusicStatsWidget.qml` | 新增 | 没有 → 同上 |
| `services/Maintenance.qml` | 新增 | 没有 → 同上 |
| `modules/ii/sidebarLeft/MaintenancePage.qml` | 新增 | 没有 → 同上 |
| `modules/common/Config.qml` | 改过 | 有 → **会被覆盖** |
| `modules/common/widgets/SelectionDialog.qml` | 改过 | 有 → **会被覆盖** |
| `modules/ii/bar/BarContent.qml` | 改过 | 有 → **会被覆盖** |
| `modules/ii/bar/Workspaces.qml` | 改过 | 有 → **会被覆盖** |
| `modules/ii/bar/LeftSidebarButton.qml` | 改过 | 有 → **会被覆盖** |
| `modules/ii/sidebarLeft/Translator.qml` | 改过 | 有 → **会被覆盖** |
| `modules/ii/sidebarLeft/SidebarLeftContent.qml` | 改过 | 有 → **会被覆盖** |
| `modules/settings/BarConfig.qml` | 改过 | 有 → **会被覆盖** |
| `modules/ii/sidebarRight/BottomWidgetGroup.qml` | 改过 | 有 → **会被覆盖** |
| `modules/settings/ServicesConfig.qml` | 改过 | 有 → **会被覆盖** |

⚠ 如果 rsync 带了 `--delete`，上面那些新增文件也会被删掉。

另有几个文件在 ii 配置目录**之外**，不受上游同步影响（细节见 §6）：

| 文件 | 作用 |
|---|---|
| `~/.local/bin/ii-stats-daemon` | 系统指标 + 打字明细采集（Python3，仅标准库） |
| `~/.config/systemd/user/ii-stats.service` | 上面那个 daemon 的 unit，跟 `rime_counter.service` 同一套写法 |
| `~/.local/share/ii-stats/*.json` | daemon 的产出，QML 只读这些 |
| `~/.config/systemd/user/quickshell-ii.service` | quickshell 的守护 unit（`Restart=always`，细节见 §8） |

---

## 1. Rime 输入法字数统计接入 bar

**为什么是补丁而不是上游功能**

上游 ii 没有这个组件。数据来自用户自写的 `rime_counter_rs`，
它是个常驻 daemon，用 inotify 盯着 fcitx5 的词库，
把结果写成 `/tmp/rime_status.json`（waybar 的自定义模块协议）：

```json
{ "text": "2074 字", "tooltip": "<span weight='bold' color='#a6e3a1'>Today:</span> …",
  "class": "active", "alt": "ime" }
```

**新增的三个文件**

- `services/WordCount.qml` —— 单例。`FileView` + `watchChanges`（inotify）
  读那个 JSON，把 tooltip 从 Pango 转成 Qt 富文本。
- `modules/ii/bar/WordCountWidget.qml` —— bar 上的组件，图标 + `WordCount.text`，
  MouseArea 上挂悬浮窗。
- `modules/ii/bar/WordCountPopup.qml` —— 悬浮窗本体，`StyledPopup` +
  一个 `StyledText { textFormat: Text.RichText }`。

**改动的文件**

1. `modules/common/Config.qml` —— 在 `bar` 对象里、`tooltips` 之后加：

   ```qml
   property JsonObject wordCount: JsonObject {
       property bool enable: true
       property string statusFile: "/tmp/rime_status.json" // 由 rime_counter_rs 写出
   }
   ```

   （`config.json` 里也可以覆盖这两项。默认值只是兜底。）

2. `modules/ii/bar/BarContent.qml` —— 在**左侧** `leftSectionRowLayout` 里、
   `ActiveWindow` 之后加：

   ```qml
   WordCountWidget {
       Layout.rightMargin: Appearance.rounding.screenRounding
       Layout.alignment: Qt.AlignVCenter
       visible: root.useShortenedForm === 0
   }
   ```

   同一处还要把 `ActiveWindow` 的 `Layout.rightMargin` 从
   `Appearance.rounding.screenRounding` 改成 `4`。

**四个非显然的坑（都已实测确认，改代码时别踩回去）**

1. **放在右侧不行。** 右侧 `rightSectionRowLayout` 的可用宽度已被 `SysTray`
   的托盘图标吃光，RowLayout 会把这个组件压到接近 0 宽，
   文字直接溢出去盖住电池指示器。左侧 `ActiveWindow` 是 `fillWidth`，会自己让位。

2. **Qt 的 `<span style="…">` 只认 `font-weight` / `font-family`，不认 `color`。**
   实测（同一份文本逐条对比）：

   | 写法 | 结果 |
   |---|---|
   | `<span style="color:#a6e3a1">` | 灰的，**不生效** |
   | `<span style="font-weight:bold">` | 粗体，生效 |
   | `<span style="font-weight:bold;color:#a6e3a1">` | 只有粗体，**颜色丢** |
   | `<font color="#a6e3a1">` | 绿，生效 |
   | `<b>` | 粗，生效 |

   所以 `pangoToQt()` 把 Pango 的 `weight`+`color` 组合展开成
   `<b><font color="…">…</font></b>`。

3. **悬浮窗用 `StyledPopup`——就是 bar 上时钟 / 资源 / 电池那几个用的东西。**
   三段弯路都试过，最后这个是唯一又简洁又不会崩的：

   | 方案 | 结果 |
   |---|---|
   | `StyledToolTip`（= `QtQuick.Controls.ToolTip`） | 渲染在 bar 那个 40px 高的图层窗口**内部**，内容实测 273x220 塞不下 → "飞出屏幕外"；而且它参与命中测试，鼠标一压上去 `containsMouse` 翻假 → 隐藏 → 再弹出，每帧来回切 = "无限刷新" |
   | `PopupToolTip`（Quickshell `PopupWindow` + `PopupAnchor`） | 渲染没问题，但**会把 bar 崩掉**，见下面那条 |
   | `StyledPopup`（`LazyLoader` + `PanelWindow`） | ✅ 用的是 layer-shell 表面，**根本不走 PopupAnchor 那条路**，没有崩溃面 |

   写法照抄 `Resources.qml:50`：`MouseArea { hoverEnabled: …; XxxPopup { hoverTarget: mouseArea } }`，
   hover 判定由 `StyledPopup.active: hoverTarget && hoverTarget.containsMouse` 自己管。
   （`clickToShow = true` 时 `hoverEnabled` 为 false，就变成点击才弹，和其它几个一致。）

4. **⚠ 别用 Quickshell 的 `PopupToolTip`——它会把整个 bar 崩掉。**
   Quickshell 0.2.1 的 `PopupAnchor` 有雷：PopupWindow 如果在配置**加载期间**
   被创建，它会在 `ProxyWindowBase::completeWindow()` 里、锚点 item 正在 reparent
   的时候去读 `item->window()`，**段错误**（`popupanchor.cpp:112`），
   整个 bar 一起没。判据不是"有没有 hover"，而是"**加载那一刻可见条件是不是已经为真**"：

   ```
   # 实测（光标用 ydotool 真实停在组件上再触发热重载）
   parent.hovered / containsMouse  →  单次重载侥幸活，连打 10 次必崩
   硬编码 true                     →  一启动就崩（连 bar 都起不来）
   StyledPopup                     →  连打 10 次 + 光标压着启动，都不崩
   ```

   顺带：`bar` 上的 `SysTrayItem`（`containsMouse`）和 `ScrollHint`（靠 `parent.hovered`）
   用的都是 `PopupToolTip`，也就是说**它们同样带着这个雷**，
   只是要"正好在 reload 时鼠标压在托盘图标上"才会踩到。别去抄它俩。

**tooltip 行数不再截断**

早先用 `StyledToolTip` 时 tooltip 渲染在 bar 窗口里、只容得下 3 行，
所以 `pangoToQt()` 只保留 Today / Month / 柱状图。现在走独立面板，
12 行（含 "Last 7 days:" 的 7 天明细）完整显示，那段截断已删掉。

**数据源用 `FileView` 而不是轮询**

`services/WordCount.qml` 用 `FileView { watchChanges: true }`，
daemon 一写文件 bar 立刻更新。配 `printErrors: false` —— daemon 没跑时
文件不存在是正常状态，否则每次 reload 都往日志里写一条
`Read of … failed: File does not exist.`。

实测过的行为（`FileView` 会在父目录上重新建立监视）：

| 情况 | 结果 |
|---|---|
| 文件不存在 | `loadFailed`，`text()` 为空（不采信，保留上次的值） |
| 文件被创建 / 改写 | `fileChanged` → `reload()` → `loaded` |
| 文件被删掉 | `loadFailed`，`text()` 清空 |
| 文件被重建 | `fileChanged` → `loaded`，自动恢复 |

另有 `intervalSeconds` 这个配置项曾是轮询周期，已随轮询一起去掉。

**依赖**

daemon 必须活着。启动方式在 `~/.config/hypr/UserConfigs/Startup_Apps.lua:61`：

```lua
hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/rime_counter_rs")
```

**daemon 现在由 systemd 托管**（不再用 `Startup_Apps.lua` 裸跑了）：

- `~/.config/systemd/user/rime_counter.service` —— `ExecStart=%h/.local/bin/rime_counter_rs`，
  `Restart=on-failure`，`PartOf=graphical-session.target`，enabled。
- `~/.config/systemd/user/hyprland-session.target` —— **新建**，就两行：
  ```ini
  BindsTo=graphical-session.target
  After=graphical-session.target
  ```
  `BindsTo` 一举两得：既能把 `RefuseManualStart=yes` 的 `graphical-session.target`
  拉起来，又算作"有活动单元依赖它"，让它不会被自身的 `StopWhenUnneeded=yes` 立刻停掉。
- `Startup_Apps.lua` 末尾那行从 `start graphical-session.target` 改成
  `start hyprland-session.target`（原来那行**一直是空转**，见下），
  并删掉了裸跑 `rime_counter_rs` 的那行。

⚠ **原来 `systemctl --user start graphical-session.target` 是永远失败的** ——
那个单元是 `RefuseManualStart=yes` + `StopWhenUnneeded=yes`，只能被依赖拉起。
所以在这次改动之前，**任何 `WantedBy=graphical-session.target` 的单元在这个会话里
都从来不会启动**。副作用是 `solaar.service`（它也挂着这个 target，且一直是 enabled）
现在才第一次真正跑起来。

**踩过的坑：两个实例会清空每日历史。** 起 systemd 实例时旧的裸跑实例还活着，
两个 daemon 同时盯着同一批文件写，之后 `words_count_history.json` 的 `per_day` 变成 `{}`
（每日明细清零，bar 上变成 "0 字"）。教训：**切换启动方式时先把旧的杀掉**。
恢复方法见下。

**`per_day` 丢了怎么重建**（`words_input.csv` 是真正的数据源，不会丢）：
每行是 `"时间戳","YYYY-MM-DD HH:MM:SS","schema","拼音","文本","字数"`，
按第 2 列取日期、第 6 列求和即可。**实测重算结果与 tooltip 原本显示的数值逐个吻合**：

```bash
python3 -c "
import csv,collections
per=collections.Counter()
for r in csv.reader(open('/home/cynsm/.local/share/fcitx5/rime/py_wordscounter/words_input.csv',newline='',encoding='utf-8',errors='replace')):
    if len(r)>=6:
        try: per[r[1][:10]]+=int(r[5].strip())
        except: pass
print(dict(sorted(per.items())[-8:]))"
```
然后把结果写进 `words_count_history.json` 的 `per_day`（`last_offsets` 保留原值）
再 `systemctl --user restart rime_counter.service`。daemon 启动时会**读** `per_day`
（所以能恢复），但**不会**自己重扫 CSV（它启动时直接把 `last_offsets` 设成当前文件大小，
把已有内容全部跳过）—— 所以历史只能靠外部重建。

**验证方法**

```bash
pgrep -x rime_counter_rs                      # daemon 在跑吗（应该只有 1 个）
jq -r .text /tmp/rime_status.json             # 看得到今天字数吗
# bar 上应显示 "✎ NNNN 字"，hover 出完整面板
```

---

## 2. bar 完整形式的左右模块宽度按屏宽缩放（`BarContent.qml`）

**症状**

副屏 eDP-1（2560x1440 scale=1.6 → 逻辑 1600 宽）上，状态栏**右侧那组图标
挤成一团**：键盘布局 / 通知 / 网络 / 蓝牙指示的 `RippleButton` 和 `SysTray`
的托盘图标互相压在对方身上。

**根因**

`useShortenedForm` 的阈值是 1200，1600 > 1200 → 走"完整形式"，
而完整形式每侧固定 `barCenterSideModuleWidth = 360`：

```
中间段 = 360 + 工作区(10 格) + 360 ≈ 996，居中后跨度 302..1298
右侧可用 = 1600 - 1298 = 302
右侧需要 = RippleButton(约 110~140) + SysTray(约 150~180) ≈ 320
```

320 > 302 → RowLayout 把 `SysTray` 压得比内容还窄，里面的图标就叠了。

**补丁内容**

`centerSideModuleWidth` 改成按屏宽缩放：

```qml
readonly property int centerSideModuleWidth: {
    const base = (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth;
    const screenWidth = screen?.width ?? 1920;
    const maxByScreen = Math.floor((screenWidth * 0.55 - 276) / 2);
    return Math.max(180, Math.min(base, maxByScreen));
}
```

中间段最多占屏宽的 55%，剩下的留给两侧：

| 屏 | 上限 | 结果 |
|---|---|---|
| 1920（HDMI-A-1，主屏） | 390 | `min(360, 390)` = 360 → **主屏完全不变** |
| 1600（eDP-1，副屏） | 302 | 360 → 302，两侧各多出 58px |

（276 是中间段里工作区那一坨的宽度：`shown(10) × workspaceButtonWidth(26)`
+ `BarGroup` padding 4×2 + 两侧 Row spacing 4×2。改 `workspaces.shown`
这个数会跟着变，偏一点无所谓，它只是分配比例。）

**另一条路（没走）**：把 `barShortenScreenWidthThreshold` 从 1200 调到
1700，让副屏走 `useShortenedForm = 1`。**不行**——`useShortenedForm === 0`
才会显示 `SysTray` / `ActiveWindow` / `UtilButtons`
（`BarContent.qml` 里逐项 `visible:` 判断），副屏会直接丢掉托盘和窗口标题。

**验证方法**

```bash
grim -o eDP-1 /tmp/bar.png && magick /tmp/bar.png -crop 1000x64+1560+0 +repage -resize 180% /tmp/right.png
# 右侧那组图标之间应有明显间隙，不再互相覆盖
```

---

## 3. 工作区 app 图标尺寸（`Workspaces.qml`）

**症状**

一排有窗口的工作区看起来是一圈**等大的圆**，分不出哪个是当前工作区。

**根因**

上游：`workspaceIconSize: workspaceButtonWidth * 0.69` → 26 × 0.69 ≈ 18px。
但活动工作区的胶囊只有 `workspaceButtonWidth - 2 * activeWorkspaceMargin`
= 22px，图标 18px 就占了它的 **82%**（实测：eDP-1 上图标 29 device px、
胶囊 35 device px，比例吻合）。

**补丁内容**

```qml
property real workspaceIconSize: workspaceButtonWidth * 0.55        // 上游 0.69
property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.44 // 上游 0.55
```

26 × 0.55 = 14.3 → `roundToEven` → **14px**，占胶囊的 64%，层次分得开。
`Shrinked` 同步按同样比例缩（0.55/0.69 ≈ 0.8 → 0.44/0.55），
这是 super 键按住时用的。

**验证方法**

```bash
# 实测：有窗口的工作区里，图标宽度应从 18 logical px 变成 14
grim -o eDP-1 /tmp/bar.png   # scale=1.6，所以 14 logical = 22.4 device
```

---

## 4. bar 左上角图标可定制（preset + 任意 nerd font 字形）

**为什么是补丁**

上游 `bar.topLeftIcon` 只能填 `assets/icons/` 里的图片名（或 `"distro"`），
想换个字形只能手改 JSON 而且改不了（`CustomIcon` → `IconImage` **只吃图片**）。
现在把它**纳进设置界面**，并且多给一条渲染路径：nerd font 字形。

两个来源**互斥**，判定规则只有一条：

```
bar.topLeftIconGlyph 非空  →  渲染这个字形（字体 appearance.fonts.iconNerd），忽略 topLeftIcon
bar.topLeftIconGlyph 为空  →  维持上游行为（图片名 / "distro" / SVG 绝对路径）
```

**改动的三个文件**

1. `modules/common/Config.qml` —— `bar` 对象里、`topLeftIcon` 之后加一行：

   ```qml
   property string topLeftIcon: "spark"
   property string topLeftIconGlyph: "" // 本地新增：非空则覆盖 topLeftIcon，直接渲染这个字形（字体用 appearance.fonts.iconNerd）
   ```

   **默认值是空串**，所以升级后行为与上游完全一致（还是那个 spark）。

2. `modules/ii/bar/LeftSidebarButton.qml` —— 图标本体包一层 `Item`，
   里面 `CustomIcon` 与 `StyledText` 用 `visible` 二选一（`anchors.centerIn` 同一个位置），
   顺带把 ping 那个小圆点挪进这个 `Item` 里。

3. `modules/settings/BarConfig.qml` —— 新增「Top-left icon」一节（写在文件最前、
   `Notifications` 那节之前），四块：
   - `ConfigSelectionArray`：**图片** preset，24 个（`spark` / `google-gemini` / `openai` /
     `deepseek` / `mistral` / `ollama` / `openrouter` / 各发行版 / `github` / `desktop` / `crosshair` …）
   - `ConfigSelectionArray`：**字形** preset，28 个，分组是 AI·系统·开发·趣味
     （`cod-sparkle` / `linux-hyprland` / `oct-git_branch` / `fa-cat` …）
   - 一个自由文本框：粘贴任意字形，或填 SVG 绝对路径，旁边实时显示 `U+XXXX`
   - 一行说明 tooltip：也可以直接手改 `config.json` 的这两个键

   自备 SVG 放 `~/.local/share/ii-icons/`（**不要放进上游的 `assets/icons/`**，同步会被覆盖），
   在文本框里填它的绝对路径即可。

**四个非显然的坑（都已实测确认，改代码时别踩回去）**

1. **`CustomIcon` 会把 source 无条件拼到 `iconFolder` 后面。**
   它内部是 `iconFolder + "/" + source`，所以绝对路径会变成
   `<assets/icons>//home/cynsm/….svg` —— 图片直接不显示。
   修法：判 `startsWith("/")` 时把 `iconFolder` 传**空字符串**（空串在 `CustomIcon` 里是 falsy，
   它会原样使用 `source`）。别传 `undefined`，那会走另一条分支。

2. **字形一律写成码点，不要在源码里贴字形本身。**
   `text: String.fromCodePoint(0xF0238)` 这种写法让源文件保持纯 ASCII ——
   贴 PUA 字符进源码，一是肉眼分不清是哪个字形，二是工具（编辑器 / 脚本 / 剪贴板）
   过一手就可能改坏，而且 `Edit` 工具匹配含 PUA 的行很容易 `String to replace not found`。
   查码点用 `fontTools` 按**字形名**反查，别猜：

   ```python
   from fontTools.ttLib import TTFont
   font = TTFont('/home/cynsm/.local/share/fonts/JetBrains/JetBrainsMonoNerdFont-Regular.ttf')
   cmap = font.getBestCmap()
   for cp, name in cmap.items():
       if 'fire' in name.lower(): print(name, hex(cp))
   ```

   也可以直接问 fontconfig：`fc-list ':family=JetBrainsMono NF:charset=F0238' family`。

3. **别用 `fa-fire`（U+F06D）当火苗** —— 这个字形底下自带一条横杠，
   小号渲染出来像下划线。要用 `md-fire`（U+F0238，材料图标那套，跟 ii 整体风格也一致）。
   （`fa-fire` 还留在设置页的字形 preset 列表里 —— 列表是给人**看着挑**的，
   预览能看出那条横杠；但代码里要硬写一个火苗时别选它。）

4. **选图片时必须把 `topLeftIconGlyph` 清空**，否则字形一直盖着图片，
   表现是「点了图片 preset 没反应」。`pickTopLeftIcon()` 里那句
   `Config.options.bar.topLeftIconGlyph = ""` 就是干这个的。

⚠ **解析规则有两份**：`LeftSidebarButton.qml` 的 `imageSource` 和 `BarConfig.qml` 的
`resolveIconSource()`。改一处记得改另一处（两处都写了这条注释）。

**验证方法**

```bash
# 设置 → Bar → Top-left icon → 选字形 / 粘一个字形 → quickshell 热重载
grim -o eDP-1 /tmp/bar.png
magick /tmp/bar.png -crop 80x64+0+0 +repage -resize 400% /tmp/icon.png   # 看左上角
```

---

## 5. 左栏扩成多页 + 「字数」页（打字统计）

**背景**

上游左栏（`SwipeView`）的页签是写死的：Intelligence / Translator / Anime。
本地改成**条件展开 + 实例缓存**，现在最多五个页签：
翻译 / **字数** / **监控** /（Intelligence 与 Anime 按 `policies` 关闭）。

⚠ **零键位成本**：页签栏、滚轮切页、`Ctrl+PgUp/PgDn` 都是上游已有的，
新页面只是往 `tabButtonList` 里多一条，**没占用任何新键位**。

**新增的两个文件**

- `services/TypingStats.qml` —— 单例。读两个文件、做全部聚合与几何计算。
- `modules/ii/sidebarLeft/TypingStatsPage.qml` —— 页面。六张卡：
  今日输入（含连续打卡火苗）/ 本周·本月·总计 / 近 7 天 / **输入节奏**（24 小时分布）/
  **高频排行**（词语·拼音）/ 最近一年热力图。
  后两张（节奏、排行）随 `typingStats.showDetails` 开关出现。

**改动的两个文件**

1. `modules/common/Config.qml` —— `sidebar` 对象里加（`translator` 之后）：

   ```qml
   property JsonObject typingStats: JsonObject {
       property bool enable: true
       property string historyFile: ""    // 留空 → ~/.local/share/fcitx5/rime/py_wordscounter/words_count_history.json
       property bool showDetails: true    // 打字明细（小时分布 / 高频词 / 连打）
       property string detailsFile: ""    // 留空 → ~/.local/share/ii-stats/typing_details.json
   }
   ```

2. `modules/ii/sidebarLeft/SidebarLeftContent.qml` —— `tabButtonList`、
   `contentChildren` 各展开成条件列表，新增两个 `Component`。

**数据来源两条流，别混**

| 文件 | 谁写的 | 内容 | 用途 |
|---|---|---|---|
| `words_count_history.json`（几 KB） | 用户的 `rime_counter_rs` | `per_day` 354 天 | 今日/周/月/总计、热力图、连打 |
| `typing_details.json` | `ii-stats-daemon`（§6） | 小时分布、高频词/拼音、段数 | 「输入节奏」「高频排行」两张卡 |

前者是权威的「每天多少字」，后者才有分布。两个进程各写各的，所以**同一天的数字
可能差一两条** —— 页面上数字以 `per_day` 为准，明细只拿来画分布。

**五个非显然的坑（这条最重要，改代码时别踩回去）**

1. **⚠ `SwipeView.contentChildren` 是个绑定，会在启动时重新求值 → 页面实例泄漏。**
   上游那个占位页的条件写的是 `tabButtonList.length === 0`，而 `tabButtonList` 里
   有 `Translation.tr(...)`（页签名要翻译）—— 启动时语言从 `en_US` 切到 `zh_CN`，
   依赖 `Translation.tr` 的绑定全部重新求值，`contentChildren` 每求值一次就
   `createObject()` 一批**新**页面，旧实例还被 JS 那边引用着不会释放。
   这些孤儿页面里所有「引用页面根 id」的绑定会在根 id 已失效的状态下求值，刷一屏
   `TypeError: Cannot read property 'x' of null`：**实测一次启动泄漏 6 个页面、单页刷 1855 条**，
   整个日志 7760 条。**上游 `AiChat.qml` 有同样的症状**（别去抄它的写法）。
   两条修法**都要做**：
   - 条件里不出现 `Translation.tr` —— 把 `tabButtonList.length === 0` 展开成纯 Config 条件
     （`!aiChatEnabled && !translatorEnabled && !typingStatsEnabled && !systemMonitorEnabled && …`）
   - `cachedPage(key, component)` 按 key 缓存实例，重复求值拿回的是同一批对象

2. **⚠ 页面里的 delegate 一律不许引用页面根的 id。**
   只要 delegate 写了 `pageRoot.xxx`，页面实例一旦失效，delegate 就对着 null 求值。
   这条是**硬规矩**：**几何 / 色阶 / 状态 / 格式化函数全部下沉到单例**，
   delegate 只读单例 + `modelData`。所以你会看到 `TypingStats.levelColor()`、
   `TypingStats.groupDigits()`、`TypingStats.hourDistribution()` 这种「本该写在页面里」的东西。

3. **⚠ `RowLayout` 的 `Layout.fillWidth` 不是等分。**
   Qt 给 fillWidth 的项分剩余空间时**看各列的 `implicitWidth`（成比例）**。
   24 列里只有 4 列带轴标签、其余标签是空串（`implicitWidth` 0）时，
   带标签那几列能宽出十几倍 —— 画出来像「几根粗柱子夹一堆竖线」。
   最小复现（24 列 `Item{Layout.fillWidth: true; Layout.preferredHeight}+StyledText`）：

   | 组 | 列标签 | 实测列宽 |
   |---|---|---|
   | A | 4 列写 `"00"`，20 列空串 | **70px vs 5px** |
   | B | 4 列写 `" "`（空格），20 列空串 | 42px vs 10px |
   | C | 24 列全写（`"00"` 2 字 vs `"5"` 1 字） | 27px vs 13.5px（严格 2:1） |

   **修法：等分图形（24 根柱、371 个格子）的 `x/y/宽/高` 一律在服务层算好塞进模型**，
   页面用普通 `Item` + `Repeater` 手工定位，**不碰 Layout**。
   页面把「卡片内容区宽度」推给服务（`pushContentWidth()` 挂在 `onWidthChanged`
   + `Component.onCompleted` 上），服务据此算 `heatmapCellSize/hourColumnWidth`。

4. **火苗用 nerd font，不用 emoji。**
   用户明确要求。`md-fire`（U+F0238）+ `color: Appearance.colors.colPrimary` ——
   emoji 是彩色位图，跟 matugen 配色完全脱节。详见 §4 坑 2/3。

5. **页签宽度有上限。**
   `ToolbarTabButton` 是「图标 22px + 文字」，`horizontalPadding: 10`，
   可用宽度约 424px。**页签名必须用 1-2 字短标签**（翻译/字数/监控），
   实测三个页签占 254 逻辑像素、居中正常。再多就退成「只显示图标 + tooltip」
   （页签栏本来就能滚轮悬停切页）。

**验证方法**

```bash
# 数字对不对：用 CSV 独立重算 per_day，和页面上的「总计」逐个对比（§1 的老办法）
python3 -c "
import csv,collections
per=collections.Counter()
for r in csv.reader(open('/home/cynsm/.local/share/fcitx5/rime/py_wordscounter/words_input.csv',newline='',encoding='utf-8',errors='replace')):
    if len(r)>=6:
        try: per[r[1][:10]]+=int(r[5].strip())
        except: pass
print(sum(per.values()))"

# 柱宽对不对：截图上量 24 根柱的像素宽度（应当一致）
# 有没有新报错：主 shell 日志里 TypeError 的条数（<id> 见日志首行 "Launching config: …"）
grep -c TypeError /run/user/1000/quickshell/by-id/<id>/log.log
```

---

## 6. ii-stats daemon + 左栏「监控」页

**新增的四个文件**

- `~/.local/bin/ii-stats-daemon` —— Python3，**只依赖标准库**。
- `~/.config/systemd/user/ii-stats.service` —— 跟 `rime_counter.service` 同一套
  （`PartOf=graphical-session.target` + `Restart=on-failure` + `WantedBy=graphical-session.target`）。
- `services/SystemMetrics.qml` —— 单例，`FileView { watchChanges }` 读 summary。
- `modules/ii/sidebarLeft/SystemMonitorPage.qml` —— 页面。
  卡片：CPU / 内存 / GPU（使用率·显存·功耗·频率）/ 温度与风扇 / 电池 /
  **今日曲线**（可切 CPU·GPU·内存·温度，`Graph` 画）+ **近 7 天 CPU** 柱状。

**产出（都在 `~/.local/share/ii-stats/`）**

| 文件 | 内容 |
|---|---|
| `system_summary.json` | 「当前 + 今日曲线」，每 10 秒原子重写，QML 只读这个 |
| `metrics-YYYY-MM-DD.jsonl` | 原始采样，按天分文件，保留 30 天 |
| `typing_details.json` | 打字明细（§5 的第二张卡用） |
| `typing_state.json` | CSV 解析游标 + 累计计数（重启不用重扫 39MB） |

采样节奏：**10 秒** CPU/内存/温度/电池/磁盘，**30 秒** GPU（`nvidia-smi`），
**5 分钟** CSV。命令行开关：`--once` / `--rescan` / `--status`（调试用）。

**四个设计要点（都是踩过或差点踩的）**

1. **`nvidia-smi` 不能塞进 10 秒那条路。** 每次调用 100~300ms，
   10 秒一次倒也不是不行，但它在 `--query-gpu` 上偶尔会卡到 1 秒；
   单独 30 秒一次，且失败就保留上次的值（不掉帧、不刷日志）。

2. **⚠ 单实例保护用 `flock`。** §1 记过教训：两个 daemon 同时盯着同一批文件写，
   **每日明细会被清空**。`flock` 拿不到锁就直接退出（别用 pidfile，
   进程被 kill -9 之后 pidfile 会撒谎）。

3. **CSV 游标按字节记，且只吃以换行结尾的完整行。** 文件里有 UTF-8 中文，
   不能按字符算；读到写了一半的那一行要丢掉、下次再来。
   游标大于当前文件大小（文件被重写过）→ 从头发起重扫。
   用 `csv.reader` 时套一层 `io.StringIO`，别直接喂 bytes。

4. **所有 JSON 都是「写临时文件 + `os.replace`」。** 读端永远见不到半截文件 ——
   这也让 QML 侧 `JSON.parse` 失败时的处理可以很简单（保留上次的值，等下一次
   `fileChanged`）。今日曲线在内存里按 200 个等宽时段累积（平均 + 峰值），
   重启时从当天的 jsonl 重建 —— 所以 summary 大小恒定，跟跑了多久无关。

**验证方法**

```bash
systemctl --user status ii-stats.service
journalctl --user -u ii-stats -n 50
jq '.current.cpu, .current.mem, .today.cpu.max' ~/.local/share/ii-stats/system_summary.json

# 跟外部工具对一遍（数字应当吻合）
nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,power.draw --format=csv,noheader
upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -iE 'percentage|rate|energy'
```

**页面显示「数据太久没更新」时**：`SystemMetrics.fresh` 是
「距上次读盘 < 30 秒」，daemon 挂了就会翻假 —— 那条提示里的
`systemctl --user status ii-stats` 就是让人照着敲的。

---

## 7. 翻译页：语言列表换成常用列表（治滚动 freeze）+ 上游 `SelectionDialog` 的绑定环

**先说翻译引擎是什么**：`trans`（translate-shell 0.9.7.1-git，`/usr/bin/trans`），
默认后端是 **Google Translate 的网页端点**。ii 的调用形式：

```bash
trans -brief -no-bidi -source S -target T '文本'
```

**问题一：滚到中东/南亚那一段，整个侧栏冻十几秒。**

上游的候选列表直接来自 `trans -list-languages`：**159 项原生语言名**
（`Afrikaans` / `አማርኛ` / `العربية` / `བོད་ཡིག` …），覆盖 60+ 种文字。
Qt 每碰到一个新 script，**首次渲染要单独走一次字体回退**；本机装了 5209 个字体，
用 `TextMetrics` 实测单次同步耗时（`font.pixelSize: 16`）：

| 文字 | 首次 | 同 script 第二次 |
|---|---|---|
| latin / icelandic | 0 ms | 0 ms |
| korean | 9 ms | — |
| arabic | 9 ms | 0 ms |
| japanese | 18 ms | — |
| devanagari | 28 ms | — |
| amharic | 42 ms | — |
| **tibetan** | **153 ms** | — |

滚动时一个接一个新 script 首次渲染，累加就是十几秒的冻结。
（fontconfig 本身不慢 —— `fc-match` 只要 12 ms；贵的是 Qt 侧的字体回退 + shaping。）

**问题二**：列表按字母序排，中文排在最后面。

**改动 1 —— `modules/common/Config.qml`**：`language.translator` 里加

```qml
property list<string> customLanguages: [ "en-US|英语（美国）", … ]
```

每项 `"代码|显示名"`（显示名可省，省了就直接显示代码）。
**留空 `[]` → 回退到上游那份全量列表的行为。**
默认值按使用频率排：英(US/UK) → 简中 → 繁中(台) → 繁中(港) → 粤语 →
挪威语 → 冰岛语 → 日语 → 韩语 → 德语 → 法语 → 西班牙语。

**改动 2 —— `modules/ii/sidebarLeft/Translator.qml`**（5 处）：

1. 新增 `customEntries` / `useCustomLanguages` / `autoLabel`、
   `labelForCode()` / `codeForLabel()`、`selectorItems`。
   **关键点：发给 trans 的必须是*代码*（`en-US` / `yue` / `nb` …），界面上显示的是*名字*。**
   上游是把原生名直接当 target 传给 trans 的，自定义模式不能再这么干。
   认不出的旧值（配置里还留着 `"English"` 这种）原样显示，不会崩。
2. trans 命令串里插入 `root.engineArg`。
3. `getLanguagesProc.running: !root.useCustomLanguages` —— 自定义模式下不再白跑一次 `trans`。
4. `SelectionDialog` 的 `items` 换成 `root.selectorItems`，`defaultChoice` 用 `labelForCode(...)`，
   `onSelected` 里用 `codeForLabel(result)` 反查回代码再写配置。
5. 两个语言按钮的 `displayText` 走 `labelForCode(...)`。

**顺带修了上游一个死键**：`Config.options.language.translator.engine` 上游定义了却从没传给 trans。
现在 `engine` 非空且不是 `"auto"` 时会补上 `-engine '<值>'`（可选值看 `trans -list-engines`），
Google 端点不通时可以切 bing / yandex。

**改动 3 —— `modules/common/widgets/SelectionDialog.qml`（修的是上游 bug）**

现象：打开语言选择器时，**高亮（实心圆点）不落在当前语言上**。根因是 delegate 里这段（上游原文）：

```qml
checked: index === choiceListView.currentIndex
onCheckedChanged: { if (checked) choiceListView.currentIndex = index; }
```

`checked` 由绑定驱动，于是 delegate 一被创建（`false → true`）就会**赋值** `currentIndex`，
而**赋值会打断 `currentIndex` 的绑定**；此后 `defaultChoice` / `items` 再怎么变都不再跟随，
停在某个中间 index 上。Qt 自己会在日志里点破这条：

```
WARN scene: QML StyledRadioButton at SelectionDialog.qml[86:27]: Binding loop detected for property "checked":
qs:@/qs/modules/common/widgets/SelectionDialog.qml:98:21
```

实测（打开时目标语言是 zh-TW，在列表里排第 5 位 = index 4）：
`idx=5 → idx=4 → idx=3`，最后停在 3 —— 而 `items.indexOf(defaultChoice)` 自始至终是 4。
本机这个页面的 `items[0]` 是 `Translation.tr("Auto")`，翻译数据加载完会从 `"Auto"` 变「自动」、
触发一次 `items` 重设，正好是绑定已断之后，所以错位必现。

修法：**只把「用户真的点了这一项」同步给 `currentIndex`**，绑定保持活性：

```qml
onClicked: choiceListView.currentIndex = index
```

改完后同一次实测：`currentIndex` 一次都没被改写，绑定环警告 **8 条 → 0 条**，高亮落在正确的项上。

**`trans` 的语言代码（全部实测可用）**：

| 代码 | 结果 |
|---|---|
| `zh-CN` | 你好世界 |
| `zh-TW` | 你好世界 |
| `yue` | 哈囉，世界 |
| `nb` | hei verden |
| `is` | halló heimur |
| `ja` / `ko` / `de` / `fr` / `es` / `en-US` / `en-GB` | 正常 |

（`-target auto` 等于不翻译，原样返回。`-engine auto` 与 `-engine google` 都能用。）

**验证方法**

```bash
# 1) 列表内容与映射：起个 harness（模板见附录）打印
#    useCustomLanguages / selectorItems / labelForCode(...) / codeForLabel(...)
# 2) 打开选择器看高亮落点
grim -o eDP-1 /tmp/tr.png && magick /tmp/tr.png -crop 445x520+0+150 +repage /tmp/tr-crop.png
# 3) 绑定环：改前 8 条 / 改后 0 条
grep -ac 'Binding loop detected for property "checked"' /run/user/1000/quickshell/by-id/<id>/log.log
# 4) freeze：用 TextMetrics 逐个 script 量首次 shaping 耗时（见上表）
```

**注意**：改完之后 ii 自己往 `~/.config/illogical-impulse/config.json` 里写了 `customLanguages`
（照抄 `Config.qml` 的默认值），并把 `targetLanguage` 从 `"English"` 改成了 `"zh-CN"` —— 那是 ii 的正常写回。
旧的原生名（`"English"`）留在配置里也能用：显示时原样兜底，不匹配任何显示名，但 trans 认得它。

---

## 8. quickshell 保活（systemd）+ 那次 Super+C 事故

**事故（2026-09-22 晚）**：按了 `Super+C` 之后 quickshell 整个消失，而且**再也回不来**
（Hyprland 只在会话启动时 `hl.exec_cmd` 起它一次，没有守护）。

**日志证据**（`/run/user/1000/quickshell/by-id/<id>/log.qslog` 的尾部）：

```
Received event: "openwindow>>563ef1810140,3,mihomo-party,Clash Party"
Received event: "closewindow>>563ef1810140"          ← Super+C，关掉的是 Clash Party 的窗口
Received event: "activewindow>>,"
Received event: "closelayer>>quickshell:bar"         ← 紧接着 quickshell 的 layer 全被销毁
Received event: "closelayer>>quickshell"
```

`Super+C` 绑的是 `hl.dsp.window.close()`（`UserKeybinds.lua:107`）＝ Hyprland 的 `closewindow`。
`coredumpctl` 里**没有**对应的 core —— 所以不是崩溃，是**自行退出或被信号终止**；
`log.log`（stderr）退出前也没有任何异常。**触发链只确证到这里**：按键 → 关掉 Clash Party →
quickshell 退。不管它是自己判定"没有窗口了"而退，还是被谁信号杀，结论一样：**它不会自己回来**。

**为什么没有 QML 层的解法**：本机 pin 的 quickshell 版本（commit `7511545e`）
`ShellRoot` **没有 `keepAlive` 属性**（`/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes` 里查得到），
也就是说没法像新版本那样靠一个属性阻止"窗口全关 → 退出"。**只能靠外部守护。**

**解法：`~/.config/systemd/user/quickshell-ii.service`**

照 `rime_counter.service` / `ii-stats.service` 同一套写法，要点：

- `Environment=QSG_RENDER_LOOP=threaded`（帧率修复，原来写在 `Startup_Apps.lua` 里）
- `Environment=PATH=%h/.local/bin:...`（systemd user 的默认 PATH 不含它，而 ii 会调那底下的脚本）
- `Restart=always` + `RestartSec=1` —— **不管崩溃还是被误杀，1 秒内拉回来**
- `StartLimitIntervalSec=60` / `StartLimitBurst=10` —— 配置坏掉时别无限刷日志（进 failed 后看
  `systemctl --user status quickshell-ii`）
- `WantedBy=hyprland-session.target`（跟 rime_counter 一样，由 `Startup_Apps.lua` 末尾那条
  `systemctl --user start hyprland-session.target` 拉起 —— 那一刻 `WAYLAND_DISPLAY` 已经
  `import-environment` 进 systemd 了，所以必须挂在它底下，**不能**挂 `graphical-session.target`）

**同时改了 `~/.config/hypr/UserConfigs/Startup_Apps.lua`**：原来那行
`hl.exec_cmd("env QSG_RENDER_LOOP=threaded qs -c ii")` 已注释掉（注释里写了原因）。
⚠ **不要再恢复它**：同名 config 的第二个实例会被 `instance.lock` 挡掉，
结果是 systemd 那份退出、`Restart=always` 反复重启，两个启动路径互相打架。

**顺带的好处**：quickshell 现在是 systemd 的子进程，不再是 Hyprland 的子进程 ——
Hyprland 崩溃/重启时会带着 SIGHUP 杀掉旧子进程，systemd 管的不受这个影响。

**验证方法**

```bash
systemctl --user status quickshell-ii.service          # enabled + active (running)
systemctl --user kill --signal=SIGKILL quickshell-ii   # 强杀：4 秒内 MainPID 应变成新 PID
systemctl --user restart quickshell-ii                 # 改完 QML 想干净重启就用这条
```

**以后 bar/侧栏突然"整块消失"**：先 `systemctl --user status quickshell-ii` 看是不是在 failed，
再 `journalctl --user -u quickshell-ii -n 50`。日志仍在
`/run/user/1000/quickshell/by-id/<id>/log.log`（每次重启换新 id）。

---

## 9. 听歌统计（左栏「音乐」页 + 右栏第 4 个 tab）

**为什么是补丁**

上游有 `MprisController`（媒体弹窗在用）但**没有任何听歌历史统计**。本地加了一套，
数据**分两路，别混**：

| 看什么 | 谁提供 | 为什么 |
|---|---|---|
| **正在播的那首** | `MprisController`（本地 MPRIS） | 实时、带进度/时长/封面 |
| **历史与统计** | last.fm（`user.getrecenttracks` / `user.getTopArtists`） | 本机 MPRIS 只有当前这一首，没有历史 |

**为什么必须两个源**：last.fm 的 recenttracks 里「正在播」那条**没有 `date` 字段、
也不进历史**，拿它当播放器状态用是不行的；反过来 MPRIS 给不出「今天听了多少首」。
（`user.getTopArtists` 是按周/月聚合的，**没有「今日」粒度**，所以今日统计是
把 recenttracks 从头翻页下来自己在本地聚合的。）

**新增的三个文件**

- `services/LastFm.qml` —— 单例。XHR 拉取 + 本地聚合。**90 秒下限节流**
  （设置里填更小也按 90 秒兜底，last.fm 有速率限制；右栏是常驻加载的，必须靠这层拦住）。
- `modules/ii/sidebarLeft/MusicPage.qml` —— 左栏「音乐」页。在播卡 / 今日收听 /
  封面墙 / 今天循环过的 / 今日记录时间线 / 近 7 天占比。
  里面自带一个轻量 `ControlButton`（播放/暂停/上下首），**没有复用
  `mediaControls/PlayerControl.qml`** —— 那个是媒体弹窗的重组件（模糊背景 +
  ColorQuantizer + WaveVisualizer），塞进侧栏页太重。
- `modules/ii/sidebarRight/musicstats/MusicStatsWidget.qml` —— 右栏第 4 个 tab。
  容器只有 350px，**只放概览**（在播行 + 今日曲数 + Top3 专辑封面 + Top3 艺人）。
  长列表一律去左栏页，别往这儿塞。

**改动的四个上游文件**

1. `modules/common/Config.qml` —— 两处：
   - `stats` 对象（插在 `sounds` 与 `time` 之间，保持字母序）：
     ```qml
     property JsonObject stats: JsonObject {
         property JsonObject lastFm: JsonObject {
             property bool enable: true
             property string username: ""
             property string apiKey: ""
             property int refreshInterval: 120 // 秒；服务层另有 90 秒下限兜底
         }
     }
     ```
   - `sidebar` 对象里加 `property JsonObject music: JsonObject { property bool enable: true }`
2. `modules/ii/sidebarLeft/SidebarLeftContent.qml` —— `tabButtonList` /
   `contentChildren` 各加一条 + 末尾加一个 `Component`。
   ⚠ **加新页时那个占位页的条件也要跟着加**（`tabButtonList.length === 0` 已展开成
   纯 Config 条件，见 §5 坑 1），否则新页会跟占位页同时出现。
3. `modules/ii/sidebarRight/BottomWidgetGroup.qml` —— `tabs` 数组加第 4 项。
   **故意不做「关了 last.fm 就少一个 tab」的条件数组**：`Persistent` 里存的
   `bottomGroup.tab` 是索引，少一项就索引越界，上游对这种情形没有兜底。
   关掉 last.fm 时这一页显示空态提示。
4. `modules/settings/ServicesConfig.qml` —— 在 `Networking` 那节之前加
   `last.fm` 一节（Enable 开关 + 账号两栏 + 刷新间隔）。

**六个非显然的坑（都已实测确认）**

1. **⚠ 页面在 `Component.onCompleted` 里调 `refresh()` 会永远不生效。**
   `Config` 是异步加载的，那一刻 `Config.ready` 还是 false → `cfg` 是 `{}` →
   `enabled` 是 false → 请求被**静默 return**，而且之后再没人触发它。
   实测症状：harness 里日志一声不吭、页面永远空态。
   修法：服务里自己兜一刀 ——
   ```qml
   onEnabledChanged: { if (root.enabled) root.refresh(); }
   ```
   （跟 §5 坑 1 是同一类"启动时序"问题的另一副面孔：**别指望调用方的时机是对的**。）

2. **last.fm 用 `;` 分隔多艺人，但 `&` 不能拆。**
   `"Culprate; Siskiyou"` 不拆的话会在 Top 榜单里自成一档，榜首长这样；
   而 `"Simon & Garfunkel"` 是**一个**艺人名，拆 `&` 会把经典组合拆坏。
   规则：只按 `;` 拆，每个艺人各记一笔（合作曲要让两边都加分），
   时间线里显示用 `join(" & ")` 保持一行。

3. **⚠ 右栏那张卡的高度是写死的 350px**（`BottomWidgetGroup.qml:16`），
   而且**右栏整个目录没有任何 Flickable** —— 超出就是被裁掉。
   实测内容自然高：无在播 178 / 有在播 224，可用 330。
   往这一页加东西前先量，超了就把内容挪到左栏页。

4. **量内容高度用 `implicitHeight`，别用 `childrenRect`。**
   `ColumnLayout` 被 `anchors.fill` 时，`childrenRect` 量出来的是**容器**高
   （330，永远是满的），会误判成"放得下"；读 `collayout.implicitHeight`
   才是内容自然高度（178/224）。
   同理：**窗口内取位置用 `mapToItem(null, 0, 0)` 得到的是该窗口自己的 scene 坐标，
   不是屏幕坐标**（每个 layer shell 窗口一个 scene）—— 本次差点据此误判成
   "窗口跑到左上角去了"。

5. **封面尺寸别在 `RowLayout` 里写 `Layout.preferredHeight: width`。**
   实测第一张封面被撑到 **130px 高**（`width` 在布局求解时不可靠），
   把下面的行全挤出容器。改成 `Row` + 写死 `width/height: 64` 就稳了 ——
   跟 §5 坑 3（`Layout.fillWidth` 不是等分）是同一个家族：**等尺寸图形别交给 Layout 算**。

6. **空壳播放器会让「在播行」白占 40px。**
   D-Bus 上常驻着 `org.mpris.MediaPlayer2.playerctld`（playerctl 的守护进程），
   没有真实播放器时它也在，还可能留着上次的曲目元数据。
   `MprisController.activePlayer` 用的是**未过滤**的 `Mpris.players.values[0]`
   （`isRealPlayer` 只作用于 `players` 那个属性）→ player 非 null 但内容为空。
   判定改成 `(root.track?.title ?? "").length > 0`。

**顺带发现：Qt 的网络请求走 KDE 配置里的死代理（尚未修）**

症状：`[LastFm] 拉取失败：HTTP 0`（连接根本没建立），同一时刻 `curl` 同一个 URL 正常。

- `~/.config/kioslaverc` 里 `[Proxy Settings] ProxyType=1` +
  `httpProxy=http://127.0.0.1 7897`（KDE 格式：host 与 port 用**空格**分隔）
- 本机 mihomo（Clash Party）的混合端口是 **7890**，**7897 无人监听**（`ss -tlnp` 确认）
- **Qt 读 KDE 的代理设置，curl 不读**（只认 `http_proxy` 环境变量，本机环境里没有）
  → 所以 curl 通、Qt 挂

**影响范围不止 last.fm**：ii 的天气、Booru、听歌识曲等**所有 Qt 网络请求**都受影响。

**2026-09-23 已修**（用户拍板改法）：`~/.config/kioslaverc` 里 `ProxyType=1` → `0`，
三行指向 7897 的 `httpProxy` / `httpsProxy` / `socksProxy` 和那行 PAC 脚本地址一并删掉
（都是 Clash Party 的旧端口；**TUN 已全局开启，显式代理本就多余**）。
原文件备份在 `~/.config/kioslaverc.bak-2026-09-23`。

验证：harness 里发一个**不带 key** 的 last.fm 请求，`HTTP 0` → `HTTP 400` ✅
（400 = 连接建立、只是缺参数；0 = 连不上。带 key 的真实请求则返回 200。）

**验证方法**

```bash
# 数字对不对：直接问 last.fm 今日总数，和页面上的「今日 N 首」比
# （差 1 是正常的：正在播的那条 nowplaying 不算在内）
curl -s --noproxy '*' -A "$UA" "https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks\
&user=<用户名>&api_key=<key>&format=json&from=$(date -d today +%s)&limit=200" \
  | jq '.recenttracks["@attr"].total'

# 服务自己的日志（key 不会出现在日志里）
grep -a '\[LastFm\]' /run/user/1000/quickshell/by-id/<id>/log.log
#   [LastFm] 今日 28 首 / 10 位艺人 / 10 张专辑；榜首 Culprate
#   [LastFm] 近 7 天 32 首；榜首 Culprate

# 排版：harness 截图（模板见附录，窗口照抄 400x350）
grim -o eDP-1 /tmp/tab.png
magick /tmp/tab.png -crop 645x585+1915+65 +repage -resize 55% /tmp/tab-crop.png
```

**用 harness 验排版时注意跨天**：0 点之后今日数据本来就是空的（服务行为正确），
想看满排版得往单例里塞假数据 —— 在 harness 里直接 `LastFm.topAlbums = [...]` 赋值即可，
但**要等它自己拉完**（`Timer { interval: 2500 }`）再塞，否则会被 `finishToday()` 的清空覆盖掉。

**设置项里那个 key 的来路**：从 `rescrobbled` 的配置搬过来的（用户原有），
已写进 `~/.config/illogical-impulse/config.json` 的 `stats.lastFm`。
**默认值只写 `Config.qml`** —— 手改 `config.json` 加的东西会被 ii 的写回冲掉（§5 坑 5）。

---

## 10. 左栏「系统维护」页

**为什么另起服务，而不是扩展上游的 `services/Updates.qml`**

上游那个文件只有一句 `checkupdates | wc -l`，而且**全 ii 没有任何界面显示它**
（`ServicesConfig.qml` 里那段设置至今是注释掉的，上游自己写着
"There's no update indicator in ii for now"）。维护页要的东西比它多得多
（AUR / 孤儿包 / 缓存 / 上次升级），与其把一个上游文件改成另一个东西，
不如新建 —— **上游同步时少一处冲突**。那个上游文件就留在原地不管。

**新增的两个文件**

- `services/Maintenance.qml` —— 单例，跑 8 条命令 + 节流（5 分钟）。
- `modules/ii/sidebarLeft/MaintenancePage.qml` —— 页面。四张卡：
  系统更新 / 包缓存 / 孤儿包 / 系统。

**改动的两个上游文件**：`Config.qml`（加 `sidebar.maintenance.enable`）、
`SidebarLeftContent.qml`（第 5 个页签：`property` / `tabButtonList` /
`contentChildren` / 占位页条件 / `Component`，共五处）。

**⚠ 这一页不执行任何会改动系统的动作。** 只显示状态、把命令复制到剪贴板
（`Quickshell.clipboardText = ...`，ii 里已有这个写法），更新 / 清理由用户自己去终端敲 ——
要提权、且不可逆的事不该由侧栏按钮代劳。

**命令与实测耗时**（EndeavourOS，2026-09-23）

| 查什么 | 命令 | 耗时 |
|---|---|---|
| 官方仓库可更新数 | `set -o pipefail; checkupdates \| wc -l` | 0.6s |
| AUR 可更新数 | `paru -Qua \| wc -l` | 4.3s |
| 孤儿包 | `pacman -Qtdq` | 0.9s |
| 包缓存体积 | `du -sh /var/cache/pacman/pkg \| cut -f1` | 0.1s |
| 上次升级 | `grep -a 'starting full system upgrade' /var/log/pacman.log \| tail -1` | — |
| 内核 / 已装包 / flatpak | `uname -r` / `pacman -Qq \| wc -l` / `flatpak list --app \| wc -l` | — |

最慢的 paru 那条决定了节流 = **5 分钟**（页面每次切回来都会调 `refresh()`，靠这层拦住）。

**五个非显然的坑**

1. **⚠ `checkupdates` 的退出码有语义**：0 = 有更新、**2 = 没有更新**、其他 = 出错
   （脚本结尾那个 `exit 2` 就是"没更新"分支）。所以命令必须写成
   `set -o pipefail; checkupdates | wc -l` —— 否则退出码是 `wc` 的 0，
   数据库被锁 / 断网会被显示成「0 个更新」。判据：`lastExit` 不是 0 也不是 2 就**保留上次的值**。
   ⚠ 另外 `StdioCollector.onStreamFinished` 与 `Process.onExited` **谁先谁后不保证**，
   所以两边都调同一个 `apply()`，退出码还没回来时（-1）直接 return。

2. **⚠ 左栏的 `contentChildren` 不是懒加载。** `cachedPage()` 会**立即**
   `createObject()` —— 也就是说这个页面在 ii **启动时就存在了**（SwipeView 里全是预创建的）。
   要是在 `Component.onCompleted` 里调 `refresh()`，每次启动都会白跑那 8 条命令
   （paru 那条 4 秒 + 联网）。
   修法：**只在 `visible` 时刷**，`onCompleted` 里加一句 `if (visible)` 兜底
   （覆盖"SwipeView 正好停在那一页"的情况）。
   ⚠ **`MusicPage.qml` 原来也有这个毛病**（启动就发 last.fm 请求），一并改了。

3. **`pacman.log` 的时间戳不能用 `Date.parse`。** 格式是
   `[2026-09-18T22:10:29+0800]`，而 ISO 8601 要求时区写成 `+08:00`（带冒号）——
   Qt 的 JS 引擎不认这种写法。正则截出年月日时分，按**本地时间**
   `new Date(y, m - 1, d)` 构造（那个 `+0800` 就是本机时区）。

4. **天数按「日历天」算，不按 24 小时。** 18 号晚上升级、23 号凌晨来看，
   时间差只有 4 天出头，但人会说「5 天前」。两边都取当天 0 点再相减。

5. **空壳播放器**（同 §9 坑 6）：`playerctld` 常驻 D-Bus，
   `MprisController.activePlayer` 非 null 但没有元数据 —— 在播卡的显示条件要用
   `track.title` 是否为空来判断。`MusicPage.qml` 同样改了。

**⚠ 页签宽度这次是卡着上限过的**

`ToolbarTabButton` 是「图标 22px + 文字」+ `horizontalPadding: 10`。实测
**五个页签（翻译/字数/监控/音乐/维护）工具栏宽 406px**；左栏内容区可用约 **425px**
（460 − `hyprlandGapsOut` − `elevationMargin` − 2×`sidebarPadding`）—— **余量只剩约 19px**。

**再加第六个页签就会溢出**（页签栏没有滚动）。真要加，先改成「只显示图标 + tooltip」
（页签栏本来就支持滚轮悬停切页）。

**验证方法**

```bash
# 单独验页面：面板宽照抄左栏的 460（harness 模板见附录）
qs -p ~/.config/quickshell/ii/_harness-maintenance.qml > /tmp/h.out 2>&1 &
grep -a harness /tmp/h.out   # 打印「五页签工具栏宽 = 406 | 面板内可用 ≈ 440」

# 数字对不对：跟手动跑一遍对比
checkupdates | wc -l; paru -Qua | wc -l; pacman -Qtdq | wc -l
du -sh /var/cache/pacman/pkg; grep -a 'starting full system upgrade' /var/log/pacman.log | tail -1

# 有没有白跑命令（页面不可见时应当一条都没有）
pgrep -a 'paru|checkupdates'
```

---

## 11. 外观参数化 + preset 系统 + 死亡搁浅主题

**为什么这么做**：`Appearance.qml` 里**除透明度一项外，所有度量都是硬编码** —— 圆角 8 档、
字号 9 档、动画 9 组、面板尺寸约 20 项，想换口味只能改代码。所以先把它们接到 Config
（这一步本身零视觉变化），「preset」才有东西可套。

三层结构（改动前就存在，这里只是划清边界）：

| 层 | 归谁管 | 本次动了吗 |
|---|---|---|
| 配色 | matugen / theme-switcher | ✅ 动了（见「DS 主题」与坑 8） |
| 基础度量 | `Appearance.qml`（硬编码） | ✅ 参数化 |
| 组件内部样式 | 散落数百处 | 只加全局开关，不逐处参数化 |

**preset 与自由调不互斥**：preset 只是一组值的快照，套完仍可逐项微调；微调后不会「退出 preset」，
`lastAppliedName` 仍显示旧名（已知的语义糙点，不打算修）。

### 新增的文件

| 路径 | 作用 |
|---|---|
| `modules/settings/AppearanceConfig.qml` | 设置页，6 段：预设 / 圆角 / 字号与密度 / 面板尺寸 / 动画手感 / 图标与材质 |
| `services/AppearancePresets.qml` | Singleton，枚举 + 读取 + 套用 preset |
| `~/.config/illogical-impulse/appearance-presets/*.json` | 7 套 preset（见下） |
| `~/.config/illogical-impulse/translations/zh_CN.json` | 35 条用户翻译（补内置缺口，见坑 16） |
| `~/.config/theme-switcher/themes/death-stranding.theme` | `THEME_TYPE="static"` |
| `~/.config/theme-switcher/assets/death-stranding/` | 5 件：`colors.json` / `foot.ini` / `gtk.css` / `hypr.colors.lua` / `hyprlock.colors.conf` |
| `~/.config/theme-switcher/assets/{gruvbox-dark,gruvbox-light,kanagawa-dark}/colors.json` | 补的，理由见坑 8 |

⚠️ preset 目录**不在 QML 树里** —— `Directories.shellConfig` 指的是
`~/.config/illogical-impulse`（**不是** `~/.config/quickshell/ii`，容易记反）。
好处：preset 属于用户数据，上游 `--delete` 同步 QML 目录时不会被删。

7 套 preset：`default`（34 项，**含所有档位绝对值**）/ `compact` / `spacious` / `round` /
`square`（含 `rounding.full: 3` + panelOutline）/ `lively` / `death-stranding`。

> `default.json` 之所以要写全 34 项绝对值、而不能只写 `rounding.scale: 1`：
> 用户手改过 `small: 40` 之后，只把 scale 设回 1 是恢复不了原状的。

### 改动的上游文件

| 文件 | 改动 |
|---|---|
| `modules/common/Config.qml` | `appearance` 段新增 `rounding`(含 `scale`) / `fontSize`(含 `scale`) / `sizes` / `animation`(含 `scale`、`curveStyle`) / `iconFillAll` / `panelOutline` / `letterSpacing` |
| `modules/common/Appearance.qml` | 上述各档改为从 Config 读；`colLayer0Border` 按 `panelOutline` 派生；动画曲线三选一 |
| `modules/common/widgets/MaterialSymbol.qml` | `fill` 默认值 0 → **-1 哨兵**；`Behavior` 从 `fill` 改挂 `truncatedFill` |
| `modules/common/widgets/StyledText.qml` | `font` 组加 `letterSpacing: Appearance.letterSpacing` |
| `settings.qml` | `pages` 数组在 Background 之后插入 Appearance 页 |
| `ii/bar/BarContent.qml`、`ii/bar/verticalBar/VerticalBarContent.qml` | `border.width` 加 `\|\| Appearance.panelOutline` |

ii 之外：`~/.config/theme-switcher/switch.sh` 的 `COMPONENT_MAP` 加一行
`colors.json|$HOME/.local/state/quickshell/user/generated/colors.json`；
`~/.config/darkman/{dark,light}-mode.d/20-quickshell-ii.sh` 各加一段 static 主题判断（坑 8）。

### 实测数据

| 检查项 | 实测 |
|---|---|
| 参数化前后 dump 对比（零变化判据） | 40+ 项逐字一致，**唯一差异** `sizes.hyprlandGapsOut` 5→4（有意修正，见坑 9） |
| 设置页引用的 Config 键 | 33 个，逐个核对过存在 |
| preset 键 vs Config 键（`comm` 机械核对） | 18 个，无静默失败 |
| `rounding.full` 引用点 | **37 处**（头像遮罩、开关轨道、滑块手柄、徽章） |
| 不走 token 的半径 | `radius: height/2` **25 处**、`width/2` 7 处、字面量 9999 5 处 |
| `StyledText` 规模 | 325 处实例 / 136 文件；`letterSpacing` 改前**全仓 0 处**使用 |
| `MaterialSymbol` 显式 `fill` | 32 处（14 静态 1 / 7 静态 0 / 11 条件式），其余走哨兵 |
| panelOutline 实需改动 | **2 个文件**（计划里写的 9 个是错的，见坑 5） |
| DS `colors.json` 键集合 | 与 matugen 的 `diff` 为空，49 键 |
| matugen 安全性验证 | `--dry-run --show-colors` 前后 md5 不变：`826f0ed5e91edb1d9f20ddcf28f9f5b3` |
| 热重载确认 | 文件 mtime 00:28:06 → 日志 `INFO: Reloading configuration` 00:28:16 |
| darkman 钩子干跑 | death-stranding / gruvbox-dark / kanagawa-dark → 跳过；matugen / 空 / 不存在 → 走 switchwall（零回归） |
| 设置页中文字符串缺口 | 抓出 37 条，其中 **35 条**内置表没有（用户表已补全） |
| `ConfigSpinBox` 冻值复现 | 受控实验：外部属性 5 → 42 秒后改 42，修复前控件**停在 5**，修复后跟到 **42** |
| 设置页实际渲染（2026-09-23 补验） | 6 段全出、7 套 preset 全枚举、中文标签正常、每个数值与 `config.json` 一致（`.full`=3 / `windowRounding`=0 / `barGapsOut`=4 / `curveStyle`=standard / `iconFillAll`=off / `panelOutline`=on / `letterSpacing`=0.5→滑块 25%） |

### 非显然的坑

1. ⚠ **`rounding.full`(=9999) 不是装饰性圆角，是「圆形/胶囊」语义**（37 处）。
   所以它**不参与 `rounding.scale` 缩放** —— 缩放哨兵值没有视觉意义，
   还会让「圆角全 0」的 preset 看起来像是要动它。设置页里它单独用 `ConfigSpinBox`，
   `square.json` 给它 3 而不是 0（否则头像变方块、开关变方轨）。

2. ⚠ **`radius: height/2`（25 处）/ `width/2`（7 处）不走 token** —— 进度条、滚动条永远保持胶囊。
   这是**故意的、不是漏网**：方角 preset 下它们仍然圆，属预期行为。

3. ⚠ **78 处 `font.pixelSize` 字面量不跟随字号参数**（时钟大数字这类特殊件）。
   已知限制：密度调整对它们无效。想覆盖得逐个改，收益不划算。

4. ⚠ **JsonObject 只能写已定义的键** —— `Config.setNestedValue()` 对不存在的键**静默失败**
   （不报错、不生效、不落盘）。所以每加一个 preset 键，都必须在 `Config.qml` 里先存在。
   这正是「第一步先参数化」的意义。

5. ⚠ **`panelOutline` 不是「加边框」，是「让一直存在但看不见的边框显出来」。**
   计划原写「改 9 个消费组件的 `border.width`」，实测**一个都不需要**：
   6 个本来就恒 `border.width: 1`（`SidebarLeft` / `SidebarRightContent` / `StyledPopup` /
   `WallpaperSelectorContent` / `Cheatsheet` / `SysTrayMenu`），只是颜色淡到看不见；
   2 个跟 `cornerStyle` 走。按原计划改会把那 6 个从 1 改成 0，**破坏零变化**。
   实际只改 `BarContent` + `VerticalBarContent` 两处，加 `|| Appearance.panelOutline`。
   颜色一变（`#2a292a` → alpha 0.65 的 `m3outlineVariant`），那些边框自己就显出来了。

6. ⚠ **qml Singleton 是懒加载的** —— 首次访问才实例化、内部的 `Process` 才开跑。
   用 harness 验证时踩过：在 Timer 里第一次访问 `AppearancePresets` 然后立刻读
   `presetNames`，拿到的是空列表。**真实场景不受影响**（设置页是响应式绑定）。

7. ⚠ **`StyledSlider` 的 tooltip 对 value 做 `Math.round`** → 缩放类参数（`rounding.scale`、
   `fontSize.scale`、`animation.scale`、`letterSpacing`）在界面上用 **×100 / ×10 的整数**，
   存回时再除。直接给 0~2 的小数会在 tooltip 里全显示成 0 或 1。

8. ⚠ **静态主题与 darkman 打架**（原计划「风险 5」命中）。
   darkman 的两个钩子直接调 `switchwall.sh`，**不经过 theme-switcher**，
   日出日落时会重新生成 matugen 配色、把静态主题写好的 `colors.json` 冲掉 →
   界面停在主题色、窗口/终端却跟着壁纸变了。
   修法：钩子里读 `~/.config/theme-switcher/current`，`THEME_TYPE="static"` 就跳过
   **ii 配色这一项**（上面的 `theme-sync.sh` 照常跑）。当前值 `matugen` → 行为与改动前完全一致。
   **连带修的**：`switch.sh` 的 `COMPONENT_MAP` 原本没有 `colors.json`
   （所以静态主题从来管不到 ii UI），加上这一行后，**另外三个静态主题也必须各补一份 `colors.json`** ——
   否则从 DS 切回 gruvbox 时，ii 会停在 DS 的配色。这就是那几个文件存在的原因。

9. ⚠ **顺手修的老 bug**：`Appearance.sizes.hyprlandGapsOut` 硬编码 5，而
   `~/.config/hypr/UserConfigs/UserDecorations.lua` 里 `gaps_out = 4` —— bar 开 Float 时缩进多 1px。
   参数化时一并改成读 `sizes.barGapsOut`（默认 4）。**这是零变化验证里唯一的差异，是有意为之。**

10. ⚠ **preset 套用 = 写 Config → 触发 `config.json` 落盘**（ii 有 50ms 防抖写回）。
    这是正常行为，不是 bug。同理：**它写的是用户数据文件**，测试时别自动套。

11. ⚠ **换壁纸会清空 `accentColor`**（上游有意设计）—— 所以固定配色不能靠 `accentColor` 实现，
    只能走静态主题那条路。

12. ⚠ **`rounding.screenRounding` 派生自 `large`，没有独立 Config 键。**
    方角 preset 会连带把屏幕圆角也变方。若要「方角面板 + 圆角屏幕」得单独加键，目前不支持。

13. ⚠ **`ConfigSpinBox` 曾「冻在创建时的值」不跟外部变化 —— 本轮已修**（`widgets/StyledSpinBox.qml`）。
    根因：`StyledSpinBox` 里 `text: root.value`（text 派生自 value）+ `onTextChanged: { root.value = parseFloat(text) }`
    —— 这条绑定**第一次求值**就触发处理器，那次无条件命令式赋值**打断了调用方写在 `value:` 上的绑定**
    （页面里是 `value: Config.options.appearance.…`），于是控件与 Config 永久脱钩。
    后果：套完 preset（或拖滑块改倍率）后**约 20 个 SpinBox 仍显示旧值**，
    此时再点一下 +/− 就会把**陈旧值写回 `config.json`，静默覆盖刚套上的 preset**。
    修法两道守卫：① 只有输入框真拿到焦点（= 用户在手输）才回写；② 值确实不同才赋值
    （否则键盘 ± 也会打断绑定）。**受控复现**（不碰 config.json）：harness 里
    `property int testVal: 5` + Timer 4 秒后改 42 + `ConfigSpinBox { value: win.testVal }` ——
    修复前停在 5，修复后跟到 42。这与「给绑定赋值 = 打断绑定」是同一个家族的坑
    （§7 的 `SelectionDialog` checked 绑定环、§11 坑 1 的 `Behavior` 只能赋值一次都是它）。

14. ⚠ **设置页初始加载写死 `pages[0]`** —— `settings.qml:247` 的
    `Component.onCompleted: source = root.pages[0].component` 与 `currentPage` **无关**，
    而切页动画只挂在 `onCurrentPageChanged`（只在**变化**时触发）。
    所以把 `currentPage` 改成别的值 → **导航高亮挪了、内容却还是第 0 页**
    （我因此白截了一轮图，还以为是页面写错了）。要在真窗口里看深层页，临时把那行也改成
    `root.pages[root.currentPage].component`，看完两处一起改回。

15. ⚠ **`Config` 是异步加载的** —— `Config.ready` 从 false 变 true（实测 t0 `false`、t2.5s `true`），
    在此之前创建的页面拿到的是 **`Config.qml` 里的默认值**（比如 `rounding.full` 显示 9999 而非 3）。
    排查「界面显示的值和 `config.json` 对不上」时**先排除这条**，别急着怀疑参数化串线。
    设置页本身有 `active: Config.ready` 挡着，所以真窗口不受影响 —— 只有自己写的 harness 会中招。

16. ⚠ **新增了用户翻译表** `~/.config/illogical-impulse/translations/zh_CN.json`（35 条）。
    `services/Translation.qml` 有两个 `TranslationReader`：内置的
    `Quickshell.shellPath("translations")` 与用户的 `Directories.shellConfig + "/translations"`，
    查找式是 `tr[key] || generated[key] || key` —— **内置优先**，所以用户表只补缺口、不覆盖。
    缺口怎么算：抓出页面里所有 `Translation.tr(...)` 的字面量，与内置 `zh_CN.json` 的键做 `comm`。
    术语沿用 ii 内置译法（`Palette` 用「配色」、`Bar` 用「条栏」、`Rounding` 用「圆角」）。

### 验证方法（本次用的）

```bash
# 零视觉变化：改前 dump 一份、改后 dump 一份再 diff
#   harness 要点：必须 import qs.modules.common.functions（ColorUtils 在那），
#   且只能用 `qs -p <绝对路径>`（-p 与 -c 互斥）
qs -p "$PWD/_harness-appearance.qml" > /tmp/appearance-after.txt

# 热重载是否真的生效：文件 mtime vs 日志时间
stat -c %y modules/common/Appearance.qml
grep "Reloading configuration" ~/.local/state/quickshell/ii/logs/*.log | tail -1

# 主实例有没有 QML 报错（热重载后必查）
grep -iE "error|is not defined" ~/.local/state/quickshell/ii/logs/*.log | tail -20

# preset 键 vs Config 键的机械核对（抓静默失败）
comm -23 <(jq -r 'keys[]' ~/.config/illogical-impulse/appearance-presets/xxx.json | sort) \
         <(grep -oP 'property \w+ \K\w+' modules/common/Config.qml | sort -u)

# 在真窗口里看「深层页」（如第 5 页 Appearance）：临时改 settings.qml 两处，看完一起改回
#   ① property int currentPage: 4
#   ② pageLoader 的 Component.onCompleted: source = root.pages[0].component
#      → 改成 root.pages[root.currentPage].component（不改就是「高亮挪了、内容没挪」，见坑 14）
# 页面比窗口高时，harness 里用「y 负偏移」看尾部（1:1，比缩略图清楚得多）：
#   Item { width: 620; height: 1800; y: -850; Loader { anchors.fill: parent; source: "…" } }
# 开窗前先断言焦点屏（本机 dispatch 语法见附录），否则窗会开在用户正在干活的主屏上。
```

⚠️ 仍然**没有验证到的**（诚实记录，别当成已验证）：
- `applyPreset` 的真实写入效果 —— 会改 `config.json`，未自动测试。
  （用户在 2026-09-23 前自行套过一次 `death-stranding`，`config.json` 里确实留下了完整的
  preset 痕迹，所以这条链路是通的；但我没有做过「套用 → 逐键比对」的自动验证。）

✅ 2026-09-23 补验（此前三次截图都被游戏窗口遮挡、从未真正看到过这个页面）：
- 设置页 Appearance 的真实排版：6 段全出、7 套 preset 全枚举、无 QML 报错；
  每个控件显示的数值都与 `config.json` 逐项一致（含两个倍率滑块的位置 = 值 ÷ 2，
  因为滑块量程是 0~200 对应 0~2.0）。
- 中文标签实际渲染：35 条用户翻译全部生效（`预设`/`圆角`/`字号与密度`/`面板尺寸`/`动画手感`/
  `图标与材质`/`填充图标`/`面板描边`/`字距（×0.1px）`…），曲线 chips 显示为
  `表现力 / 标准 / 线性`，preset chips 保持文件名（`death-stranding` 等，故意的：那是文件名）。

---

## 12. Obsidian 双库 → GitHub 提交工作流（vaultCommit）

两个库（`Learning and Coding Shit` = 代码与仓库 / `SecondBrain` = 第二大脑）各自 git init
并推到 private GitHub repo。桌面两个键：

| 键位 | 作用 |
|---|---|
| `SUPER+ALT+G` | **提交**：认当前库 → 弹框显示变更摘要 → 手写 message → 回车 = `add -A` + `commit` + `push` |
| `SUPER+ALT+S` | **速记**：弹框预填 `October 7th, 2026 - `，补个标题 → 建同名 `.md` 并让 Obsidian 打开 |

弹框里有一行**目标库 chip**（配了 2 个以上库才出现）：默认是识别出来的那个库，点另一个即可改写到别的库
（速记/提交都有）。认不出是哪个库 → 弹 `SelectionDialog` 让用户选。

### 新增的文件

- `modules/ii/vaultCommit/VaultCommit.qml`（885 行，面板本体：`Scope` + 5 个 `Process` + `Loader` 包 `PanelWindow`）
- `~/.local/bin/vault-commit`（468 行，**全部 git 逻辑就在这一个脚本里**，可单独在终端跑；
  含无 GUI 环境的 `interactive` / `capture-interactive` 兜底，见第四/五轮）
- `~/.config/vault-commit/vaults.json`（两库的 key/name/label/path；`VAULT_COMMIT_CONFIG` 可整体换掉，测试就靠它）

### 改动的上游文件

- `panelFamilies/IllogicalImpulseFamily.qml`：+2 行（import + `PanelLoader`）
- `translations/zh_CN.json`：722 → 750 键（手写 28 条，见坑 7）
- `modules/common/widgets/SelectionDialog.qml`：+`dialogRadius` 属性（默认 `rounding.normal` 不变，弹框传入更大的角；翻译页不受影响）
- `~/.config/hypr/UserConfigs/UserKeybinds.lua`：+2 条 `hl.bind`（EOF；备份 `.bak-before-vaultcommit`）
- `~/.config/systemd/user/quickshell-ii.service`：+`Environment=QT_IM_MODULE=fcitx`（见坑 2）

### 非显然的坑

1. **本机 `qs -c ii ipc` 不通**（`No running instances`，尽管 `/run/user/1000/quickshell/by-path/…`
   的映射确实存在）。所以键位**没走**计划里的 `hl.dsp.exec_cmd("qs -c ii ipc call …")`，
   改成 `hl.dsp.global("quickshell:vaultCommitOpen")` ↔ QML `GlobalShortcut`（和现有
   `quickshell:cheatsheetToggle` 同一套）。`IpcHandler` 仍然留着——这台机器上没用，换机能用。
2. **面板里打不出中文**：`/etc/environment` 的 `QT_IM_MODULE` 是被**故意注释掉**的
   （Wayland 下全局设它会绕过 text-input 协议，fcitx5 官方不建议），而 quickshell 是 Qt 应用、
   又不走 text-input → 不会加载 fcitx5 的平台输入上下文插件。解法是**只给这一个服务**加
   `Environment=QT_IM_MODULE=fcitx`。判据：`grep -ci fcitx /proc/<pid>/maps` —— 不设 = 0，
   设上 = 10（其中 `libfcitx5platforminputcontextplugin.so` 就是它）。实测打 `nihao` + 空格出「你好」。
3. `SelectionDialog` 是给 460px 左栏设计的（`anchors.fill` + 默认 `dialogMargin: 30`），
   直接塞进全屏 `PanelWindow` 会摊满整个屏幕。**外面包一层定尺寸 `Item`**，并把 `dialogMargin` 置 0。
4. **`Process` 必须挂在 `Scope` 上、别放进 `Loader` 里的 `PanelWindow`**：否则 Esc 一关窗就把
   正在跑的 push 连带 SIGKILL 掉了（`Loader.active=false` 会销毁组件树）。
5. 脚本的子命令**几乎全部 `exit 0`**，失败也是返回 0 + `{"ok":false,...}`。前端必须判 `ok`
   字段，**不能看 exit code**。
6. push 失败后的重试路径：`apply` 的「无改动」分支要先查 `@{u}..HEAD`，发现还有未推的提交就
   **只补推**；否则用户重试只会一直被告知「没有需要提交的改动」，永远推不上去。
7. ⚠️ `manage-translations.sh update -l zh_CN -y` 会**删掉源码里仍在使用的键**（实测 16 条，
   如 `"Unknown command: "`、`"There might be a download in progress"`），还顺带灌进 244 条
   无关键。**别用它加词条**，手工改 JSON（`json.dump(..., ensure_ascii=False, indent=2)`）。
8. 键位本身不受「本机 `hyprctl dispatch` 只认 Lua 语法」那条坑影响（走 `hl.bind`）。
9. `git status --porcelain` **默认会把非 ASCII 路径转义**成 `"\346\214\252..."`（`core.quotePath`），
   中文文件名全变乱码。脚本里得写成 `git -c core.quotePath=false status --porcelain`。
   这坑直到拿中文长路径做视觉测试才暴露 —— 之前测试全用英文文件名。
10. ⚠️ push 失败后的重试块，**重试前 `rc` 必须先归零**。`perr="$(run_push …)" || rc=$?`
    在重试**成功**时不会执行 `|| rc=$?`，`rc` 留着第一次的失败码 → 明明推成功了却报
    「推送失败」（双机测试实测踩到：远端提交都到位了，输出还是 `{"ok":false,"stage":"push"}`）。
    两处重试（`-u origin HEAD` 补 upstream、rebase 后重推）都要。

### 视觉：怎么跟 ii 对齐的（2026-10-07 第二轮）

初版是「浮在全屏 scrim 上的一张平底矩形」，跟 ii 别处不像。对齐靠三条：

1. **色和圆角抄同屏最近的那个组件。** 认库失败弹的 `SelectionDialog` 用的是
   `Appearance.m3colors.m3surfaceContainerHigh`（#2b2a2a）+ `rounding.normal`，
   卡片就跟它一模一样 —— 两个视图来回切时不跳色、不跳角。
2. **用不透明的 `m3*` 原色，别用 `colLayer*`。** `colLayer*` 跟随用户的透明度设置，
   卡片会透出底下终端的字（实测很难看）；上游的对话框组件也一律用不透明的 `m3*`。
3. **浮层要阴影。** `StyledRectangularShadow { target: <卡片> }` 做成兄弟节点 + `z` 排序
   （卡片 `z:1`）即可，不必像 `WallpaperSelectorContent` 那样外包一层 Item 留 `elevationMargin`。
   选择器自己没有阴影 → 垫一个同尺寸、透明的圆角 `Rectangle` 当阴影替身。

其余：变更摘要包成比卡片亮一档的 `m3surfaceContainerHighest` 内嵌卡片；`+N/−N` 做成胶囊 chip；
M/A/D 做成小色章；提示条没直接用 `NoticeBox`（它固定 `colPrimaryContainer`，在亮卡片上
几乎同色看不见，且 error 场景也不变红），改成按语义色 `ColorUtils.transparentize(accent, 0.88)` 染一层。

### 目标库切换（2026-10-08 第三轮）

弹框多了个 `listProc`（跑 `vault-commit list`，和 detect 并行）把全部库做成一行 chip；
`switchVault(key)` 是切换逻辑。两个模式行为**刻意不同**：

- **速记**：只换目标库，已写的标题原样留着（笔记标题跟写到哪个库无关）
- **提交**：重拉新库的 `status`，**清空已写的 message**（那条消息是给旧库的改动写的）

视觉：当前库 chip = `colPrimary` 淡底 + `check` 图标，非当前 = `m3onSurface` 淡底（都用
`ColorUtils.transparentize`，跟 StatChip 一套规矩）。`loading`/`busy` 时整行禁用
（RippleButton 的 `enabled=false` 自带 0.4 透明度）。`list` 失败静默 —— 切换行不出现，主流程照走。

### 双机并用：自动 rebase + 无 GUI 入口（2026-10-08 第四轮）

用户白天在 Fedora Workstation（GNOME）、晚上在 Arch，两台机器**并用**同一批库。
`apply` 的 push 被拒（响应里有 `non-fast-forward` / `fetch first` / `[rejected]`）时自动
`pull --rebase` 再重推一次 —— 两台轮流推的问题就无感了。三种落点：

| 情形 | 行为 |
|---|---|
| rebase 成功 | 直接重推，返回 `ok:true`（用户无感知） |
| rebase 冲突 | `rebase --abort` 保持干净，**本地提交原封不动**，返回 `stage:"conflict"` + 手动解决指引（`cd <库> && git pull --rebase`） |
| 拉取失败（断网等） | 返回 `stage:"pull"`，本地提交同样保住 |

配套：所有网络 git 操作走 `run_git_net`（`timeout 90` + `GIT_TERMINAL_PROMPT=0` +
ssh `BatchMode`），断网不会吊死弹框。

**无 GUI 机器的入口**：`interactive [<key>]`（提交）/ `capture-interactive [<key>]`（速记）。
rofi 优先、没有就 zenity（GNOME 自带）：`gui_ask` 收输入、`gui_pick` 选库。
GNOME 键位用系统设置的自定义快捷键，命令必须写**绝对路径**（GNOME 不展开 `~`）。

跨机套装（脚本 + 配置模板 + Claude 记忆 31 条）放在 private repo **`cynsm-workflow`**，
Fedora 落地步骤全在它的 README 里。

### 双机读路径 + 无 GUI 反馈 + 圆角（2026-10-08 第五轮）

**「顺手同步」——补上读路径。** 第四轮的自动 rebase 只解决了「推不用手动 pull」；反过来
「坐下来想看另一台昨晚写的东西」没有出口（干净库按 G 只报「没有需要提交的改动」）。现在：

- 脚本侧：`apply` 的「无改动」分支里，没有 upstream → 旧文案 `no-changes`；**不领先**
  （`@{u}..HEAD` = 0）→ 跑 `GIT_NET_TIMEOUT=30 pull --rebase`（网络操作统一走 `run_git_net`，
  超时改成可用环境变量调），按拉到几个提交回 `"…（远端也是最新的）"` / `"…已从另一台同步 N 个提交"`；
  拉取失败 → `stage:"pull"`。
- QML 侧：`onStatus` 见到 `clean && ahead===0` 不再进静态 clean，而是
  `syncOnly=true; applyMsg="（同步）"; phase="loading"; applyProc.running=true`；
  `onApplied` 里 `syncOnly` + `no-changes` → `cleanText` 写进 clean 提示条（不弹通知——
  弹框就在眼前）；`syncOnly` + `pull` 失败 → error 态 + critical 通知。`submit()` 正常路径
  重置 `syncOnly` 并把 `applyMsg` 设为清洗后的 message（**`applyProc.command` 改读 `applyMsg`**，
  不再直接读 `inputText`）。
- **陈旧结果守卫**：`onApplied` 开头 `if (!root.syncOnly && root.phase !== "busy") return;`
  —— Esc 关窗后进程还在飞，新会话不能被旧结果回写状态。

**无 GUI 机器的反馈（Fedora/GNOME）。** GNOME 自定义快捷键派生的进程 stdout 是**死的**，
zenity 弹完框成功失败都看不见 → 新增 `notify_result()`：`notify-send` 缺失静默跳过；
`pushed` → 「已提交并推送（hash）」；`no-changes` → 普通紧急度带文案；其余 → `-u critical`。
`interactive` 重写：也走 detect 链（窗口→obsidian.json→上次用的）、**干净时跳过 message 询问**
（内部传 `（同步）`，同样触发顺手同步）、捕获输出后通知；`capture-interactive` 同样加通知。
README 的 Fedora 包列表要加 `libnotify`。

**detect 链的空匹配 bug（真机也中招的那种）。** `detect_from_obsidian_json` 原名以
`jq -r … | head -1` 结尾 —— **没匹配时输出为空但退出码是 0**（head 的），`elif key="$(…)"`
就把它当成功 → 链条在「Obsidian 开着配置外的库」时**误停**，连 `state_get last` 兜底都到不了，
直接弹选择器。修法：捕获进变量、`[[ -n "$k" ]] || return 1` 再 printf。本机真实配置
（obsidian.json 的 open = SecondBrain，配置里有）不触发；测试环境的 open 库不在测试配置里，
第一次跑 QML harness 就撞上了 —— 属于「测试环境与真机状态不同才暴露的真 bug」。

**圆角：给弹框族设下限。** 用户反馈「第一眼像直角」。根因是外观参数化的 `scale≈0.28`
（方角预设）把 `rounding.normal` 缩到 ≈5px。加两个派生值：
`cardRadius: Math.max(Appearance.rounding.large, 16)`（主卡 + 选择器阴影替身 + SelectionDialog）、
`innerRadius: Math.max(Appearance.rounding.normal, 10)`（VaultNotice / 摘要卡）。预设本来就圆
（large ≥ 16）时完全跟随，不跟参数化打架。选择器行（`StyledRadioButton`）本来就是 `full` 胶囊，
不动。卡的角 16px、内层 10px、chip 胶囊 —— 层次刚好。

### 验证方法（本次用的）

```bash
# 脚本层先过 CLI（对着 /tmp/vc-test 的裸 remote-a.git 验过 commit + push 都到位）
vault-commit detect            # 焦点不在 Obsidian → ok:false + candidates
vault-commit status code       # {"ok":true,...,"clean":true,...}
vault-commit apply alpha "msg"

# QML 层：harness 必须放 ~/.config/quickshell/ii/ 里（导入要靠 qs.modules.*），用 -p 跑
VAULT_COMMIT_CONFIG=/tmp/vc-test/vaults.json qs -p ~/.config/quickshell/ii/vc-harness.qml
#   速记那条要先挡掉 xdg-open，否则会真把 obsidian:// 交给 Obsidian：
#   mkdir -p /tmp/vc-test/bin → 写个只 echo 的假 xdg-open → 跑时 PATH=/tmp/vc-test/bin:$PATH

# 截图时机：grim 要在 QML 里 execDetached 触发（外部 sleep 抓不准 qs 的 boot 耗时）
# 看截图别信全屏渲染，用 ImageMagick 量像素 + Read 读**裁剪图**

# 想一次看全所有状态：harness 里直接注入假状态（vc.status = {...}; vc.phase = "editing"）
#   比跑真流程快得多，也不用碰真库。
#   ⚠️ grim 比状态慢一拍：同一个 tick 里「改状态 + 截图」会拍到上一帧 —— 要么分两个 tick，
#   要么按「偏移一步」读图（第 N 张图里是第 N-1 步的状态）。

# 双机并用（第四轮）：/tmp/vc-test 里再 clone 一份 machine-b 模拟第二台（同一个 remote-a.git），
#   两边各改各的 → 自动 rebase 重推 ok:true；两边改同一文件 → stage:"conflict" 且本地提交还在
# 无 GUI 路径不用真弹 rofi：PATH 最前面塞个桩 rofi（bash 脚本，按 -p 的提示语 echo 固定答案）即可冒烟
#   ⚠️ 测试一律 XDG_STATE_HOME=/tmp/... 隔离 —— 否则会写脏真机的 ~/.local/state/vault-commit/last

# ⭐ 第五轮起改用的 QML harness 法（「vctest 镜像农场」，ii 目录零改动、快捷键零冲突、无还原步骤）：
#   ~/.config/quickshell/vctest/ 里：把 ii 顶层**全部符号链接**过来（shell.qml 除外）、
#   弹框用 sed 改造副本（WlrKeyboardFocus.Exclusive→None 不抢键盘；三个 GlobalShortcut 改名
#   vctest* 不与真 ii 抢注册）、自写 shell.qml 当驱动宿主（Connections 打 VCTEST-PHASE 日志，
#   Timer 里 openCommit/openCapture + 自动填 inputText + submit）。
#   跑法 `qs -c vctest`（**不是** -p：-c 按配置名选目录）。环境三件套：
#     VAULT_COMMIT_CONFIG=/tmp/vc-test/vaults.json XDG_STATE_HOME=/tmp/vc-test/state
#     PATH=/tmp/vc-test/stub-bin:$PATH   # notify-send 记账、hyprctl 直接 exit 1（保证确定性）、rofi 读 answer.txt
#   四个场景：A 干净+最新 → "（远端也是最新的）"；B machine-b 先推 → "已从另一台同步 1 个提交"（+工作区真更新）；
#   C 有改动 → editing → 自动提交 → done+hash；D 速记 → done+文件落地。
#   截图：grim -g "<焦点屏 x,y WxH>"；近景核对圆角用 Read 读裁剪图。
#   ⚠️ 改了驱动场景要**重跑 build 脚本**再 qs —— 忘了重建就白跑一轮（C 场景踩过）。
#   ⚠️ 老式的「harness 放 ii/ 里 + qs -p + sed 还原 Exclusive」已废弃。
```

### 诚实记录

- ~~没在真实快捷键上按过~~ → **2026-10-07 用户实机验收通过**（按了真键；提交 `768bc06 aa`
  已推到 GitHub，`git ls-remote` 实查一致）。真实库的 `apply` 就此跑通。
- 认库链**不要求 Obsidian 在前台**：`detect_from_window` 查 `hyprctl clients` 全部窗口
  （按 `focusHistoryID` 取最近用的那个）。一个 Obsidian 窗口都没有时才落到
  `obsidian.json`（最后打开的库）→ 选择器。实测：Obsidian 没开、焦点在 Zen，照样认出 SecondBrain。
- 测试期出过一次事故：IME harness 开着 `WlrKeyboardFocus.Exclusive`，把用户正在打的字
  吃进了测试输入框。副产品是**证实了 `Exclusive` 是真正的协议级 grab**——要抓输入就用它，
  但别拿它当「不抢键盘的探针」。
- 第四轮的另一笔教训来自测试自己：早期双机测试没隔离 `XDG_STATE_HOME`，把真机
  state 的 `last` 写成了测试 key `alpha`（真配置里没这个 key → 兜底链拿到坏 key）。
  已清掉。另外工具 shell 里 `set -e` 对 `&&` 链的**尾命令不生效**（测试脚本曾在 push
  被拒后照常往下跑，制造过一次假 `ok:true`）——测试脚本写显式检查，别依赖 `set -e`。
- 第五轮：`machine-b` **第二次**栽在「没先同步自己就推」（第一次是当天早上的 conflict 测试）——
  凡「制造撞车」的测试，流程固定为：第二台先 `git pull --rebase` → 改 → 推 → 第一台再动。
  另：QML 场景 C 第一轮白跑（改了驱动场景忘了重建 vctest 就启动），日志停在 editing 无提交，
  差点被当成功能 bug —— 跑 harness 前先确认农场是**本次**构建的。
- 第五轮的 detect bug 是拿测试环境撞出来的真 bug：测试 vaults.json 里没有「Obsidian 正开着的
  那个库」，链条才走了 `detect_from_obsidian_json` 的空匹配分支。真机配置恰好覆盖了这种情况，
  所以之前四轮都没暴露 —— 说明**测试环境与真机状态不同**本身就是有价值的探针。

---

## 13. Super+X 区域 OCR：中文支持 + 去汉字间空格

`SUPER+X` → `hl.dsp.global("quickshell:regionOcr")` → `RegionSelector` 框选 →
`ScreenshotAction.qml` 的 `CharRecognition` 分支 → `tesseract` → `wl-copy`。

### 「只支持英文」不是代码问题

上游那行本来就是**全语言**：`-l` 后面是
`$(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\n' '+' | …)` 拼出来的 ——
**装了什么语言就用什么**。本机 `/usr/share/tessdata/` 只有 `eng` + `osd`
（`tesseract-data-eng` 一个包），中文认不出是缺数据包，装完自动生效、不用改代码：

```bash
sudo pacman -S tesseract-data-chi_sim     # 繁体再补 tesseract-data-chi_tra
```

### 本地改：去掉汉字之间的空格（`ScreenshotAction.qml` 一处）

`chi_sim` 的输出会在每个汉字/中文标点之间插空格（`你 好 ， 世 界`），复制出去没法用。
在 `wl-copy` 前接一道 `perl`：**只在「CJK 字符 / 中文标点」相邻的位置删空白**，
中英之间的空格（`你好 Hello`）保留：

```
| perl -CSD -pe 's/(?<=[\x{3000}-\x{303F}\x{4E00}-\x{9FFF}\x{FF00}-\x{FFEF}])\s+(?=[\x{3000}-\x{303F}\x{4E00}-\x{9FFF}\x{FF00}-\x{FFEF}])//g'
```

⚠ QML 里这行在 JS 模板字符串内：`\x` / `\s` 必须写成 `\\x` / `\\s`
（和既有的 `tr '\\n'` 同理，写错 = 整个文件加载失败）。

### 验证方法（不装包就能先干跑）

```bash
# 造测试图：中文用 Noto Sans CJK SC，英文用 DejaVu Sans
magick -size 760x140 xc:white -font "Noto-Sans-CJK-SC" -pointsize 46 -fill black \
  -gravity center -annotate 0 "你好，世界 Hello 2026" /tmp/ocr-zh.png

# 预演：把 chi_sim.traineddata 放到 /tmp/tessroot/tessdata/ 里
# ⚠ TESSDATA_PREFIX 要指到「装着 *.traineddata 的那层目录本身」，指到父目录认不出
TESSDATA_PREFIX=/tmp/tessroot/tessdata tesseract /tmp/ocr-zh.png stdout -l eng+chi_sim
#   裸 tesseract →「你 好 ， 世 界 Hello 2026」；接上 perl →「你好，世界 Hello 2026」

# 整条命令按 QML 里 JS 解转义后的形态跑（wl-copy 换成 cat）；中/英/混排三张图都过
```

### 诚实记录

- 命令行本体（tesseract + perl 管道）三类测试图全过；**QML 侧没端到端跑过**
  （要真人按 Super+X 框选），改的只是一条命令字符串，`qmllint` 干净。
- `-l` 里带 `osd` 是上游行为（`--list-langs` 输出第二行）：实测不报错、不污染 stdout。

---

## 附：本地调试手法（改 ii 的 UI 时通用）

这几条与具体补丁无关，但每次改 UI 都会用到，记在这里省得重查。

**看真实日志 —— 不要靠终端里的输出。** Quickshell 每个实例的日志在：

```
/run/user/1000/quickshell/by-id/<id>/log.log
```

**首行写着 `Launching config: …`**，据此认出哪个是主 shell（`qs -c ii`）。
**目录堆得很多时**（跑过 harness 就会多一个），一条命令认全：

```bash
grep -h 'Launching config' /run/user/1000/quickshell/by-id/*/log.log | sort -u
# 主 shell 那行是 ".../ii/shell.qml"；harness 会写自己那个文件名
```

按时间过滤：`awk '$1 >= "2026-09-22" && $2 >= "02:00"'`。
终端里跑 `qs -c ii` 会开第二个实例，抢 IPC、抢 layer，别这么干。

**热重载**：改完 QML，主 shell 自己会重载；`qs -c ii ipc call <target> <fn>` 可以远程调函数
（左栏只有 `sidebarLeft.{toggle,close,open}`，**没有切页的 IPC**）。
**绝不要用 `pkill -f "qs -c ii"`** —— 它会匹配到执行这条命令的 shell 自己。
要杀就 `pgrep -x qs` / `pkill -x qs`。

**无干扰截图（测试用的 harness）必须放在 `~/.config/quickshell/ii/` 目录里面**，
否则 `qs.modules.*` 这类 import 解析不到。最小形态：

```qml
// ~/.config/quickshell/ii/xxx-harness.qml（用完删掉，别留在配置目录里）
import Quickshell
import Quickshell.Wayland
PanelWindow {
    screen: Quickshell.screens.find(s => s.name === "eDP-1")  // 副屏，不打扰主屏
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:pageTest"
    implicitWidth: 445; implicitHeight: 1000
    // …要测的页面
}
```

**`screen:` 不能直接写字符串 `"eDP-1"`** —— 会报
`Invalid property assignment: unsupported type "QuickshellScreenInfo*"`，
必须用上面那行 `Quickshell.screens.find(...)`。

启动：`qs -p /home/cynsm/.config/quickshell/ii/xxx-harness.qml`（`qs -c ii -p file` 会报
`--path excludes --config`）。**杀 harness 别用 `pkill -f`**（会匹配到执行命令的 shell 自己）：

```bash
for p in $(pgrep -x qs); do cmd=$(tr '\0' ' ' < /proc/$p/cmdline); case "$cmd" in *harness*) kill $p;; esac; done
```

eDP-1 的 scale 是 **1.6**。整页验证时套一层
`Item { width: X*0.55; height: Y*0.55; transform: Scale { xScale: 0.55; yScale: 0.55 } }`
缩放 —— 缩放后物理像素 = 逻辑 × 0.55 × 1.6 = 0.88。然后
`grim -o eDP-1 /tmp/shot.png`，用 PIL 裁切。

**像素级量尺寸**：取目标区域的**众数色**当背景（不要手挑参考像素 —— 很容易挑到被测物体上），
然后逐列找「第一个与背景差 > 24 的 y」。扫描窗口要把 tab 栏文字、底部说明文字排除掉，
否则它们会被当成图形的一部分。

**`hyprctl dispatch` 在本机必须走 `hl.dsp.*`。** Hyprland 用的是 Lua 配置，
`dispatch` 的参数会被包成 `hl.dispatch(<参数>)` 去求值 —— 裸写
`hyprctl dispatch focusmonitor eDP-1` 报 `')' expected near 'eDP'`，而且**静默不切焦点**：
信了它就会以为窗口开在副屏，其实开在用户正在用的主屏上（我因此把设置窗开错过一次）。写法：

```bash
hyprctl dispatch 'hl.dsp.focus({monitor = "HDMI-A-1"})'   # 返回 ok
hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'  # 开窗前断言
```

`movecursor(...)` 这类老 dispatcher 在 Lua 版里干脆不存在（读属性报 nil value）。

**在 scale=1 的屏幕上截窗口**：`hyprctl clients -j` 里的 `at` / `size` 就是物理像素，
所以 `grim -o HDMI-A-1 /tmp/x.png` 之后直接
`magick /tmp/x.png -crop WxH+X+Y +repage /tmp/x-crop.png`，不用换算
（只有 eDP-1 是 scale 1.6，才需要乘系数）。
