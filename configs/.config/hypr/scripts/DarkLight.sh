#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Dark and Light switching
#
# ============================================================
#  [ii 迁移] 大改。原脚本假设"整个桌面归 wallust + waybar + awww 管"，
#  现在这事归 theme-switcher 了，所以这里只保留两件它真正该管的事：
#
#    1. 切 ii / matugen 的明暗模式（委托给 switch.sh --toggle-mode）
#    2. 切 GTK 的 color-scheme、qt5ct/qt6ct 的配色方案、Kvantum 主题
#
#  已删除（都已废弃或与 ii 冲突）：
#    - awww 换壁纸  → 壁纸由你自己选，见 WallpaperSelect.sh (SUPER+W)
#    - wallust 调色板切换（palette = dark16/light16）
#    - swaync / ags / kitty / waybar 的配色 sed
#    - 从 Dynamic-Wallpapers 随机抓图（那目录里每个模式只有 1 张图，等于没随机）
#    - set_custom_gtk_theme 的随机挑主题（会和你的 Catppuccin-Mocha 打架，
#      也会和 theme-switcher 写的 gtk.css 打架）。函数保留在文件末尾但未调用，
#      想要原来的行为就把最后那段注释解开。
#
#  已修 bug：原来第 144-145 行用未定义的 $qt5ct_color_scheme / $qt6ct_color_scheme
#  去 sed，会把 color_scheme_path 写成空值，把 Qt 应用的配色方案清掉。
# ============================================================

SCRIPTSDIR="$HOME/.config/hypr/scripts"
THEME_SWITCHER="$HOME/.config/theme-switcher/switch.sh"
notif="$HOME/.config/swaync/images/bell.png"
MODE_CACHE="$HOME/.cache/.theme_mode"

# ---------- 1. 决定下一个模式 ----------
if [ "$(cat "$MODE_CACHE" 2>/dev/null)" = "Light" ]; then
    next_mode="Dark"
else
    next_mode="Light"
fi

# ---------- 2. 交给 theme-switcher 切 ii 的明暗 ----------
# 它会：改 matugen.theme 的 THEME_MATUGEN_MODE、让 ii 按新模式重生成配色、
#      若是静态主题则把静态配色抢回来、reload Hyprland、发通知。
if [ -x "$THEME_SWITCHER" ]; then
    "$THEME_SWITCHER" --toggle-mode
else
    notify-send -u critical "DarkLight" "找不到 $THEME_SWITCHER"
    exit 1
fi

# ---------- 3. GTK: 只切 color-scheme（不动具体主题名）----------
if [ "$next_mode" = "Dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
fi

# ---------- 4. qt5ct / qt6ct 配色方案 ----------
if [ "$next_mode" = "Dark" ]; then
    qt_scheme="Catppuccin-Mocha"
else
    qt_scheme="Catppuccin-Latte"
fi

qt_set_color_scheme() {
    local conf="$1"
    local colors_dir="$2"
    [ -f "$conf" ] || return 0
    if [ ! -f "$colors_dir/$qt_scheme.conf" ]; then
        echo "跳过 $conf：找不到配色文件 $colors_dir/$qt_scheme.conf"
        return 0
    fi
    sed -i "s|^color_scheme_path=.*$|color_scheme_path=$colors_dir/$qt_scheme.conf|" "$conf"
}

qt_set_color_scheme "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt5ct/colors"
qt_set_color_scheme "$HOME/.config/qt6ct/qt6ct.conf" "$HOME/.config/qt6ct/colors"

# ---------- 5. Kvantum（仅在该主题确实存在时才切）----------
if [ "$next_mode" = "Dark" ]; then
    kvantum_theme="catppuccin-mocha-blue"
else
    kvantum_theme="catppuccin-latte-blue"
fi

kvantum_dir_found=""
for d in "$HOME/.config/Kvantum" /usr/share/Kvantum; do
    [ -d "$d/$kvantum_theme" ] && kvantum_dir_found="$d"
done

if [ -n "$kvantum_dir_found" ] && command -v kvantummanager >/dev/null 2>&1; then
    kvantummanager --set "$kvantum_theme" >/dev/null 2>&1 || true
else
    echo "跳过 Kvantum：未安装 $kvantum_theme 主题（当前只装了 Colloid / MaterialAdw）"
fi

# ---------- 6. 记录模式，供下次交替 ----------
echo "$next_mode" > "$MODE_CACHE"

notify-send -u low -i "$notif" " Themes switched to:" " $next_mode Mode"
exit 0


# ============================================================
#  以下为原脚本的 GTK 主题/图标随机切换逻辑，默认不调用。
#
#  为什么不调用：
#    - 你现在的 gtk-theme 是 Catppuccin-Mocha，随机挑选会把它换掉
#    - 图标主题同理
#    - theme-switcher 已经在管 ~/.config/gtk-3.0/gtk.css 里的配色，
#      再叠一层"随机换主题名"会让颜色来源变得难以预测
#
#  想恢复原来的行为：把下面这行的注释去掉即可。
# ============================================================

# set_custom_gtk_theme "$next_mode"

set_custom_gtk_theme() {
    mode=$1
    gtk_themes_directory="$HOME/.themes"
    icon_directory="$HOME/.icons"
    color_setting="org.gnome.desktop.interface color-scheme"
    theme_setting="org.gnome.desktop.interface gtk-theme"
    icon_setting="org.gnome.desktop.interface icon-theme"

    if [ "$mode" == "Light" ]; then
        search_keywords="*Light*"
        gsettings set $color_setting 'prefer-light'
    elif [ "$mode" == "Dark" ]; then
        search_keywords="*Dark*"
        gsettings set $color_setting 'prefer-dark'
    else
        echo "Invalid mode provided."
        return 1
    fi

    themes=()
    icons=()

    while IFS= read -r -d '' theme_search; do
        themes+=("$(basename "$theme_search")")
    done < <(find "$gtk_themes_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

    while IFS= read -r -d '' icon_search; do
        icons+=("$(basename "$icon_search")")
    done < <(find "$icon_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

    if [ ${#themes[@]} -gt 0 ]; then
        selected_theme=${themes[RANDOM % ${#themes[@]}]}
        echo "Selected GTK theme for $mode mode: $selected_theme"
        gsettings set $theme_setting "$selected_theme"

        # Flatpak GTK apps (themes)
        if command -v flatpak &> /dev/null; then
            flatpak --user override --filesystem=$HOME/.themes
            sleep 0.5
            flatpak --user override --env=GTK_THEME="$selected_theme"
        fi
    else
        echo "No $mode GTK theme found"
    fi

    if [ ${#icons[@]} -gt 0 ]; then
        selected_icon=${icons[$RANDOM % ${#icons[@]}]}
        echo "Selected icon theme for $mode mode: $selected_icon"
        gsettings set $icon_setting "$selected_icon"

        ## QT5ct icon_theme
        sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt5ct/qt5ct.conf"
        sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt6ct/qt6ct.conf"

        # Flatpak GTK apps (icons)
        if command -v flatpak &> /dev/null; then
            flatpak --user override --filesystem=$HOME/.icons
            sleep 0.5
            flatpak --user override --env=ICON_THEME="$selected_icon"
        fi
    else
        echo "No $mode icon theme found"
    fi
}
