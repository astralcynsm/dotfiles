#!/usr/bin/env sh

set -eu

mode="${1:-}"
if [ "$mode" != "dark" ] && [ "$mode" != "light" ]; then
    echo "Usage: $0 dark|light" >&2
    exit 1
fi

set_gtk_settings() {
    file="$1"
    prefer_dark="$2"
    [ -f "$file" ] || return 0

    if grep -q '^gtk-application-prefer-dark-theme=' "$file"; then
        sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=${prefer_dark}/" "$file"
    else
        printf '\ngtk-application-prefer-dark-theme=%s\n' "$prefer_dark" >> "$file"
    fi

    if grep -q '^gtk-theme-name=' "$file"; then
        if [ "$mode" = "dark" ]; then
            sed -i 's/^gtk-theme-name=Catppuccin-Latte/gtk-theme-name=Catppuccin-Mocha/' "$file"
            sed -i 's/^gtk-theme-name=adw-gtk3$/gtk-theme-name=adw-gtk3-dark/' "$file"
        else
            sed -i 's/^gtk-theme-name=Catppuccin-Mocha/gtk-theme-name=Catppuccin-Latte/' "$file"
            sed -i 's/^gtk-theme-name=adw-gtk3-dark$/gtk-theme-name=adw-gtk3/' "$file"
        fi
    fi
}

set_qtct_scheme() {
    file="$1"
    scheme="$2"
    [ -f "$file" ] || return 0
    if grep -q '^color_scheme_path=' "$file"; then
        sed -i "s|^color_scheme_path=.*$|color_scheme_path=${scheme}|" "$file"
    else
        printf '\ncolor_scheme_path=%s\n' "$scheme" >> "$file"
    fi
}

if [ "$mode" = "dark" ]; then
    prefer_dark=1
    gnome_scheme='prefer-dark'
    gnome_theme='adw-gtk3-dark'
    qt5_scheme="$HOME/.config/qt5ct/colors/Catppuccin-Mocha.conf"
    qt6_scheme="$HOME/.config/qt6ct/colors/Catppuccin-Mocha.conf"
else
    prefer_dark=0
    gnome_scheme='prefer-light'
    gnome_theme='adw-gtk3'
    qt5_scheme="$HOME/.config/qt5ct/colors/Catppuccin-Latte.conf"
    qt6_scheme="$HOME/.config/qt6ct/colors/Catppuccin-Latte.conf"
fi

# Portal / libadwaita preference path
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme "$gnome_scheme" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface gtk-theme "$gnome_theme" >/dev/null 2>&1 || true
fi

# GTK fallback for apps reading settings.ini directly
set_gtk_settings "$HOME/.config/gtk-3.0/settings.ini" "$prefer_dark"
set_gtk_settings "$HOME/.config/gtk-4.0/settings.ini" "$prefer_dark"

# Qt apps (qq etc.) through qt5ct/qt6ct color schemes
set_qtct_scheme "$HOME/.config/qt5ct/qt5ct.conf" "$qt5_scheme"
set_qtct_scheme "$HOME/.config/qt6ct/qt6ct.conf" "$qt6_scheme"
