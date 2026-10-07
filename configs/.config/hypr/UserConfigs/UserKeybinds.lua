-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- This is where you put your own keybinds. Be Mindful to check as well ~/.config/hypr/configs/Keybinds.conf to avoid conflict
-- if you think I should replace the Pre-defined Keybinds in ~/.config/hypr/configs/Keybinds.conf , submit an issue or let me know in DC and present me a valid reason as to why, such as conflicting with global shortcuts, etc etc
--
-- 由 UserConfigs/UserKeybinds.conf 转换为 lua (Hyprland >= 0.55)
-- bindr -> { release = true }; bindl -> { locked = true }; binde -> { repeating = true }
-- bindel -> { locked = true, repeating = true }; bindln -> { locked = true, non_consuming = true }

-- See https://wiki.hyprland.org/Configuring/Keywords/ for more settings and variables
-- See also Laptops.conf for laptops keybinds

-- /* ---- ✴️ Variables ✴️ ---- */  --
local mainMod = "SUPER"
local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"
local UserScripts = os.getenv("HOME") .. "/.config/hypr/UserScripts"
local UserConfigs = os.getenv("HOME") .. "/.config/hypr/UserConfigs"

-- settings for User defaults apps - set your default terminal and file manager on this file
require("UserConfigs/01-UserDefaults")

-- common shortcuts
-- hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -modi drun,filebrowser,run,window"), { release = true }) -- Super Key to Launch rofi menu
-- [ii 迁移] 原为 rofi 主菜单（pkill rofi || rofi -show drun -modi ...）。
-- 改道到 ii 的搜索面板，和「单按 Super」共用同一个界面 —— 这样两者天然同款，
-- 不用去维护一条「把 rofi 主题改成跟 ii 一样」的脆弱链路。
--
-- ii 搜索的能力其实覆盖了原来 rofi 的 drun/run/window/calc：
--   > app   / action   ; 剪贴板   : emoji   = 计算器   $ shell   ? 网页搜索
-- 缺的只有 rofi 的 filebrowser 和 window 切换（这两件 FileManager/Overview 另有所属）。
--
-- rofi 本身没废：SUPER+SHIFT+M（音乐）、SUPER+SHIFT+K（键位查询）、
-- SUPER+CTRL+SHIFT+R（主题选择器）还在调它，配色已改由 matugen 供给。
-- [2026-09-20] 这里必须用 searchToggle（按下触发），不能用 searchToggleRelease（松手触发）。
-- 原因：Hyprland 只在「修饰键仍然按着」时才认为组合键结束、才把 release 事件发给 quickshell。
-- 而人的习惯是先松 Alt 再松 Space，Alt 一松 modmask 就从 8 掉到 0，bind 当场不再匹配，
-- release 事件永远发不出去 —— 表现为「按了完全没反应」（空格也不会漏进应用，因为按下那刻已被消费）。
-- 改成按下触发后与松键顺序彻底无关，且没有等松手的迟滞。
-- 注意：Super 单按那条仍然走 Release 路径（见本文件末尾），它需要区分「单按 Super」和「Super+别键」，不能动。
hl.bind("ALT + SPACE", hl.dsp.global("quickshell:searchToggle"), { description = "应用搜索（ii 搜索面板）" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("xdg-open \"https://\"")) -- default browser
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pkill rofi || true && ags -t 'overview'")) -- desktop overview (if installed)
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:overviewWorkspacesToggle")) -- [ii 迁移] 原名 overviewToggle 已废弃，改为新版事件名
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(term)) --terminal
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd(files))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("foot --app-id=yazi-float yazi"))
hl.bind(mainMod .. " + SHIFT + CTRL + E", hl.dsp.exec_cmd(file_manager))
hl.bind("CTRL + ALT + D", hl.dsp.exec_cmd("obsidian"))

-- FEATURES / EXTRAS
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh")) -- help / cheat sheet

-- hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh")) -- Refresh waybar, swaync, rofi
hl.bind(mainMod .. " + ALT + R", hl.dsp.global("quickshell:overlayToggle")) -- [ii 迁移] 小工具悬浮层（原 Refresh.sh 刷新的 waybar 要废弃、swaync 没在用）
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh")) -- emoji menu
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh")) -- Google search using rofi
hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh")) -- Toggle blur settings
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh")) -- Toggle animations ON/OFF
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh")) -- Toggle Master or Dwindle Layout
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh")) -- Clipboard Manager
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(scriptsDir .. "/RofiThemeSelector.sh")) -- KooL Rofi Menu Theme Selector
hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh")) -- modified Rofi Theme Selector

-- hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen()) -- whole full screen
-- hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized" })) -- fake full screen
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat")) --All Float Mode
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(scriptsDir .. "/Dropterminal.sh " .. term)) -- Dropdown terminal

-- Desktop zooming or magnifier
hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.exec_cmd([[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')"]]))
hl.bind(mainMod .. " + ALT + mouse_up", hl.dsp.exec_cmd([[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')"]]))

-- ## NOTES for ja (Hyprland version 0.39 (Ubuntu 24.04))
-- hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.exec_cmd([[hyprctl keyword misc:cursor_zoom_factor "$(hyprctl getoption misc:cursor_zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')"]]))
-- hl.bind(mainMod .. " + ALT + mouse_up", hl.dsp.exec_cmd([[hyprctl keyword misc:cursor_zoom_factor "$(hyprctl getoption misc:cursor_zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')"]]))

-- Waybar / Bar related
hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar")) -- Toggle hide/show waybar
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh")) -- Waybar Styles Menu
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh")) -- Waybar Layout Menu

-- FEATURES / EXTRAS (UserScripts)
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(UserScripts .. "/RofiBeats.sh")) -- online music using rofi
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperSelect.sh")) -- Select wallpaper to apply
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperEffects.sh")) -- Wallpaper Effects by imagemagick
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperRandom.sh")) -- Random wallpapers
hl.bind(mainMod .. " + CTRL + O", hl.dsp.exec_cmd("hyprctl setprop active opaque toggle")) -- disable opacity on active window
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh")) -- search keybinds via rofi
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh")) --hyprland animations menu
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(UserScripts .. "/ZshChangeTheme.sh")) -- Change oh-my-zsh theme
-- hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"), { locked = true, non_consuming = true }) -- Change keyboard layout globally
-- hl.bind("SHIFT_L + ALT_L", hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"), { locked = true, non_consuming = true }) -- Change keyboard layout locally for each window
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(UserScripts .. "/RofiCalc.sh")) -- calculator (qalculate)

-- Move current workspaces to monitors (left right up or down)
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.workspace.move({ monitor = "l" })) --move current workspace to LEFT monitor
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.workspace.move({ monitor = "r" })) --move current workspace to RIGHT monitor
-- hl.bind(mainMod .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" })) --move current workspace to UP monitor
-- hl.bind(mainMod .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" })) --move current workspace to DOWN monitor


-- ###################
-- ### KEYBINDINGS ###
-- ###################

-- See https://wiki.hypr.land/Configuring/Keywords/
-- Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more
hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle

-- Move focus with mainMod + arrow keys + vim keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))

hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))

hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))

hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
-- hl.bind(mainMod .. " + Tab", hl.dsp.window.cycle_next())
-- hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
-- Switch workspaces with mainMod + [0-9]




-- Move active window to a workspace with mainMod + SHIFT + [0-9]
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and draging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Screenshot
-- [ii 迁移] 原来是 `grim -g "$(slurp)" - | wl-copy` —— 只进剪贴板，
-- 不落盘、不通知、不能标注，复制下一次就被顶掉。改接 ii 的 RegionSelector：
--   · 左键拖选 → 裁图 + 存到 ~/Pictures/Screenshots + 复制到剪贴板
--   · 右键拖选 → 同一张图直接丢给 satty 标注（箭头/文字/马赛克/裁剪）
-- 选区界面是 ii 原生的，配色和圆角跟着 matugen 走，无需额外维护。
-- 注：存盘路径和 satty 开关在 ~/.config/illogical-impulse/config.json
--     （screenSnip.savePath / regionSelector.annotation.useSatty）。
hl.bind("CTRL + ALT + A", hl.dsp.global("quickshell:regionScreenshot"), { description = "截图：框选（左键存+复制 / 右键标注）" })
-- 框选取字：tesseract 识别后进剪贴板
hl.bind(mainMod .. " + X", hl.dsp.global("quickshell:regionOcr"), { description = "截图：框选取字（OCR）" }) -- [ii 迁移]
-- 框选录屏（再按一次停止）
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { description = "截图：框选录屏" }) -- [ii 迁移]
-- 未绑定、留给你决定的：quickshell:regionSearch —— 框选后传到 uguu.se 再走
-- Google Lens 搜图，好用但会把截图上传到第三方图床，是否启用你自己定。
-- hl.bind("CTRL + ALT + SHIFT + A", hl.dsp.exec_cmd([[grim -g "$(hyprctl activewindow | grep 'at:' | cut -d' ' -f3) $(hyprctl activewindow | grep 'size:' | cut -d' ' -f2 | sed 's/,/x/')" - | wl-copy]]))

-- open applications
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"))
-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("CTRL + ALT + right", hl.dsp.exec_cmd("playerctl --player=fooyin next"), { locked = true })
hl.bind("CTRL + ALT + left", hl.dsp.exec_cmd("playerctl --player=fooyin previous"), { locked = true })
hl.bind("CTRL + ALT + up", hl.dsp.exec_cmd("playerctl --player=fooyin volume 0.05+"), { locked = true, repeating = true })
hl.bind("CTRL + ALT + down", hl.dsp.exec_cmd("playerctl --player=fooyin volume 0.05-"), { locked = true, repeating = true })
hl.bind("CTRL + ALT + M", hl.dsp.exec_cmd("playerctl --player=fooyin play-pause"), { locked = true })
-- For passthrough keyboard into a VM
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
-- hl.define_submap("passthru", function()
-- to unbind
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))
-- end)

-- #############################################
-- ### ii / illogical-impulse (quickshell) 键位 ###
-- #############################################
-- [ii 迁移] 全部落在原本空闲的键上，你既有的绑定一个未动。
-- 未绑的 ii 功能及原因：
--   mediaControlsToggle → 你说不需要媒体控制键
--   oskToggle           → 你说不需要屏幕键盘
--   sessionToggle       → CTRL+ALT+Del 被你的 exit Hyprland 占着
--   barToggle           → SUPER+J 被 KooL 的 cyclenext 占着
--   sidebarLeftToggle 的 SUPER+B → 被你的浏览器占着（改由 SUPER+O 承担）

hl.bind(mainMod .. " + SUPER_L", hl.dsp.global("quickshell:searchToggleRelease"),
    { description = "Shell: 搜索" })
-- [ii 迁移] 单按 Super 弹搜索，但"按住 Super 期间按了别的键"就不该弹。
-- ii 为这件事专门留了 searchToggleReleaseInterrupt（Overview.qml:190），
-- 可它**在上游 keybinds.lua 里也从没被绑定过**（grep 只命中 searchToggleRelease），
-- 所以这个冲突只能自己接。
--
-- 冲突现场：fcitx5 的 [Hotkey/TriggerKeys] 正是 Super+space（切输入法），
-- 而这条 SUPER+SUPER_L 绑定会在松 Super 时把搜索面板一起带出来。
--
-- non_consuming 是关键：Super+SPACE 要既不弹搜索、又继续往下传给应用，
-- fcitx5 才收得到这一击（否则键被 Hyprland 吞掉，输入法根本切不了）。
-- 原理：本绑定在 Space 按下时把 GlobalStates.superReleaseMightTrigger 置 false，
-- 于是松 Super 时 searchToggleRelease.onReleased 会直接 return，不再 toggle。
hl.bind(mainMod .. " + SPACE", hl.dsp.global("quickshell:searchToggleReleaseInterrupt"),
    { non_consuming = true, description = "Shell: 取消单按 Super 的搜索" })
hl.bind(mainMod .. " + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"),
    { description = "Shell: 工作区总览" })
hl.bind(mainMod .. " + Period", hl.dsp.global("quickshell:overviewEmojiToggle"),
    { description = "Shell: Emoji 面板" })
hl.bind(mainMod .. " + ALT + N", hl.dsp.global("quickshell:overviewClipboardToggle"),
    { description = "Shell: 剪贴板总览" })
hl.bind(mainMod .. " + O", hl.dsp.global("quickshell:sidebarLeftToggle"),
    { description = "Shell: 左侧栏（翻译）" })
hl.bind(mainMod .. " + ALT + A", hl.dsp.global("quickshell:sidebarLeftToggleDetach"),
    { description = "Shell: 左侧栏弹出为独立窗口" })
hl.bind(mainMod .. " + N", hl.dsp.global("quickshell:sidebarRightToggle"),
    { description = "Shell: 右侧栏（快捷开关/通知）" })
hl.bind(mainMod .. " + Slash", hl.dsp.global("quickshell:cheatsheetToggle"),
    { description = "Shell: 快捷键速查表" })
hl.bind("SHIFT + SUPER + ALT + Slash", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/ii/welcome.qml"),
    { description = "Shell: 欢迎 / 设置向导" })

-- ### 主题切换器 ###
-- 手动切深色/浅色。切完会记一个时间戳，让按上海日出日落自动切换的逻辑
-- 在本个半天周期内不覆盖你的选择（下个日出/日落后自动逻辑重新接管）。
-- 自动逻辑由 systemd user timer 驱动：theme-auto-mode.timer
-- 见 ~/.config/theme-switcher/README.md
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/theme-switcher/toggle-mode.sh"),
    { description = "主题: 切换深色/浅色（自动按上海日出日落）" })

-- ### 笔记：Obsidian 库 → GitHub ###
-- 一个键提交当前库：自动识别当前打开的是哪个库（认不出就弹选择器），
-- 弹框里看变更摘要、手写 commit message、回车 = add -A + commit + push。
-- 速记那个键新建一篇「<日期> - <你填的标题>.md」并直接在 Obsidian 里打开。
-- git 逻辑全在 ~/.local/bin/vault-commit（可单独在终端跑），配置在
-- ~/.config/vault-commit/vaults.json。弹框坏掉时的兜底：vault-commit interactive
hl.bind(mainMod .. " + ALT + G", hl.dsp.global("quickshell:vaultCommitOpen"),
    { description = "笔记: 提交并推送到 GitHub" })
hl.bind(mainMod .. " + ALT + S", hl.dsp.global("quickshell:vaultCaptureOpen"),
    { description = "笔记: 速记（新建带日期的笔记）" })
