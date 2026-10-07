-- Gruvbox Dark —— 由 theme-switcher 管理
-- ⚠ 改这个文件不生效（下次切主题会被覆盖）
--    要改请改 ~/.config/theme-switcher/assets/gruvbox-dark/hypr.colors.lua

hl.config({
    general = {
        col = {
            active_border   = "rgba(fabd2f99)",  -- bright yellow
            inactive_border = "rgba(50494555)",  -- bg2
        },
    },
    misc = {
        background_color = "rgba(282828FF)",     -- bg0
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba(fabd2fAA) rgba(fabd2f77)",
})

-- 与 matugen 版保持完全相同的变量名，
-- 这样引用方（UserDecorations.lua）无需感知主题类型。
themePrimary    = "rgba(fabd2fFF)"  -- bright yellow —— 强调/边框/阴影
themePrimaryDim = "rgba(d79921FF)"  -- yellow
themeOutline    = "rgba(928374FF)"  -- gray —— 弱化元素
themeSurface    = "rgba(282828FF)"  -- bg0
themeOnSurface  = "rgba(ebdbb2FF)"  -- fg1
