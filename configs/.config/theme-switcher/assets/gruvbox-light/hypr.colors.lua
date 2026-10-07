-- Gruvbox Light —— 由 theme-switcher 管理
-- ⚠ 改这个文件不生效（下次切主题会被覆盖）
--    要改请改 ~/.config/theme-switcher/assets/gruvbox-light/hypr.colors.lua

hl.config({
    general = {
        col = {
            active_border   = "rgba(b5761499)",  -- dark yellow（浅底上要更深才看得见）
            inactive_border = "rgba(d5c4a133)",  -- bg2
        },
    },
    misc = {
        background_color = "rgba(fbf1c7FF)",     -- bg0
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba(b57614AA) rgba(b5761477)",
})

-- 与 matugen 版保持完全相同的变量名，
-- 这样引用方（UserDecorations.lua）无需感知主题类型。
themePrimary    = "rgba(b57614FF)"  -- dark yellow —— 强调/边框/阴影
themePrimaryDim = "rgba(d79921FF)"  -- bright yellow
themeOutline    = "rgba(7c6f64FF)"  -- fg4 —— 弱化元素
themeSurface    = "rgba(fbf1c7FF)"  -- bg0
themeOnSurface  = "rgba(3c3836FF)"  -- fg1
