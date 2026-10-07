# 主题框架（Theme / Skin 系统）—— 设计方案

> 状态：**计划中**，2026-09-23 定稿，2026-09-24 开工。
> 实施完的每一步都要回头更新本文档 + `LOCAL-PATCHES.md`，别让两份记录分叉。

## 为什么做这个

现在的「外观自定义」（LOCAL-PATCHES §11）只能改**参数**：圆角、字号、尺寸、动画、两个字面开关。
它改变了观感的**程度**，但改变不了观感的**语言** —— 无论怎么调，ii 还是 ii。

用户要的是**成套的风格**：一套主题 = 一整套视觉语言，一键切换。首批点名了五套：
死亡搁浅 / 赛博朋克 2077 / 僵尸毁灭工程（僵毁）/ Undertale / 天国拯救（KCD），之后还会继续加。

**框架的核心 KPI 不是「DS 做得像」，而是「新增第六套主题要便宜」。**
如果加一套主题要复制整套 UI，那这个框架就失败了。

## 现状盘点：已有的三套机制各自管什么

**不要在框架里重造这三样，要接管它们。**

| 机制 | 位置 | 管什么 | 在框架里的角色 |
|---|---|---|---|
| theme-switcher 静态主题 | `~/.config/theme-switcher/{themes,assets}/` | **配色**（写 `colors.json` 等资产）。`COMPONENT_MAP` 已含 `colors.json`，所以静态主题现在能管到 ii 的 UI | 主题包的**配色提供者**之一（`colors.mode: static`） |
| appearance-presets | `~/.config/illogical-impulse/appearance-presets/*.json` | **形状**：圆角/字号/尺寸/动画/描边/字距/图标填充 | 主题包的**形状片段**（直接内联进 `theme.json`） |
| matugen + MaterialThemeLoader | 壁纸 → `~/.local/state/quickshell/user/generated/colors.json` → `Appearance.m3colors`（`watchChanges`，外部改写即热生效） | 随壁纸动的**配色** | `colors.mode: wallpaper`（现状，不动它） |
| darkman 钩子 | `~/.config/darkman/{dark,light}-mode.d/20-quickshell-ii.sh` | 日出日落切明暗 | 已加「当前是 static 主题则跳过 ii 配色」的判断，框架沿用 |

## 框架设计

### 1. 目录与 manifest

**主题包全部放用户数据目录**（`Directories.shellConfig` = `~/.config/illogical-impulse`）：
上游 `--delete` 同步 QML 目录时不会碰它们，也方便分享/备份。

```
~/.config/illogical-impulse/themes/
  _base/                     # 基底：所有主题继承它，只写差异
    theme.json
  death-stranding/
    theme.json               # 清单（唯一必需文件）
    colors.json              # mode: static 时的色卡（键名同 matugen 模板）
    fonts/                   # 该主题需要的字体（FontLoader 加载）
    textures/                # 底纹/切角 9-patch/角标 SVG
    overrides/               # 可选：排布级覆盖（见第 4 节）
      bar/BarContent.qml
      ...
  cyberpunk-2077/
  zomboid/
  undertale/
  kcd/
```

`theme.json` 结构（**除 `name` 外全部可省，省略即继承 `_base`**）：

```jsonc
{
  "name": "死亡搁浅",
  "extends": "_base",
  "description": "…（给设置页显示）",

  "colors": { "mode": "static", "file": "colors.json" },
  // mode: static        → 用自带 colors.json（不随壁纸动）
  //       wallpaper     → 纯 matugen（现状行为）
  //       wallpaper-tinted → matugen 派生后按下面 tint 规则映射（随壁纸动 + 保主题色）

  "tint": {                    // 仅 wallpaper-tinted 用
    "lockHue": true,           // 主色相锁到 primaryHue
    "primaryHue": 30,          // 琥珀橙
    "saturation": [0.35, 0.85],// 饱和度压到这个区间
    "valueCurve": 0.9          // 明度曲线的指数
  },

  "shapes": {                  // 直接吃 appearance-preset 那套键，逐字相同
    "rounding.scale": 0,
    "rounding.full": 3,
    "rounding.windowRounding": 0,
    "animation.scale": 0.6,
    "animation.curveStyle": "standard",
    "letterSpacing": 0.5,
    "panelOutline": true,
    "iconFillAll": false
  },

  "skin": {                    // 视觉语言（新增，见第 3 节）
    "fontFamily": "mono",      // 覆盖 Appearance.font.family.main
    "forceUppercase": true,    // 仅对拉丁字母有效 —— 中文标签不受影响，见「坑 3」
    "forceLanguage": "en",     // 可选：主题强制界面语言（HUD 感需要英文时）
    "cornerMarks": "L",        // none | L | tick
    "cornerCut": 0,            // px，切角（0 = 不切）
    "borderStyle": "line",     // line | double | none
    "texture": "contour",      // none | contour | scanline | paper | grain | grid
    "textureOpacity": 0.18,
    "textureTint": "primary",
    "iconStyle": "symbol",     // symbol | outline | label | pixel
    "labelCase": "upper",
    "typewriterText": false,   // 文字逐字显现（Undertale）
    "sounds": {}               // 可选：{"click": "…wav", "confirm": "…"}
  }
}
```

### 2. 三层能力，按深度分开做

| 层 | 做什么 | 挂点 | 成本 |
|---|---|---|---|
| **① 视觉语言**（换皮） | 字体/大小写/字距/边框策略/角标/切角/底纹/图标策略 | 少数渲染原语 + 一个装饰器组件 | 中，一次投入全 UI 受益 |
| **② 排布**（重构） | bar 变 HUD、overview 变环形菜单、通知变「送货单」 | `overrides/` 里逐面板替换实现 | 每个面板几百行 |
| **③ 交互**（未来） | 键鼠语义、音效 | — | 先不做，仅预留 `sounds` |

**关键论据（已实测，见 §11 坑 5）**：让**所有**面板换描边，实际只改了 **2 个文件**。
ii 的视觉原语高度集中：

| 原语 | 覆盖 |
|---|---|
| `modules/common/widgets/StyledText.qml` | 325 处实例 / 136 文件 —— 全部文字 |
| `modules/common/widgets/MaterialSymbol.qml` | 全部图标（带 FILL 轴） |
| `Appearance.colors.colLayer*` / `colLayer0Border` | 所有面板底色与边框 |
| `modules/common/widgets/StyledRectangularShadow.qml` | 27 个文件的阴影 |
| `bar/StyledPopup.qml` 等外壳系 | 几乎所有面板外框 |

所以①层**不需要碰 136 个文件**，改 5~8 个原语即可全局生效。

### 3. 新增的引擎部件

**`modules/common/Skin.qml`**（qml Singleton，照 `Appearance.qml` 的路子）：
读当前主题的 `theme.json` → 暴露 `Skin.fontFamily` / `Skin.texture` / `Skin.cornerMarks` …
默认值 = 现状（`texture: none`、`forceUppercase: false`…），保证**不选主题时零变化**。

**`modules/common/widgets/SkinDecor.qml`**（装饰器）：给任意面板加装饰，一条挂载搞定：

```qml
SkinDecor {                       // 挂在面板外壳里，anchors.fill
    cornerMarks: Skin.cornerMarks
    cornerCut: Skin.cornerCut
    texture: Skin.texture
}
```

内部实现要点：
- **切角**用 **SVG 9-patch + `BorderImage`**（fcitx5 主题那套经验直接复用），不要用 `Shape`/`PathClip` —— 后者在 panel 上重复构建会掉帧
- **底纹**用预生成 PNG + `Image { fillMode: Image.Tile }`，**不要用 shader、更不要碰 Hyprland 的 `screen_shader`**（全局单值，会跟 anti-flashbang 抢，§11 已否决过）
- 角标是 4 个 L 形线的 `Rectangle` 组合，跟着 `Appearance.colors.colOnLayer*` 走

**`services/ThemeColors.qml`**（配色变换层）：插在 matugen 与 `Appearance` 之间。
现在链路是 `MaterialThemeLoader.applyColors()` 直接写 `Appearance.m3colors`；
改成写进 ThemeColors → 按 `theme.tint` 规则变换 → 再写 `Appearance.m3colors`。
`wallpaper-tinted` 模式靠它，`static`/`wallpaper` 模式下它是透传（零变化）。

**`modules/common/ThemeRegistry.qml`**（主题枚举 + 切换）：
照 `services/AppearancePresets.qml` 的路子（`Process` + `ls`），扫描 `themes/*/theme.json`；
`applyTheme(name)` 做四件事：① 应用 colors（调 `switchwall.sh` 或写 `colors.json`）
② 写 `shapes` 到 Config（复用 `AppearancePresets.applyValues()`）
③ 写当前主题名到一个 Config 键（`appearance.theme`）供 Skin 读
④ 若主题带 `overrides/`，通知 Loader 换实现。

**`scripts/themes/new-theme.sh <name>`**（脚手架，决定 KPI 的那件工具）：
生成目录骨架 + **从当前 Config 快照 `shapes`** + 拷一份 `_base/theme.json` 模板。
「调满意了存下来」这个能力顺手就有了（§11 里挂账的「另存为 preset」在主题层一并解决）。

### 4. 排布覆盖（②层）

每个面板一个 QML 文件，由 Loader 按主题选实现：

```qml
Loader {
    source: ThemeRegistry.overrideFor("bar/BarContent.qml")
            ?? "modules/ii/bar/BarContent.qml"     // 主题没覆盖就用上游
}
```

**契约（写覆盖实现时的硬约束）**：
- 数据只从 `services/` 单例取（`Battery` / `MprisController` / `Workspaces` / `Notifications` …），
  不直接读 `/sys`、不自己起 `Process`
- 只吃 `Appearance` 与 `Skin` 的 token，不写死颜色/字号
- 对外暴露的属性与上游同名（`BarContent` 的 `screen` / `bar` 等），否则调用方会炸

先做**一个**面板验证契约（建议 `bar`，最显眼；或 `overview`，最能体现风格差异）。

### 5. 切换入口

- **设置页**：Appearance 页顶部加「主题」段（列出 `themes/` + 当前主题名 + 「新建主题」按钮）
  —— 替换现在那个只有 preset 的 Presets 段
- **快捷键**：不占新键。`SUPER+CTRL+SHIFT+R` 现在是 rofi 主题选择器（KooL 遗留），
  可改道给 ThemeRegistry 的下一个主题；或把 `SUPER+SHIFT+R` 那类空转键给「切到下一个主题」
- **与明暗联动**：`static` 配色主题要沿用 §11 坑 8 的做法（darkman 钩子读 `theme-switcher/current`），
  或改成读 `appearance.theme` 更直接

## 首批五套主题的设计语言

每套主题的价值在**设计语言**，不在色号。下面每行都是框架「参数面」要能表达的东西 ——
写不出来说明框架缺参数。

| | 死亡搁浅 | 赛博朋克 2077 | 僵毁 | Undertale | 天国拯救 |
|---|---|---|---|---|---|
| 底 | 近纯黑 | 深蓝黑 | 脏绿灰 | **纯黑** | **羊皮纸浅色**（唯一浅色主题） |
| 强调 | 琥珀橙 `#E8842C` + 青 | 品牌黄 `#FCEE0A` + 青/洋红 | 锈褐 + 警示橙 | 纯白 + 红心 | 血红 + 棕 |
| 字 | 等宽、宽字距、大写标签 | 技术感等宽（Rajdhani/OCR-A 味） | 打字机/衬线 | **像素字体**（Determination Mono 味） | 衬线/哥特 |
| 形 | 直角、1px 线框、四角 L 标 | **斜切角**、粗边、硬阴影 | 方角、磨损边 | 8bit 直角、双线框 | 细线 + 装饰分隔 |
| 底纹 | 等高线/地形 | **扫描线** + 故障感 | 纸纹 + 污渍 | 无（纯色块） | 木刻/蜡封 |
| 特殊 | HUD 数字带刻度 | 「警告条」黄底黑字 | 生存指标式状态条 | 对话框 + ▼ 提示 + 打字机文字 | 纹章式图标 |
| 排布（②层，可选） | 递送单式列表 | 终端式日志 | 物品栏式网格 | 对话框取代面板 | 抄本式分栏 |

**注意 KCD 是浅色主题** —— 框架必须支持 `light` 主题（沿现有 darkman 机制），
不能假设所有主题都是暗色。这条要是漏了，第五套主题就做不出来。

## 阶段路线图

**阶段 0（明天，最小可见验证）**
1. `themes/` 目录 + `_base/theme.json` + `death-stranding/theme.json`
2. `Skin.qml` Singleton（全默认值 = 零变化）
3. 两个原语钩子：`StyledText`（字体族/字距/大写）、`SkinDecor.qml`（角标 + 底纹）
4. 挂到 **`sidebarLeft`** 验证（已拍板：最稳妥的试点，不动 bar）
5. `scripts/themes/new-theme.sh` 脚手架
6. **判据**：切到 DS → 出现宽字距 + 角标 + 等高线底纹；切回默认 → **逐像素回到原样**（零残留）

**阶段 1**：装饰能力补全（切角 9-patch、扫描线、纸纹、像素边框）+ 五套主题各出一版 `theme.json`
（配色/字体/形状三件，**不做排布**）→ 此时「一键换风格」已经成立

**阶段 2**：`ThemeColors.qml` 的 `wallpaper-tinted` 模式（随壁纸动 + 保主题色相）

**阶段 3**：排布覆盖机制 + 一个面板的替代实现（②层）

**阶段 4**：设置页主题段 + 快捷键改道 + 与 darkman/theme-switcher 收口

**阶段 5**：主题包导出/分享（可选）；音效（可选）

## 风险与已知坑

1. **漏水点会在强风格下集体显形**（§11 坑 3/2）：78 处写死的 `font.pixelSize`、25 处 `radius: height/2`、
   散落的内联尺寸。DS 那种强对比会立刻暴露它们。**阶段 0 就要定策略**：哪些保留原样、
   哪些进皮肤（建议：只收拾"一眼看得见"的，其余记进本文档的已知限制）。
2. **底纹不要走 `screen_shader`**（Hyprland 全局单值，与 anti-flashbang 冲突，§11 已否决）。
   一律 QML 纹理。
3. **全大写字距对中文无效** —— 界面是中文的，`font.capitalization` 只作用于拉丁字母。
   DS/2077 那种 HUD 感要么靠 `letterSpacing`（对中文有效），要么主题带
   `forceLanguage: "en"` + 一份英文标签表（主题包里放 `translations/en_US.json`，走已有的用户翻译机制）。
4. **上游同步**：主题包全在 `~/.config/illogical-impulse/`（用户数据，安全）；
   `Skin.qml`/`SkinDecor.qml`/`ThemeRegistry.qml` 在 ii 目录里，属上游文件，**必须记进 `LOCAL-PATCHES.md` §12**。
5. **性能**：底纹是每帧合成的成本，180fps 之下要量。纹理优先、避免 shader、避免每面板独立大图。
6. **字体来源与授权**：已拍板「允许自带、不限来源」→ 放 `themes/<name>/fonts/`，
   用 `FontLoader` 加载（QtQuick 支持），或装进系统字体目录。
   仍要注意：**每个主题都要保证"字体缺失时能优雅退化"**（回退到 `_base` 的字体），
   否则别人拿走你的主题包会变成一堆豆腐块。
7. **主题 vs 换壁纸**：`static` 配色主题下换壁纸，配色不跟着变（这正是主题的意义）；
   如果你要"换壁纸也换色"，那就是 `wallpaper` / `wallpaper-tinted` 模式。**每个主题各自声明**。

## 已拍板（2026-09-23）

1. ✅ **主题可以自带字体文件**（不限来源，Nerd Font 也可以）——
   Undertale 的像素字体、2077 的技术字体、KCD 的衬线体都按自带处理。
2. ✅ **主题可以绑定语言**（`forceLanguage`，如 DS 用英文）。
3. ✅ **阶段 0 试点面板 = `sidebarLeft`**（选最稳妥的：改动面小、不动日常最依赖的 bar；
   观感验证通过后再推 bar / overview）。

**这三条决定额外打开的几个口子**（阶段 1 用得上）：

- **图标策略从"大工程"降级为"换字体 + 映射表"**：`iconStyle: "pixel" | "outline"` 的实现路径 =
  在 `MaterialSymbol.qml` 上换 `font.family`（换成主题自带的 Nerd Font 或像素图标字体），
  再加一张**字形映射表**（Material Symbols 用连字 `"add"`，Nerd Font 用码点 `""`，
  所以需要 `{"add": "", …}` 这样一份表）。
  主题包里放 `icons.json` + `fonts/*.ttf` 即可，不用逐个组件改图标。
- **`forceLanguage` 的实现**：主题目录内自带 `translations/<locale>.json`，
  在 `services/Translation.qml` 里**再加一个 `TranslationReader`**，路径指向当前主题目录
  （现有两个 reader：内置的 + `Directories.shellConfig/translations`；查找式是
  `tr[key] || generated[key] || key`，内置仍然优先 —— 所以主题要覆盖中文标签，
  要么走 `forceLanguage: "en"` 绕开中文表，要么接受"只补缺口"）。
  切换主题时同时把 Config 的语言设置切过去。
- **Nerd Font 替换图标字体有一个副作用要量**：Nerd Font 字形在 14px 以下容易糊，
  bar 上的小图标首当其冲 —— 阶段 1 验收时拿 bar 量一次再决定要不要给 `pixel` 单独放大图标尺寸。

## 附：本次已确认的既有事实（省得重查）

- `StyledText` 325 处 / 136 文件；`MaterialSymbol` 带 FILL 轴；`StyledRectangularShadow` 27 文件
- `panelOutline` 实测只需改 2 个文件（外壳集中度高）
- `Directories.shellConfig` = `~/.config/illogical-impulse`（不是 QML 目录）
- `appearance-presets/` 现有 7 套；`theme-switcher/assets/` 现有 8 套静态主题（含 DS）
- matugen 链路：`switchwall.sh` → `generated/colors.json` → `MaterialThemeLoader`（热生效）
- 静态主题与 darkman 的冲突已在钩子里处理（§11 坑 8）
