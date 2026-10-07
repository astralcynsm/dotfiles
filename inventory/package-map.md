# Arch → Fedora 44 包映射（人读版）

> **本表由 `mapping.toml` 生成，改 `mapping.toml` 为准。**
> 这里的每一行都能在 `mapping.toml` 里找到同名 `[[map]]` 条目；本文件只是它的分组表格视图。

**范围**：桌面核心 + 工具链。共 168 条。不含浏览器、IDE、影音播放器、游戏、KDE 全家桶、聊天工具等纯 GUI 应用
（CLI 工具的逐项勾选清单见 `cli-candidates.md`）。原机的完整包清单见 `packages-arch-explicit.txt`（609 个）
与 `packages-arch-aur.txt`（202 个）。

**核实方式**（2026-10-08 实测，不是回忆）：把 Fedora 44 官方仓库（releases/44 + updates/44，91607 个包名）、
RPM Fusion 44 free/nonfree（740 个包名）、以及各 COPR 的 `fedora-44-x86_64` 元数据拉下来逐名比对，
并从元数据里读出实际版本。「已核实」= 包名在元数据里出现过；「未核实」= 查不到，替代路径也没实测。

**状态含义**
- `已核实` —— 归宿确认，可直接进安装脚本
- `换名/替代` —— 要装的包名与 Arch 不同，或换了个工具顶上
- `未核实` —— 没找到官方包，替代路径（cargo/pipx/源码）也未实测，需要人工确认
- `不迁` —— 明确不要
- `受阻` —— 有明确障碍

**基础层复用**：`/home/cynsm/ricing/dots-hyprland/sdata/dist-fedora/feddeps.toml`（ii 上游维护的 Fedora 依赖表，
已按 audio/backlight/fonts/hyprland/python/illogical-impulse/quickshell/screencapture/toolkit/widgets 分组）已经
覆盖了大部分基础依赖，本表直接复用它并只记录**差异与增补**。上游那套的安装机制是：先 `dnf copr enable` 五个仓库
（ririko66z/dots-hyprland、sdegler/hyprland、deltacopy/darkly、alternateved/eza、atim/starship），
再从 GitHub `end-4/ii-package-builds` 的 `packages-fedora` release 下预编译 rpm 建本地仓库
（createrepo_c + `--repofrompath` + `--nogpgcheck`），最后 `dnf versionlock add quickshell-git`。

**三条与常见说法不一致的实测结论**（写进脚本前请留意）
1. **matugen 已有 Fedora 官方包**（F44 官方 3.1.0），不必走 COPR 或 cargo。
2. **darkman 已有 Fedora 官方包**（F44 官方 2.2.0），不必 Go 编译。
3. **eza 官方版比 COPR 还新**（官方 0.23.5 vs copr:alternateved/eza 0.23.4），feddeps 里那个 eza COPR 可以不加。

**刻意排除在范围外**（原机装了，但属纯 GUI / 游戏 / 虚拟化 / AI 客户端，未逐条映射）：
steam、lutris、gamescope、gamemode、mangohud、goverlay、wine-staging、protontricks、winetricks、
qemu-full、virt-manager、docker、miniconda3、jdk8/17/21、telegram/qq/feishu/wechat、obs-studio、gimp、
kdenlive、audacity、libreoffice、各种 KDE 应用、cherry-studio/typora/claude-code/openai-codex 等。
需要的话按原包名在 Fedora 官方/RPM Fusion 里再查一遍。

---


## 桌面核心

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `hyprland` | `hyprland` · COPR sdegler/hyprland · pin >=0.56.0 | 已核实 | Fedora 官方仓库没有 Hyprland。sdegler/hyprland 实测有 0.56.2-2.fc44，满足 ≥0.56（源机配置是 Lua 格式，0.56 移除了 hyprctl dispatch 字符串形式）。备选实测：ashbuk/Hyprland-Fedora 与 mineiro/hyprland 也都是 0.56.2。禁用 solopasha/hyprland（f44/f43 连 chroot 都没有，只剩 rawhide，停在 0.51.1）。jaques22/hyprland 实测只有 0.26.0（太旧，别用）；nightishaman/hyprland 仓库里根本没有 hyprland 包。 |
| `hyprland-guiutils` | `hyprland-guiutils` · COPR sdegler/hyprland | 已核实 | 官方无（feddeps.toml 也是从 COPR 拿）。sdegler/hyprland 与 mineiro/hyprland 都提供。 |
| `hyprland-qt-support` | `hyprland-qt-support` · COPR sdegler/hyprland | 已核实 | sdegler/hyprland 与 ririko66z/dots-hyprland 都提供（后者是 ii 上游指定的那一个）。 |
| `hyprlock` | `hyprlock` · COPR sdegler/hyprland | 已核实 | 实测 0.9.6-1.fc44。官方仓库没有。 |
| `hypridle` | `hypridle` · COPR sdegler/hyprland | 已核实 | 实测 0.1.8-1.fc44。官方仓库没有。 |
| `hyprpicker` | `hyprpicker` · COPR sdegler/hyprland | 已核实 | 官方无。取色器，ii 的取色功能依赖它。 |
| `hyprsunset` | `hyprsunset` · COPR sdegler/hyprland | 已核实 | 官方无（feddeps.toml 也从 COPR 拿）。 |
| `hyprpolkitagent` | `hyprpolkitagent` · COPR sdegler/hyprland | 已核实 | 实测 0.2.0-1.fc44。官方仓库没有。注意与 polkit-gnome 二选一，别两个都跑。 |
| `hyprshot` | `hyprshot` · COPR sdegler/hyprland | 已核实 | 实测 1.3.0-1.fc44。官方无。替代方案：grim + slurp + satty（三者都在官方/COPR 有）。 |
| `xdg-desktop-portal` | `xdg-desktop-portal` · Fedora 官方 | 已核实 | 官方有。ii 的 portal 组第一项。 |
| `xdg-desktop-portal-gtk` | `xdg-desktop-portal-gtk` · Fedora 官方 | 已核实 | 官方有。 |
| `xdg-desktop-portal-kde` | `xdg-desktop-portal-kde` · Fedora 官方 | 已核实 | 官方有。工作机保留 GDM/KDE 组件时用它；纯 Hyprland 会话可只留 gtk+hyprland 两个后端。 |
| `xdg-desktop-portal-hyprland` | `xdg-desktop-portal-hyprland` · COPR sdegler/hyprland | 已核实 | 必须走 COPR：F44 官方那个包被 orphan（FTI: nothing provides libsdbus-c++.so.1），2026-02-10 已关闭 WONTFIX。COPR 实测 1.4.1-1.fc44。屏共享靠它。 |
| `awww` | `swww` · COPR sdegler/hyprland | 换名/替代 | awww 是 swww 的继任分支（swww 已归档）。COPR 里只有 swww 0.11.2，没有 awww。配置键兼容但命令名不同，迁移时要么改用 swww，要么自行编译 awww。 |
| `uwsm` | `hyprland-uwsm` · COPR sdegler/hyprland | 已核实 | 可选。COPR 提供 hyprland-uwsm（以及 uwsm）。Fedora 上 Hyprland 会话要不要走 uwsm 需自行决定，不装也能起。 |
| `hyprland-plugins` | `hyprland-plugins` · COPR sdegler/hyprland | 已核实 | 可选。COPR 拆成 hyprland-plugin-<名字> 若干子包（hyprbars/hyprexpo/hyprscrolling 等），按需装。 |
| `grim` | `grim` · Fedora 官方 | 已核实 | 官方有。feddeps.toml 没列它，但它比 hyprshot 更底层，建议一起装。 |
| `slurp` | `slurp` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。 |
| `swappy` | `swappy` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。 |
| `satty` | `satty` · COPR sdegler/hyprland | 已核实 | 实测 0.20.0-2.fc44。官方无。截图标注用；与 swappy 二选一即可。 |
| `wf-recorder` | `wf-recorder` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。按帧查帧法验证动画时用的就是它。 |
| `wl-clipboard` | `wl-clipboard` · Fedora 官方 | 已核实 | 官方有。wl-copy/wl-paste，ii 脚本大量引用。 |
| `cliphist` | `cliphist` · Fedora 官方 | 已核实 | 官方有（实测在 F44，COPR 里也有）。剪贴板历史。 |
| `wl-clip-persist` | —（无对应包） · cargo | 未核实 | 未核实：F44 官方与 RPM Fusion 都没有这个包名。可用 cargo install wl-clip-persist 或从源码构建。是否真需要它取决于剪贴板持久化要求。 |
| `wtype` | `wtype` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。 |
| `ydotool` | `ydotool` · Fedora 官方 | 已核实 | 官方有。装上还要起 ydotoold 服务并给 /dev/uinput 权限，否则注入静默失败（注意：ydotool 注入会骗你说「没问题」，验证时别只靠它）。 |
| `waybar` | `waybar` · Fedora 官方 | 已核实 | 官方有 0.15.0。但 ii 用 quickshell 自带 bar，waybar 是旧配置遗留 —— 建议 drop。真要留，COPR sdegler/hyprland 里那份带 git 补丁。 |
| `fuzzel` | `fuzzel` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。 |
| `wlogout` | `wlogout` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。注销菜单。 |
| `rofi` | `rofi` · Fedora 官方 | 已核实 | 官方有。老 waybar 配置时代的遗留，ii 用 quickshell 自己的启动器，可 drop。 |
| `swaync` | `SwayNotificationCenter` · Fedora 官方 | 换名/替代 | 包名不同：Fedora 官方叫 SwayNotificationCenter。ii 自带通知中心，可 drop。 |
| `nwg-displays` | `wdisplays` · Fedora 官方 | 换名/替代 | F44 官方没有 nwg-displays（官方只有 nwg-bar/nwg-dock/nwg-drawer/nwg-launchers/nwg-panel/nwg-wrapper）。ii 的显示设置页会调 nwg-displays，这是真实缺口：替代品 wdisplays / kanshi / wlr-randr 官方都有。建议先按 wdisplays 顶上，缺的功能再补。 |
| `nwg-look` | `nwg-look` · COPR sdegler/hyprland | 已核实 | 官方无。COPR 里有。GTK 设置 GUI。 |
| `illogical-impulse-quickshell-git` | `quickshell-git` · COPR ririko66z/dots-hyprland · pin versionlock | 已核实 | 走 ii 上游的 Fedora 路径：ririko66z/dots-hyprland COPR 提供 quickshell-git（实测 0.2.1^713.git26531fc-1.fc44），配合 GitHub end-4/ii-package-builds 的 packages-fedora release（createrepo_c 建本地仓库）+ dnf versionlock。安装脚本见 sdata/dist-fedora/install-deps.sh。补充事实：F44 官方现在也有 quickshell（0.2.1^git20260209），avengemedia/danklinux 有 0.3.1，但 ii 固定版本是有原因的，别乱换。 |


## 主题链

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `matugen` | `matugen` · Fedora 官方 | 已核实 | 「matugen 无官方包」这条前提已经过期：实测 F44 官方仓库有 matugen 3.1.0-1.fc44（F43/F45 也有）。因此直接官方装，不必 copr:avengemedia/danklinux（那边是 4.2.0）也不必 cargo。若要跟 ii 的上游版本一致，再用 COPR（sdegler/hyprland 是 3.0.0）。 |
| `darkman` | `darkman` · Fedora 官方 | 已核实 | 「darkman 无官方包、需 Go 编译」这条前提也已过期：实测 F44 官方有 darkman 2.2.0-5.fc44（F43/F45 也有）。直接 dnf install 即可。真正的坑不在装包，而在钩子：脚本只认执行位（chmod -x 才停用，改名 .disabled 没用）。 |
| `adw-gtk-theme-git` | `adw-gtk3-theme` · Fedora 官方 | 换名/替代 | 包名不同（Fedora: adw-gtk3-theme），官方有（feddeps.toml 也列了）。Arch 侧是 -git。 |
| `kvantum` | `kvantum` · Fedora 官方 | 已核实 | 官方有（kvantum / kvantum-qt5 都在）。但实测它不跟配色方案走 —— 别指望它接管主题。 |
| `qt5ct` | `qt5ct` · Fedora 官方 | 已核实 | 官方有。注意本机上 qt5ct/qt6ct 是「死配置」——真正生效的是 GTK 平台主题，见 qt6gtk2 那条。 |
| `qt6ct` | `qt6ct` · Fedora 官方 | 已核实 | 官方有（COPR sdegler/hyprland 里也有）。同上：QT_QPA_PLATFORMTHEME 才是关键。 |
| `qt6gtk2` | `qadwaitadecorations-qt5`, `qt6-qtwayland-adwaita-decoration` · Fedora 官方 | 换名/替代 | Fedora 不打包 qt6gtk2（Arch AUR 的 Qt6 GTK2 平台主题）。官方等价物是 qadwaitadecorations-qt5 与 qt6-qtwayland-adwaita-decoration（两者实测都在 F44 官方）。目标一样：让 Qt 应用跟 GTK 明暗走。 |
| `qt5-styleplugins` | `qadwaitadecorations-qt5` · Fedora 官方 | 换名/替代 | AUR 的 Qt5 GTK2 风格插件，官方无对应包名；用 qadwaitadecorations-qt5 顶上。 |
| `gtk-engine-murrine` | `gtk-murrine-engine` · Fedora 官方 | 换名/替代 | 包名不同：Fedora 叫 gtk-murrine-engine，官方有。 |
| `darkly` | `darkly` · COPR deltacopy/darkly | 已核实 | 官方无。实测 deltacopy/darkly 有 0.5.40 的 f44 构建（feddeps.toml 指定的就是这个 COPR）。 |
| `breeze-plus` | `breeze-plus-icon-theme` · COPR ririko66z/dots-hyprland | 已核实 | 官方无源码包；ririko66z/dots-hyprland COPR 提供 breeze-plus-icon-theme（feddeps.toml 也指向它）。breeze-gtk / breeze-icon-theme / breeze-cursor-theme 本身在官方，可另装。 |
| `bibata-cursor-theme` | `bibata-cursor-theme` · COPR ririko66z/dots-hyprland | 已核实 | 实测 2.0.7-6.fc44，来自 ririko66z/dots-hyprland。官方仓库没有（feddeps.toml 的 cursor_themes 组也是指它）。 |
| `python-pywal` | —（无对应包） | 不迁 | 已被 matugen 取代。F44 官方没有 python3-pywal / pywal。真要用则 pipx install pywal。 |
| `wallust` | —（无对应包） · cargo | 未核实 | 未核实：官方无此包。wallust 已不是主力（现在走 matugen），可 drop；要留则 cargo install wallust。 |


## 输入法

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `fcitx5` | `fcitx5`, `fcitx5-autostart` · Fedora 官方 | 已核实 | 官方有（含 fcitx5-autostart，别忘它，否则开机不自启）。 |
| `fcitx5-rime` | `fcitx5-rime` · Fedora 官方 | 已核实 | 官方有。 |
| `fcitx5-chinese-addons` | `fcitx5-chinese-addons` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 未列，源机装了）。 |
| `fcitx5-configtool` | `fcitx5-configtool` · Fedora 官方 | 已核实 | 官方有（KDE 下另可选 kcm-fcitx5）。 |
| `fcitx5-gtk` | `fcitx5-gtk` · Fedora 官方 | 已核实 | 官方有（另有 fcitx5-gtk2/3/4 子包）。 |
| `fcitx5-qt` | `fcitx5-qt` · Fedora 官方 | 已核实 | 官方有（fcitx5-qt5 / fcitx5-qt6 子包）。Arch 侧是依赖带入，源机没显式装，但 Fedora 上建议显式装，否则 Qt 应用（含 quickshell）进不了输入法。QT_IM_MODULE 只给需要的服务开。 |
| `fcitx5-mozc` | `fcitx5-mozc` · Fedora 官方 | 已核实 | 官方有。 |
| `librime` | `librime` · Fedora 官方 | 已核实 | 官方有（另有 librime-devel）。 |
| `brise` | `brise` · Fedora 官方 | 已核实 | 官方有（Rime 数据/方案包）。 |
| `translate-shell` | `translate-shell` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。命令是 trans，ii 翻译页的引擎。 |
| `fcitx5-material-color` | —（无对应包） | 未核实 | 未核实：官方无 fcitx5-material-color（也没有 fcitx5-theme-material）。F44 官方 fcitx5 相关包里没有任何主题包。只能手装 theme.conf + SVG。 |
| `fcitx5-skin-fluentdark-git` | —（无对应包） | 未核实 | 未核实：官方无。AUR 皮肤；本机是靠 SVG 9-patch 圆角方案做的，迁移时把那套 SVG 与 theme.conf 直接搬过去，别找包。同族的 fluentlight-git、fcitx5-nord 同理。 |


## 字体

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `noto-fonts-cjk` | `google-noto-sans-cjk-fonts`, `google-noto-serif-cjk-fonts` · Fedora 官方 | 换名/替代 | Fedora 把 CJK 拆成 sans/serif 两个包（另有 -vf 可变字重版）。官方有。feddeps.toml 没列，但中文字型必须有。 |
| `noto-fonts` | `google-noto-sans-fonts`, `google-noto-fonts-common` · Fedora 官方 | 换名/替代 | 包名不同（Fedora 前缀 google-）。官方有。 |
| `noto-fonts-emoji` | `google-noto-emoji-fonts` · Fedora 官方 | 换名/替代 | 官方有（另有 google-noto-color-emoji-fonts，是 Fedora 的默认 emoji 字体）。 |
| `noto-fonts-extra` | `google-noto-fonts-all` · Fedora 官方 | 换名/替代 | 官方有 google-noto-fonts-all（全家桶，很大，按需）。 |
| `wqy-microhei` | `wqy-microhei-fonts` · Fedora 官方 | 换名/替代 | 包名后缀 -fonts，官方有。 |
| `wqy-zenhei` | `wqy-zenhei-fonts` · Fedora 官方 | 换名/替代 | 包名后缀 -fonts，官方有。 |
| `ttf-sarasa-gothic` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：F44 官方与 RPM Fusion 都没有 sarasa 相关包名。需从 GitHub (be5invis/Sarasa-Gothic) 下载 ttc 放 ~/.local/share/fonts。 |
| `ttf-lxgw-wenkai` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无 lxgw-wenkai 独立包（只有 texlive-lxgw-fonts，那是 TeX 集合里附带的）。从 GitHub (lxgw/LxgwWenKai) 下载，或退而用 texlive-lxgw-fonts。同族的 ttf-lxgw-neo-xihei-screen 同理。 |
| `ttf-harmonyos-sans` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无。需自行下载安装（或放弃，用 Noto Sans CJK 顶）。 |
| `otf-smiley-sans-bin` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无。GitHub 下载（atelier-anchor/smiley-sans）。 |
| `ttf-ms-fonts` | —（无对应包） | 未核实 | 未核实：官方无（版权原因）。mscore-fonts 是 MuseScore 的谱面字体，不是 MS 字体，别搞错。要用就自己从 Windows 拷，或找第三方源。 |
| `ttf-ibm-plex-sans-sc` | `ibm-plex-fonts-all` · Fedora 官方 | 未核实 | 官方有 ibm-plex-fonts-all / ibm-plex-sans-fonts，但是否含 SC（简中）子集未核实 —— 装完用 fc-list 确认再补。 |
| `maplemono-ttf` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无。GitHub (subframe7536/maple-font) 下载。 |
| `nerd-fonts-sf-mono` | `jetbrains-mono-nerd-fonts` · COPR ririko66z/dots-hyprland | 换名/替代 | Fedora 官方没有任何 nerd-fonts 包（只有 texlive-inconsolata-nerd-font 这种附带品）。ririko66z/dots-hyprland 提供 jetbrains-mono-nerd-fonts（实测 3.4.0-1.fc44，ii 用它）。源机那 20 来个 ttf-*-nerd 只能从 nerdfonts.com 批量下载，或自己打包。 |
| `ttf-firacode-nerd` | `fira-code-fonts` · Fedora 官方 | 换名/替代 | 官方有 fira-code-fonts（非 Nerd 版，没有图标字形）。要图标字形仍需 nerdfonts.com 的补丁版。 |
| `otf-font-awesome` | `fontawesome-fonts-all`, `fontawesome-6-free-fonts` · Fedora 官方 | 换名/替代 | 官方有（包名前缀 fontawesome-）。 |
| `terminus-font` | `terminus-fonts` · Fedora 官方 | 换名/替代 | 包名后缀 -fonts，官方有。 |
| `inter-font` | `rsms-inter-fonts` · Fedora 官方 | 换名/替代 | 包名不同：Fedora 叫 rsms-inter-fonts（按上游作者命名），官方有。 |
| `ttc-iosevka-ss14` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无 iosevka 相关包名。GitHub/nerdfonts 下载。 |
| `ttf-google-sans-code-nf` | `google-sans-flex-vf-fonts` · COPR ririko66z/dots-hyprland | 换名/替代 | 官方无 Google Sans 系列。ririko66z/dots-hyprland 提供 google-sans-flex-vf-fonts（feddeps.toml 指定）。Nerd 版（-nf）只能自己下。 |
| `google-material-symbols-vf-rounded-fonts` | `google-material-symbols-vf-rounded-fonts` · COPR ririko66z/dots-hyprland | 已核实 | 官方无；ririko66z/dots-hyprland 有这一族（实测含 -rounded/-outlined/-sharp 变体）。ii 图标字体，必须有。 |
| `google-rubik-vf-fonts` | `google-rubik-vf-fonts` · COPR ririko66z/dots-hyprland | 已核实 | 官方无（官方只有非 vf 的 google-rubik-fonts）；COPR 有。feddeps.toml 指定的就是它。 |
| `readex-pro-fonts-all` | `readex-pro-fonts-all` · COPR ririko66z/dots-hyprland | 已核实 | 官方无；COPR 有（feddeps.toml 指定）。 |
| `florian-karsten-space-grotesk-fonts` | `florian-karsten-space-grotesk-fonts` · COPR ririko66z/dots-hyprland | 已核实 | 官方无；COPR 有（feddeps.toml 指定）。 |


## 终端与 CLI

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `ghostty` | `ghostty` · COPR scottames/ghostty | 已核实 | 工作机指定的终端。F44 官方没有 ghostty。实测两个 COPR 都提供 1.3.1 的 f44 构建：scottames/ghostty（社区文档普遍推荐）与 avengemedia/danklinux（同一个仓库里还有 matugen 4.2.0 和 quickshell 0.3.1，一个仓库能顶三样）。 |
| `foot` | —（无对应包） | 不迁 | 不迁：工作机用 ghostty。（Fedora 官方其实有 foot，真要用直接装。） |
| `kitty` | `kitty` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了；ii 的 Fedora 文档里还用它跑 nmtui）。 |
| `zsh` | `zsh` · Fedora 官方 | 已核实 | 官方有。 |
| `zsh-autosuggestions` | `zsh-autosuggestions` · Fedora 官方 | 已核实 | 官方有。 |
| `zsh-syntax-highlighting` | `zsh-syntax-highlighting` · Fedora 官方 | 已核实 | 官方有。 |
| `zsh-fast-syntax-highlighting-git` | `zsh-syntax-highlighting` · Fedora 官方 | 换名/替代 | AUR 的快速高亮（C 实现）；Fedora 只有常规版，性能差异无所谓，直接用官方的。 |
| `zsh-theme-powerlevel10k-bin-git` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无 powerlevel10k 包。git clone 到 ~/.local/share 走 zshrc 即可（不需要包管理器）。 |
| `zplug` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无 zplug。zsh 插件管理器，git clone 安装；或改用官方打包的那几个插件直接 source。 |
| `starship` | `starship` · COPR atim/starship | 已核实 | F44 官方没有 starship。实测 atim/starship 有 1.24.2 的 f44 构建（feddeps.toml 指定的就是这个 COPR）。也可 cargo install。 |
| `eza` | `eza` · Fedora 官方 | 已核实 | 官方有，而且是 0.23.5 —— 比 feddeps.toml 里那个 copr:alternateved/eza（实测 0.23.4）还新。所以「官方版本旧、要用 COPR」这条已不成立，直接装官方。 |
| `bat` | `bat` · Fedora 官方 | 已核实 | 官方有。 |
| `ripgrep` | `ripgrep` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。 |
| `jq` | `jq` · Fedora 官方 | 已核实 | 官方有（feddeps.toml basic 组）。ii 脚本里出现 66 处。 |
| `yq` | `yq` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了，安装脚本第一步就是装它）。 |
| `bc` | `bc` · Fedora 官方 | 已核实 | 官方有（feddeps.toml basic 组）。ii 计算器功能依赖。 |
| `rsync` | `rsync` · Fedora 官方 | 已核实 | 官方有（feddeps.toml basic 组）。Obsidian 双库同步脚本依赖。 |
| `curl` | `curl` · Fedora 官方 | 已核实 | 官方有（feddeps.toml basic 组）。 |
| `ImageMagick` | `ImageMagick` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。注意 Fedora 包名大写 M，命令是 magick。ii 脚本里 30 处引用。 |
| `fastfetch` | `fastfetch` · Fedora 官方 | 已核实 | 官方有。 |
| `btop` | `btop` · Fedora 官方 | 已核实 | 官方有。 |
| `duf` | `duf` · Fedora 官方 | 已核实 | 官方有。 |
| `zoxide` | `zoxide` · Fedora 官方 | 已核实 | 官方有。 |
| `uv` | `uv` · Fedora 官方 | 已核实 | 官方有（feddeps.toml python 组也列了）。 |
| `tree-sitter-cli` | `tree-sitter-cli` · Fedora 官方 | 已核实 | 官方有。 |
| `pandoc-bin` | `pandoc-cli`, `pandoc-common` · Fedora 官方 | 换名/替代 | Fedora 3.x 把 pandoc 拆成 pandoc-cli / pandoc-common / pandoc-pdf 三个包（没有叫 pandoc 的包，注意）。要 PDF 支持再装 pandoc-pdf。 |
| `socat` | `socat` · Fedora 官方 | 已核实 | 官方有。ii 脚本里用到（2 处）。 |
| `yt-dlp` | `yt-dlp` · Fedora 官方 | 已核实 | 官方有。 |
| `rclone` | `rclone` · Fedora 官方 | 已核实 | 官方有。 |
| `aria2` | `aria2` · Fedora 官方 | 已核实 | 官方有。 |
| `perl-image-exiftool` | `perl-Image-ExifTool` · Fedora 官方 | 换名/替代 | 包名不同：Fedora 叫 perl-Image-ExifTool，官方有。 |
| `tesseract-data-chi_sim` | `tesseract-langpack-chi_sim`, `tesseract-langpack-eng` · Fedora 官方 | 换名/替代 | 命名不同：Fedora 是 tesseract-langpack-<lang>（feddeps.toml 也这么写）。区域 OCR 的汉字间空格补丁（LOCAL-PATCHES §13）与语言包无关，照搬即可。 |
| `strace` | `strace` · Fedora 官方 | 已核实 | 官方有。排障要用的那群（strace/valgrind/pv/stress-ng/iotop 等）官方基本都有。 |


## 硬件与系统

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `nvidia-open-dkms` | `akmod-nvidia-open` · RPM Fusion | 换名/替代 | RPM Fusion 有 akmod-nvidia-open（也有 akmod-nvidia，非 open 版）。实测两者都在 RPM Fusion 44 的包列表里。别忘 mokutil 注册 akmods 签名密钥，否则 Secure Boot 下起不来。 |
| `nvidia-settings` | `nvidia-settings` · RPM Fusion | 已核实 | 实测在 RPM Fusion 44（不在 Fedora 官方）。 |
| `nvidia-prime` | `xorg-x11-drv-nvidia-libs`, `nvidia-modprobe` · RPM Fusion | 换名/替代 | Arch 的 nvidia-prime 是个调度脚本，RPM Fusion 无同名包。用环境变量法（__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia）或自写 prime-run 包装脚本。 |
| `libva-nvidia-driver` | `libva-nvidia-driver` · Fedora 官方 | 已核实 | 官方有（NVDEC 硬解，浏览器/视频用）。 |
| `v4l2loopback-dkms` | `akmod-v4l2loopback` · RPM Fusion | 换名/替代 | RPM Fusion 有 akmod-v4l2loopback。虚拟摄像头（qq/会议软件用）。 |
| `intel-media-driver` | `intel-media-driver` · Fedora 官方 | 已核实 | 官方有（Intel iGPU 硬解）。 |
| `intel-ucode` | `microcode_ctl` · Fedora 官方 | 换名/替代 | 包名不同：Fedora 的 CPU 微码包叫 microcode_ctl（官方有），覆盖 Intel/AMD。 |
| `intel-undervolt` | —（无对应包） | 不迁 | 不迁：官方无此包，且降压属于高风险调优，工作机上不做。 |
| `thermald` | `thermald` · Fedora 官方 | 已核实 | 官方有（Intel 热管理）。 |
| `power-profiles-daemon` | `power-profiles-daemon` · Fedora 官方 | 已核实 | 官方有。注意与 tuned 二选一（Fedora 默认装 tuned，装 ppd 前先确认谁来管，别打架）。 |
| `zram-generator` | `zram-generator` · Fedora 官方 | 已核实 | 官方有 1.2.1。Fedora 上 zram 默认就开着（zram-generator-defaults），配置文件放 /etc/systemd/zram-generator.conf。 |
| `scx-scheds` | `scx_layered`, `scx_rusty` · Fedora 官方 | 换名/替代 | Fedora 官方不叫 scx-scheds，而是按调度器拆包：scx_layered / scx_rusty / scx_rustland / scx_c_schedulers（实测四个都在 F44）。按需挑一个，配 scx_loader 或手写 unit。 |
| `cpupower` | `kernel-tools` · Fedora 官方 | 换名/替代 | cpupower 与 turbostat 都在 Fedora 的 kernel-tools 包里，没有同名独立包。 |
| `msr-tools` | `msr-tools` · Fedora 官方 | 已核实 | 官方有。 |
| `haveged` | `haveged` · Fedora 官方 | 已核实 | 官方有。 |
| `nbfc-linux` | —（无对应包） | 不迁 | 不迁：Fedora 官方与 RPM Fusion 都没有 nbfc。若工作机风扇控制真的需要，只能源码构建，代价大、收益小。 |
| `bluez` | `bluez`, `bluez-utils` · Fedora 官方 | 已核实 | 官方有（bluez / bluez-utils 同名）。 |
| `NetworkManager` | `NetworkManager`, `NetworkManager-wifi`, `network-manager-applet` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 也列了）。ii 网络页 + nmcli（脚本里也用到）。 |
| `timeshift` | `timeshift` · Fedora 官方 | 已核实 | 官方有（意外之喜：Fedora 官方确实有 timeshift）。 |


## 脚本依赖（ii 运行时）

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `upower` | `upower` · Fedora 官方 | 已核实 | 官方有（feddeps.toml toolkit 组）。ii 脚本 19 处引用。 |
| `playerctl` | `playerctl` · Fedora 官方 | 已核实 | 官方有（feddeps.toml audio 组）。 |
| `cava` | `cava` · Fedora 官方 | 已核实 | 官方有（feddeps.toml audio 组）。ii 音频可视化。 |
| `pavucontrol` | `pavucontrol` · Fedora 官方 | 已核实 | 官方有（feddeps.toml audio 组）。 |
| `wireplumber` | `wireplumber` · Fedora 官方 | 已核实 | 官方有（feddeps.toml audio 组）。 |
| `brightnessctl` | `brightnessctl` · Fedora 官方 | 已核实 | 官方有（feddeps.toml backlight 组）。ii 脚本 14 处引用。 |
| `ddcutil` | `ddcutil` · Fedora 官方 | 已核实 | 官方有（feddeps.toml backlight 组）。外接显示器亮度。 |
| `geoclue2` | `geoclue2` · Fedora 官方 | 已核实 | 官方有（feddeps.toml backlight 组）。明暗自动切换需要它。 |
| `gammastep` | `gammastep` · Fedora 官方 | 已核实 | 官方有（feddeps.toml 没列，但 ii 夜间色温用它）。 |
| `qalculate-gtk` | `qalculate-gtk` · Fedora 官方 | 已核实 | 官方有 qalculate-gtk 与 qalculate（feddeps.toml widgets 组写的是 qalculate）。ii 计算器页面调它。 |
| `songrec` | `songrec` · COPR ririko66z/dots-hyprland | 已核实 | 官方无；ririko66z/dots-hyprland 提供（feddeps.toml widgets 组）。听歌识曲。 |
| `mpvpaper` | `mpvpaper` · COPR sdegler/hyprland | 已核实 | 官方无；COPR 有（feddeps.toml extra 组）。视频壁纸。 |
| `microtex` | `microtex` · COPR ririko66z/dots-hyprland | 已核实 | 官方无；COPR 有（feddeps.toml microtex 组）。LaTeX 渲染。 |


## Arch 专属 / 需替代或丢弃

| Arch 包 | Fedora 归宿 | 状态 | 备注 |
|---|---|---|---|
| `paru` | `dnf` · Fedora 官方 | 换名/替代 | AUR 助手无对应物。Fedora 侧靠 dnf + COPR（dnf copr enable）。官方还提供 dnf5。 |
| `yay` | `dnf` · Fedora 官方 | 换名/替代 | 同上。源机 paru + yay 都装了，工作机不需要这类工具。 |
| `pacman-contrib` | `dnf-utils` · Fedora 官方 | 换名/替代 | checkupdates → dnf check-update；paccache 之类无对应。dnf-utils 实测在 F44 官方。 |
| `downgrade` | `dnf` · Fedora 官方 | 换名/替代 | 用 dnf history undo / dnf downgrade，无需额外包。 |
| `rebuild-detector` | `dnf-utils` · Fedora 官方 | 换名/替代 | 「哪些包需要重启」用 needs-restarting -r（dnf-utils 提供）。 |
| `reflector` | —（无对应包） | 不迁 | 不迁：Fedora 的镜像选择由 dnf fastestmirror 插件（默认开）负责，没有等价工具。 |
| `pkgfile` | `dnf-utils` · Fedora 官方 | 换名/替代 | 「哪个包提供某文件」用 dnf provides /usr/bin/xxx。想自动提示就装 PackageKit-command-not-found。 |
| `archlinux-xdg-menu` | —（无对应包） | 不迁 | 不迁：Arch 专用脚本，Fedora 的 xdg 菜单由 .desktop 文件 + xdg-utils 处理。 |
| `lsb-release` | —（无对应包） | 不迁 | 不迁：F44 官方无 lsb-release / redhat-lsb-core。脚本里若判断发行版，改用 /etc/os-release。 |
| `endeavouros-branding` | —（无对应包） | 不迁 | EndeavourOS 全家桶（endeavouros-branding / -keyring / -mirrorlist / eos-apps-info / eos-hooks / eos-log-tool / eos-packagelist / eos-quickstart / eos-rankmirrors / welcome / nvidia-inst）一律不迁，纯发行版专属。 |
| `greetd` | —（无对应包） | 不迁 | 不迁：工作机保留 GDM。greetd / greetd-tuigreet / nwg-hello 都不装。（Fedora 官方其实有 greetd，但既然保留 GDM 就不碰 —— 而且 greetd 的 command 里绝不能再写 exec，那是开机黑屏的坑。） |
| `linux-zen` | `kernel` · Fedora 官方 | 换名/替代 | Fedora 官方无 zen 内核，用默认 kernel（Fedora 内核本身已偏桌面向）。要自编内核才谈得上等价。linux / linux-headers 同理 → kernel / kernel-devel / kernel-headers。 |
| `xorg-server` | —（无对应包） | 不迁 | 不迁：整套 X.Org（xorg-server / xinit / xrandr / xinput / xkill / xdpyinfo / xeyes / xcursorgen / xclip / xterm 等）在 Wayland 会话下不需要。少数脚本若还调 xrandr，改用 wlr-randr（官方有）。 |
| `lib32-glibc` | —（无对应包） | 换名/替代 | Fedora 不提供 lib32-* 这一族包名。32 位依赖由 RPM Fusion 的 steam 等包自动带 i686 依赖，其余 lib32-* 全部 drop。 |
| `claude-code` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实 Fedora 有无打包。官方推荐装法是 npm i -g @anthropic-ai/claude-code 或官方安装脚本（Fedora 上需要 nodejs，官方提供 nodejs22/nodejs24）。 |
| `openai-codex` | —（无对应包） · 源码/上游脚本 | 未核实 | 未核实：官方无。按上游给的 npm/二进制方式装。 |
| `mihomo-party-git` | `clash-meta` · Fedora 官方 | 换名/替代 | GUI 代理客户端 Fedora 无对应包（走 Flatpak 或 AppImage）。但内核有替代：Fedora 官方有 clash-meta。源机四个客户端（clash-verge-rev-bin / mihomo-party-git / flclash-bin / clash-verge-rev）功能重叠，工作机上留一个就行。 |
| `greetd-tuigreet` | —（无对应包） | 不迁 | 不迁（见 greetd 那条）。 |
| `linux-firmware` | `linux-firmware`, `alsa-sof-firmware`, `alsa-firmware`, `b43-fwcutter` · Fedora 官方 | 换名/替代 | Fedora 固件拆得细：linux-firmware 主包 + alsa-sof-firmware（声卡 DSP）+ alsa-firmware + b43-fwcutter（b43 需要自己下固件）。实测这几个都在官方。 |
