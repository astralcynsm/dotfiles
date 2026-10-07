#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# SDDM Wallpaper and Theme Colors Setter
#
# ============================================================
#  [ii 迁移]
#
#  原先：终端用 kitty（已卸载）→ 改成 foot
#        配色从 ~/.config/rofi/wallust/colors-rofi.rasi 抠（wallust 已废弃，
#        那个文件停留在旧壁纸上，是过期的）
#
#  现在：配色从 ~/.config/hypr/colors.lua 的 theme* 变量抠。
#        这些变量由 theme-switcher 统一管理，matugen 主题和静态主题
#        导出的名字完全一样，所以这里不需要知道当前是哪类主题。
#
#  调用方：WallpaperSelect.sh / WallpaperEffects.sh（那里的调用目前是注释掉的）
# ============================================================

# variables
terminal=foot
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_modified="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
sddm_simple="/usr/share/sddm/themes/simple_sddm_2"
sddm_theme_conf="$sddm_simple/theme.conf"

# 主题切换器导出的颜色变量
colors_lua="$HOME/.config/hypr/colors.lua"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"

# Parse arguments
mode="effects" # default
if [[ "$1" == "--normal" ]]; then
    mode="normal"
elif [[ "$1" == "--effects" ]]; then
    mode="effects"
fi

if [[ ! -f "$sddm_theme_conf" ]]; then
    notify-send -i "$iDIR/error.png" "SDDM" "找不到主题: $sddm_theme_conf"
    exit 1
fi

if [[ ! -f "$colors_lua" ]]; then
    notify-send -i "$iDIR/error.png" "SDDM" "找不到颜色文件: $colors_lua"
    exit 1
fi

# 从 colors.lua 抠 theme* 变量（形如 themePrimary    = "rgba(ffb3b0FF)"）
# 取出 rgba(...) 里的前 6 位作为 #RRGGBB
get_theme_color() {
    local var="$1"
    local hex
    hex=$(grep -oE "^\s*${var}\s*=\s*\"rgba\([0-9a-fA-F]{6}" "$colors_lua" \
          | grep -oE '[0-9a-fA-F]{6}$')
    if [[ -z "$hex" ]]; then
        echo ""
    else
        echo "#${hex}"
    fi
}

theme_primary=$(get_theme_color themePrimary)
theme_outline=$(get_theme_color themeOutline)
theme_surface=$(get_theme_color themeSurface)
theme_on_surface=$(get_theme_color themeOnSurface)

# 缺哪个就退回别的，尽量不让 SDDM 变成全黑
: "${theme_primary:=$theme_on_surface}"
: "${theme_outline:=$theme_on_surface}"
: "${theme_surface:=$theme_on_surface}"

# 映射到 SDDM 的各个色槽
color13="$theme_on_surface"   # 主文字（日期/时间/标题）
color12="$theme_primary"      # 强调（高亮背景、输入框文字）
color10="$theme_surface"      # 强调上的文字
color1="$theme_surface"       # 下拉框背景
color7="$theme_outline"       # 弱化（占位符、图标）

if [[ -z "$color13" ]]; then
    notify-send -i "$iDIR/error.png" "SDDM" "colors.lua 里没找到 theme* 变量\n（先跑一次 theme-switcher 试试）"
    exit 1
fi

# wallpaper to use
if [[ "$mode" == "normal" ]]; then
    wallpaper_path="$wallpaper_current"
else
    wallpaper_path="$wallpaper_modified"
    # 没做过特效就退回原图
    [[ -f "$wallpaper_path" ]] || wallpaper_path="$wallpaper_current"
fi

if [[ ! -f "$wallpaper_path" ]]; then
    notify-send -i "$iDIR/error.png" "SDDM" "找不到壁纸: $wallpaper_path"
    exit 1
fi

if ! command -v "$terminal" >/dev/null 2>&1; then
    notify-send -i "$iDIR/error.png" "SDDM" "缺少终端 $terminal，无法弹出密码输入"
    exit 1
fi

# Launch terminal and apply changes
$terminal -e bash -c "
echo 'Enter your password to update SDDM wallpapers and colors';

# Update the colors in the SDDM config
sudo sed -i \"s/HeaderTextColor=\\\"#.*\\\"/HeaderTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DateTextColor=\\\"#.*\\\"/DateTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/TimeTextColor=\\\"#.*\\\"/TimeTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DropdownSelectedBackgroundColor=\\\"#.*\\\"/DropdownSelectedBackgroundColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SystemButtonsIconsColor=\\\"#.*\\\"/SystemButtonsIconsColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SessionButtonTextColor=\\\"#.*\\\"/SessionButtonTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/VirtualKeyboardButtonTextColor=\\\"#.*\\\"/VirtualKeyboardButtonTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightBackgroundColor=\\\"#.*\\\"/HighlightBackgroundColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/LoginFieldTextColor=\\\"#.*\\\"/LoginFieldTextColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordFieldTextColor=\\\"#.*\\\"/PasswordFieldTextColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"

sudo sed -i \"s/DropdownBackgroundColor=\\\"#.*\\\"/DropdownBackgroundColor=\\\"$color1\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightTextColor=\\\"#.*\\\"/HighlightTextColor=\\\"$color10\\\"/\" \"$sddm_theme_conf\"

sudo sed -i \"s/PlaceholderTextColor=\\\"#.*\\\"/PlaceholderTextColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/UserIconColor=\\\"#.*\\\"/UserIconColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordIconColor=\\\"#.*\\\"/PasswordIconColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"

# Copy wallpaper to SDDM theme
sudo cp \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default\"

notify-send -i \"$iDIR/ja.png\" \"SDDM\" \"Background SET\"
"
