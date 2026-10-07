hl.config({
    general = {
        col = {
            active_border   = "rgba({{colors.outline_variant.default.hex_stripped}}77)",
            inactive_border = "rgba({{colors.surface_container_low.default.hex_stripped}}33)",
        },
    },
    misc = {
        background_color = "rgba({{colors.surface.dark.hex_stripped}}FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba({{colors.primary.default.hex_stripped}}AA) rgba({{colors.primary.default.hex_stripped}}77)",
})

-- ============================================================
-- 导出全局颜色变量，供 UserConfigs/ 下的配置引用
--
-- 原理：Hyprland 的 lua 配置共享同一个全局环境，所以
-- require("colors") 之后这些变量可在其它 .lua 文件里直接使用。
-- （已用 hyprctl getoption 验证过这套机制在 0.56.2 上有效）
--
-- 用法示例：
--     require("colors")
--     hl.config({ decoration = { shadow = { color = themePrimary } } })
--
-- 注意：这些变量由 ~/.config/theme-switcher/ 的主题切换器统一管理。
-- 切到静态主题（如 gruvbox）时本文件会被换成同样导出 theme* 变量的版本，
-- 所以引用方（UserDecorations.lua 等）无需感知主题类型。
-- ============================================================
themePrimary    = "rgba({{colors.primary.default.hex_stripped}}FF)"
themePrimaryDim = "rgba({{colors.primary_fixed_dim.default.hex_stripped}}FF)"
themeOutline    = "rgba({{colors.outline.default.hex_stripped}}FF)"
themeSurface    = "rgba({{colors.surface.default.hex_stripped}}FF)"
themeOnSurface  = "rgba({{colors.on_surface.default.hex_stripped}}FF)"
