-- Death Stranding —— 由 theme-switcher 管理
-- ⚠ 改这个文件不生效（下次切主题会被覆盖）
--    要改请改 ~/.config/theme-switcher/assets/death-stranding/hypr.colors.lua

hl.config({
    general = {
        col = {
            active_border   = "rgba(e8842c99)",  -- 琥珀橙
            inactive_border = "rgba(33333355)",  -- outline_variant
        },
    },
    misc = {
        background_color = "rgba(0a0a0aFF)",     -- 近纯黑
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba(e8842cAA) rgba(e8842c77)",
})

-- 与 matugen 版保持完全相同的变量名，
-- 这样引用方（UserDecorations.lua）无需感知主题类型。
themePrimary    = "rgba(e8842cFF)"  -- 琥珀橙 —— 强调/边框/阴影
themePrimaryDim = "rgba(8a5021FF)"  -- 暗橙
themeOutline    = "rgba(6a6a6aFF)"  -- 中性灰 —— 弱化元素
themeSurface    = "rgba(0a0a0aFF)"  -- 近纯黑
themeOnSurface  = "rgba(e6e6e6FF)"  -- 浅灰
