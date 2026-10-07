-- Kanagawa Dark —— 由 theme-switcher 管理
-- ⚠ 改这个文件不生效（下次切主题会被覆盖）
--    要改请改 ~/.config/theme-switcher/assets/kanagawa-dark/hypr.colors.lua

hl.config({
    general = {
        col = {
            active_border   = "rgba(e5c28399)",  -- carpYellow
            inactive_border = "rgba(2a2a3733)",  -- sumiInk2
        },
    },
    misc = {
        background_color = "rgba(1f1f28FF)",     -- sumiInk1
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba(e5c283AA) rgba(e5c28377)",
})

-- 与 matugen 版保持完全相同的变量名，
-- 这样引用方（UserDecorations.lua）无需感知主题类型。
themePrimary    = "rgba(e5c283FF)"  -- carpYellow  —— 强调/边框/阴影
themePrimaryDim = "rgba(d7a657FF)"  -- autumnYellow
themeOutline    = "rgba(727169FF)"  -- comment —— 弱化元素
themeSurface    = "rgba(1f1f28FF)"  -- sumiInk1
themeOnSurface  = "rgba(ddd8bbFF)"  -- fujiWhite
