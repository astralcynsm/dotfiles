-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --

-- This is a file where you put your own default apps, default search Engine etc

-- Set your default editor here uncomment and reboot to take effect.
-- NOTE, this will be automatically uncommented if you select neovim or vim to your default editor
hl.env("EDITOR", "nvim") --default editor

-- Define preferred text editor for the KooL Quick Settings Menu (SUPER SHIFT E)
-- script will take the default EDITOR and nano as fallback
-- 注意: 以下变量定义为全局(不带 local), 对应 hyprlang 中 $变量 的全局语义,
--       供 UserConfigs/UserKeybinds.lua 及 Waybar 模块使用。
edit = os.getenv("EDITOR") or "nano"

-- These two are for UserKeybinds.conf & Waybar Modules
-- 注意: 已调整定义顺序(term 先于 files), 因为 files 需要引用 term 的值
term = "foot" -- Terminal
files = term .. " -e yazi" -- File Manager
-- [2026-09-20] pcmanfm-qt → dolphin
-- 原因: pcmanfm-qt 拖拽必崩 —— libfm-qt 的 FolderViewListView 在
--       QDrag::exec() 返回后寄存器被写坏（8/09 起 34 次 core 栈逐帧一致，
--       9/11 双方同时升级重编后照崩），而拖拽恰是换掉 yazi 的理由。
-- 为什么 Dolphin 可以: 只多 2 个包（15+ 个 KF6 库早被其它 KDE 应用拖进来了），
--       且实测走 Breeze + KF6ColorScheme，会读 matugen 生成的
--       MaterialYouDark/Light 配色方案，跟壁纸和明暗一起变，不污染主题链路。
-- 范围: 只改 SUPER+SHIFT+CTRL+E 的目标。SUPER+CTRL+E / SUPER+E 的 yazi 绑定不动。
file_manager = "dolphin"

-- Default Search Engine for ROFI Search (SUPER S)
Search_Engine = "https://www.google.com/search?q={}"
