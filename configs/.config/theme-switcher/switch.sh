#!/usr/bin/env bash
# ============================================================
#  主题切换器 —— 一次切换一整套配套
#  （foot 终端 / ghostty 终端 / Hyprland 边框 / hyprlock 锁屏 / GTK 应用 / fcitx5 候选框）
#
#  用法:
#    switch.sh <主题名> [壁纸路径]   应用指定主题
#    switch.sh -l, --list            列出所有主题
#    switch.sh -c, --current         显示当前主题
#    switch.sh -t, --type            显示当前主题类型
#    switch.sh -n, --next            切到下一个主题
#    switch.sh -r, --reload          重新应用当前主题
#                                    （matugen 主题会重读当前壁纸）
#    switch.sh -w, --wallpaper <图>  更换壁纸
#                                    （交给 ii 设置壁纸，再按当前主题类型收尾）
#    switch.sh --toggle-mode         深色/浅色来回切
#    switch.sh --set-mode <dark|light>
#                                    指定 matugen 主题的明暗并重新应用
#
#  主题定义 = themes/<名字>.theme，声明这些变量:
#    THEME_DESC          描述（显示在菜单/通知里）
#    THEME_TYPE          matugen | static
#    THEME_ASSETS        静态主题的资源目录名（默认与主题名相同）
#    THEME_MATUGEN_MODE  matugen 主题的明暗（dark | light，默认 dark）
#    THEME_MODE          静态主题的明暗（dark | light，默认 dark）
#                        这两项决定 GTK 应用和系统走浅色还是深色，
#                        以及换壁纸时 matugen 按哪个模式出图
#
#  想接入新组件（例如以后把终端换成 kitty/alacritty）:
#    在下面 COMPONENT_MAP 里加一行  "素材文件名|目标绝对路径"
#    其余逻辑自动生效，已写好的主题文件不必改动。
#
#  ⚠ 但"加一行就完事"只对**静态主题**成立。还要看两件事：
#    1) 该组件是否有 matugen 配色（即 ~/.config/matugen/config.toml 里
#       有没有对应的 [templates.*]）。有的话，matugen 生成完还要有人把
#       产物搬成"当前"——照 sync_foot_matugen() 写一个，并在 apply_matugen()
#       和 change_wallpaper() 里各挂一处。
#    2) 运行中的进程怎么重载。foot 是 touch 主配置 + 给在跑的窗口发信号
#       （reload_foot），ghostty 是 D-Bus（reload_ghostty），fcitx5 是 D-Bus 的
#       ReloadAddonConfig（reload_fcitx5）—— 三个都不一样，不能照抄。
#       重载函数写完要在 apply_static() 里也挂一处（见 ghostty_updated 那段）。
#    3) 谁来声明"终端该用深色还是浅色"。这是最容易漏的一环：
#       foot 不看系统明暗，必须由 theme 文件自带 initial-color-theme
#       （matugen 模板写 {{mode}}，四套静态素材钉 dark），否则新窗口永远深色。
#       加新组件时先确认：它有没有"当前明暗"这个状态，由谁喂。
#
#  参考实现：ghostty 是 2026-10-08 按上面两条完整接进来的，可以照它的样子抄。
# ============================================================

set -uo pipefail

SWITCHER_DIR="$HOME/.config/theme-switcher"
THEMES_DIR="$SWITCHER_DIR/themes"
ASSETS_DIR="$SWITCHER_DIR/assets"
STATE_FILE="$SWITCHER_DIR/current"
# 手动明暗记录：内容是一个 epoch 秒。auto-mode.sh 拿它和当前半日周期的起点
# 比较——周期内手动切过就不再自动覆盖（"手动优先"，见 README 自动明暗一节）。
LAST_MANUAL_FILE="$SWITCHER_DIR/.last-manual"

# --- 组件映射表: "素材文件名|目标绝对路径"（一行一个组件）---
# 素材文件放在 assets/<主题>/ 下，按这里的文件名取用
COMPONENT_MAP="
hypr.colors.lua|$HOME/.config/hypr/colors.lua
hyprlock.colors.conf|$HOME/.config/hypr/hyprlock/colors.conf
foot.ini|$HOME/.config/foot/current_theme.ini
ghostty.theme|$HOME/.config/ghostty/active-theme
gtk.css|$HOME/.config/gtk-3.0/gtk.css
colors.json|$HOME/.local/state/quickshell/user/generated/colors.json
"

# --- 壁纸来源（matugen 主题的输入）---
# ii 的权威来源：由 ii 自己的 switchwall.sh / 选择器写入，QML 也监听这个文件
II_CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
# 次级来源：matugen 的 wallpaper 模板把 {{image}} 回写到这里
II_WALLPAPER_FILE="$HOME/.local/state/quickshell/user/generated/wallpaper/path.txt"
# ii 的换壁纸脚本（换壁纸时由本脚本调用它，以便 QML 同步重绘）
II_SWITCHWALL="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"

# switchwall.sh 需要一个 python venv（算 Material You 配色）。
# 正常由 Hyprland 的 ENVariables.lua 注入；这里兜个底，
# 免得从没有该变量的环境（systemd unit、别的启动方式）调用时失败。
if [ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-}" ]; then
    export ILLOGICAL_IMPULSE_VIRTUAL_ENV="$HOME/.local/state/quickshell/.venv"
fi

# matugen 生成的 foot 主题会落在 foot 主题库里，需再同步成"当前"
FOOT_THEMES_DIR="$HOME/.config/foot/themes"
FOOT_CURRENT_FILE="$HOME/.config/foot/current_theme.ini"

# ghostty 与 foot 同构：config 最后一行 `config-file = .../active-theme`，
# 主题库在 themes/ 下。差别只有一处，但这一处决定了整个接法：
#   foot 的 theme 文件**一份能写两套**（[colors-dark] + [colors-light]），
#        但哪一套生效不看系统明暗，只看文件里的 initial-color-theme（默认 dark）
#   ghostty 的 theme 文件是**单模式**的，一个文件就是一组颜色
# 所以 matugen 那边出两份（matugen-dark / matugen-light），由下面
# sync_ghostty_matugen() 按当前主题的明暗选一份搬到 active-theme。
GHOSTTY_THEMES_DIR="$HOME/.config/ghostty/themes"
GHOSTTY_CURRENT_FILE="$HOME/.config/ghostty/active-theme"

log()  { printf '  %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*" >&2; }
die()  { printf '  ✗ %s\n' "$*" >&2; exit 1; }

# 落一笔"用户手动切了明暗"的时间戳，压住本半日周期内的自动逻辑。
# 放在这里而不是各调用方：手动入口有三个（SUPER+D 的 toggle-mode.sh、
# ii 界面的 DarkLight.sh、手敲命令行），它们最终都走 --toggle-mode。
# 2026-10-08 之前只有第一个入口在记（记在 wrapper 里），另两个切完不留痕，
# 自动逻辑照旧在下一个转折点把用户的选择覆盖回去。
# ⚠ 只该由 toggle_mode() 调：--set-mode 是 auto-mode.sh 自己用的纯 setter，
#   在那里记等于把自动切换误标成手动，自动逻辑会把自己锁死。
mark_manual() { date +%s > "$LAST_MANUAL_FILE" 2>/dev/null || true; }

# ⚠ 运行中的 foot 不会因为 current_theme.ini（被 include 的那份）变化而重载 ——
# foot 监视的是主配置 foot.ini。所以每次写完配色都要 touch 一下主配置，
# 否则只有新开的窗口是新配色，已经在跑的终端保持旧色不动。
# 实测：touch 前窗口背景 #221818（暖红棕），touch 后变冷灰、色相跟着壁纸走。
#
# ⚠⚠ 但 touch 只管"配色内容"，**不管用哪一段**。
#   foot 的 dark/light 段选择是运行期状态：启动时由 initial-color-theme 定，
#   之后只能靠信号改（foot(1) 明载，不是推测）：
#     SIGUSR1 → 切 [colors-dark]        SIGUSR2 → 切 [colors-light]
#   而 foot 完全不读 XDG Portal（1.28.0 实测：二进制里没有 "portal" 字样、
#   没链 portal 客户端库，手册里也 0 次提及），所以系统 color-scheme 变了
#   它根本不知道。两半分工：
#     新开的窗口 → initial-color-theme（由主题文件携带：matugen 模板写
#                  {{mode}}，四套静态素材钉 dark）
#     在跑的窗口 → 本函数按参数补一枪信号
#
# 参数: $1 = dark | light（想让运行中的窗口切到哪一段）。
#         缺省则只 touch、不发信号。
reload_foot() {
    [ -f "$HOME/.config/foot/foot.ini" ] || return 0
    touch "$HOME/.config/foot/foot.ini" 2>/dev/null \
        && log "· foot 已重载（运行中的窗口即时换色）"

    local sig="" pids=""
    case "${1:-}" in
        dark)  sig=USR1 ;;
        light) sig=USR2 ;;
        *) return 0 ;;
    esac

    # footclient 是 foot 的客户端（配 `foot --server` 用）。信号对两者都有效，
    # 而给 server 发还能顺带改变"以后新开的客户端"用哪一段（foot(1) 明载）。
    pids="$( { pgrep -x foot; pgrep -x footclient; } 2>/dev/null | sort -u | tr '\n' ' ' )"
    [ -n "${pids// /}" ] || return 0
    # shellcheck disable=SC2086
    kill -"$sig" $pids 2>/dev/null \
        && log "· foot 运行中的窗口已切到 ${1} 段"
    return 0
}

# ghostty 的重载机制和 foot 完全不同，别照抄 touch 那一套：
#
# ⚠ `ghostty +reload-config` 这个子命令**不存在**（1.3.1 实测；+reload-config
#   不是合法 action）。ghostty 把 reload 注册成了 GTK action，只能走 D-Bus：
#     org.gtk.Actions.Activate reload-config '[]' '{}'
#   注意参数是**两个**：GLib.Variant 数组（这里空数组）+ 一个 a{sv} 字典。
#   在 zsh 里手敲要给 [] 加引号，否则被当 glob 展开成 "no matches found"。
#
# 已实测（2026-10-08，Ghostty 1.3.1-arch2）：
#   · DescribeAll 里 reload-config 在册
#   · Describe reload-config → ((true, signature '', @av []),)，启用且无参数
#   · 调用返回 ()、退出码 0
#   · XDG_CONFIG_HOME 隔离测试确认：改 active-theme 后调用它，
#     ghostty 重读了 include 链，palette/background/cursor 全部换新
#
# ⚠ ghostty 未运行时不要报错（开机、纯 TTY、或用户还没开终端都会走到这）。
#   gdbus 会返回 "The name com.mitchellh.ghostty was not provided by any .service files"
#   并给非零退出码 —— 那是正常情况，静默跳过即可。
reload_ghostty() {
    command -v gdbus >/dev/null 2>&1 || return 0
    gdbus call --session \
        --dest com.mitchellh.ghostty \
        --object-path /com/mitchellh/ghostty \
        --method org.gtk.Actions.Activate \
        reload-config '[]' '{}' >/dev/null 2>&1 \
        && log "· ghostty 已重载（运行中的窗口即时换色）"
    return 0
}

# ---------- fcitx5 候选框 ----------
# 主题目录：matugen 只把 theme.conf（配色）和 _colors.env（两个颜色）生成到这里，
# 圆角背景图 panel.png / highlight.png 由本脚本现画（原因见下）。
FCITX5_THEMES_DIR="$HOME/.local/share/fcitx5/themes"
FCITX5_IMG_SIZE=48      # 9-patch 源图边长
FCITX5_PANEL_RADIUS=16  # 面板圆角；必须 ≤ theme.conf 里 [*/Background/Margin] 的 18
FCITX5_HL_RADIUS=12     # 选中项圆角；必须 ≤ [*/Highlight/Margin] 的 14

# 画一张「只有四角透明」的圆角矩形 PNG，供 fcitx5 当 9-patch 背景用。
# 矩形故意画到 -0.5..(尺寸-0.5)，比画布外扩半个像素 —— 这样四条直边覆盖到的
# 像素格是完整的，不会留出半透明的边；只有四角真的是圆的。
# ⚠ 用 ImageMagick 直绘，不要走 SVG（rsvg-convert 会把 #251f17 渲染成
# (28,32,36)，本机实测的一套色彩变换；magick 直绘保色准确）。
_draw_rounded_rect() {
    local color="$1" radius="$2" out="$3" far
    far=$(( FCITX5_IMG_SIZE - 1 ))
    magick -size "${FCITX5_IMG_SIZE}x${FCITX5_IMG_SIZE}" xc:none \
        -fill "$color" \
        -draw "roundrectangle -0.5,-0.5 ${far}.5,${far}.5 $radius,$radius" \
        PNG32:"$out" 2>/dev/null
}

# 为什么背景图不用 SVG 让 fcitx5 自己画：
#   fcitx5 theme.cpp 的 SVG 分支 createImage(cairo_pattern_t*, ...) 没有给
#   pattern 设 CAIRO_EXTEND_PAD，而 cairo 默认是 CAIRO_EXTEND_NONE —— 采样
#   越界返回全透明。9-patch 拉伸边条时恰好会采到图案边界外，于是面板边缘和
#   切片线（距边 18px、距上下 12px 那两条线）附近透出背后的窗口内容，
#   表现为候选框上多出一圈红/蓝细线。PNG 分支
#   createImage(Pixmap, ...) 用 cairo_surface_create_for_rectangle 取真子表面
#   并显式设了 EXTEND_PAD，没有这个问题。所以走 PNG。
sync_fcitx5_assets() {
    command -v magick >/dev/null 2>&1 || { warn "没装 ImageMagick，fcitx5 圆角背景图无法生成"; return 0; }

    local mode dir envfile panel hl ok=0
    for mode in dark light; do
        dir="$FCITX5_THEMES_DIR/matugen-$mode"
        envfile="$dir/_colors.env"
        [ -f "$envfile" ] || continue

        unset FCITX5_PANEL FCITX5_HIGHLIGHT
        # shellcheck disable=SC1090
        source "$envfile" || continue
        [ -n "${FCITX5_PANEL:-}" ] && [ -n "${FCITX5_HIGHLIGHT:-}" ] || {
            warn "$envfile 里没有 FCITX5_PANEL / FCITX5_HIGHLIGHT，跳过"
            continue
        }

        panel="$FCITX5_PANEL"; hl="$FCITX5_HIGHLIGHT"
        _draw_rounded_rect "$panel" "$FCITX5_PANEL_RADIUS" "$dir/panel.png" \
            && _draw_rounded_rect "$hl" "$FCITX5_HL_RADIUS" "$dir/highlight.png" \
            && { log "✓ fcitx5-$mode 背景图已重绘"; ok=1; }
    done

    [ "$ok" -eq 1 ] || warn "没有任何 fcitx5 背景图被生成"
}

# fcitx5 是常驻进程，主题只在启动/重载时读，所以每次重新生成配色后都得让它
# 重读一次，否则候选框还是旧颜色。
#
# ⚠⚠ 千万不要用 `fcitx5-remote -r`（2026-09-20 实测证伪）
#   它发的是 ReloadConfig，而 Instance::reloadConfig()
#   （fcitx5 源码 src/lib/fcitx/instance.cpp）只做一句
#   `readAsIni(globalConfig_, PkgConfig, "config")` —— 只重读全局的
#   ~/.config/fcitx5/config，既不碰 conf/classicui.conf，也不调
#   addon 的 reloadConfig()，所以**主题完全不会重载**。
#   实测方法：inotify 盯 themes/matugen-{dark,light}/ + conf/，
#   调 `fcitx5-remote -r` 后只有 ~/.config/fcitx5/config 被读，
#   两套主题目录零事件。这正是「换壁纸后 fcitx5 完全没变色」的真凶。
#
# ✅ 正确的方式是 DBus 的 ReloadAddonConfig：
#   Instance::reloadAddonConfig("classicui") → ClassicUI::reloadConfig()
#   → reloadTheme() → theme_.load()，会把 theme.conf 和背景图从磁盘重读。
#   实测：调用后 inotify 立刻抓到**当前选中那套**的 theme.conf 被 OPEN|ACCESS。
#   坑：接口名是 org.fcitx.Fcitx.Controller1，不是 ...Fcitx5.Controller1。
#
# ⚠ reloadTheme() 不会主动重绘已存在的候选框窗口，要等下一次 update
#   （敲键）才用新主题画。所以换完壁纸要敲一下输入法才看到新配色，属正常。
#
# 明暗切换（dark↔light）走同一条路：classicui.conf 里 UseDarkTheme=True，
# fcitx5 按系统 color-scheme（XDG Portal）在两套主题间选，重载让它重读判断。
# 本函数同时负责先把背景图重画一遍（否则重载读到的是上次的图）。
reload_fcitx5() {
    sync_fcitx5_assets

    # fcitx5 没在跑就静默跳过（-x 是精确进程名匹配，不会误伤别的进程）
    pgrep -x fcitx5 >/dev/null 2>&1 || return 0
    command -v gdbus >/dev/null 2>&1 || {
        warn "没装 gdbus（glib2），fcitx5 主题无法热重载"
        return 0
    }

    if gdbus call --session --dest org.fcitx.Fcitx5 --object-path /controller \
            --method org.fcitx.Fcitx.Controller1.ReloadAddonConfig classicui \
            >/dev/null 2>&1; then
        log "· fcitx5 主题已重载（敲一下输入法即见新配色）"
    else
        warn "fcitx5 主题重载失败"
    fi
}

# matugen 把 foot 主题生成到主题库（themes/matugen.ini），不会自动变成"当前"。
# 但新开的 foot 窗口读的是 current_theme.ini，所以每次重生成后都要搬一次，
# 否则只有已经在跑的终端（走 ANSI 转义序列）变新色，新窗口还是旧的。
#
# 参数: $1 = dark | light，转给 reload_foot 决定给运行中的窗口发哪个信号。
#       缺省回落到当前 matugen 主题声明的明暗。
# ⚠ 搬运的那份文件里带着 initial-color-theme={{mode}}（模板写的），
#   和这里的 $1 应当是同一档才自洽 —— 所有调用点都传的是"这次 matugen
#   实际用的 --mode"，所以天然一致。
sync_foot_matugen() {
    local mode="${1:-$(current_matugen_mode)}"
    [ -f "$FOOT_THEMES_DIR/matugen.ini" ] || return 0
    cp -f "$FOOT_THEMES_DIR/matugen.ini" "$FOOT_CURRENT_FILE" \
        && log "✓ foot.ini（跟随壁纸配色 · $mode）"
    reload_foot "$mode"
}

# matugen 那边生成了 matugen-dark / matugen-light 两份（原因见文件上方
# GHOSTTY_THEMES_DIR 处的注释），这里按当前明暗选一份搬到 active-theme。
#
# ⚠ 选哪份必须由**主题的明暗**决定，不能读系统 color-scheme。
#   理由和 sync_gtk_mode() 那段注释里写的是同一件事：gsettings 和主题文件
#   会打架。这里统一听主题的。
#
# 参数: $1 = dark | light，缺省时回落到当前主题声明的 THEME_MATUGEN_MODE。
sync_ghostty_matugen() {
    local mode="${1:-${THEME_MATUGEN_MODE:-dark}}"
    local src="$GHOSTTY_THEMES_DIR/matugen-$mode"

    if [ ! -f "$src" ]; then
        warn "找不到 ghostty 配色: $src（matugen 模板没配或没跑）"
        return 0
    fi
    cp -f "$src" "$GHOSTTY_CURRENT_FILE" \
        && log "✓ ghostty（跟随壁纸配色 · $mode）"
    reload_ghostty
}

# ii 的 switchwall.sh 在不带 --mode 时会去读 gsettings 的 color-scheme，
# 而 ii 自己的浅色/深色切换（以及本脚本的 --toggle-mode）都会写这个值。
# 于是有两处记录同一件事，会打架：gsettings 停在 light、主题文件写的是 dark，
# 此时换一张壁纸就会把整个桌面悄悄刷成浅色。
# 所以这里统一以"当前主题的模式"为准：套主题时把 gsettings 掰回来，
# 调 switchwall.sh 时也显式带上 --mode（见 change_wallpaper），不信 gsettings。
sync_gtk_mode() {
    local mode="$1"
    command -v gsettings >/dev/null 2>&1 || return 0
    case "$mode" in dark|light) ;; *) return 0 ;; esac

    local want_scheme="prefer-dark" want_theme="adw-gtk3-dark"
    if [ "$mode" = "light" ]; then want_scheme="prefer-light"; want_theme="adw-gtk3"; fi

    local cur
    cur="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")"
    if [ "$cur" != "$want_scheme" ]; then
        gsettings set org.gnome.desktop.interface color-scheme "$want_scheme" 2>/dev/null \
            && log "· GTK 明暗: $want_scheme"
    fi

    # gtk-theme 直接跟着明暗走；不跟着走的话 GTK 应用会和边框/终端对不上
    cur="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")"
    if [ "$cur" != "$want_theme" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "$want_theme" 2>/dev/null \
            && log "· GTK 主题: $want_theme"
    fi
}

# ---------- KDE 配色方案（Dolphin 及所有 KDE 应用）----------
# 机制和 GTK 不同：GTK 允许"两套主题同时装在盘上、按 color-scheme 自动选"，
# KDE 不行 —— 它只认 kdeglobals 里 [General] ColorScheme= 这一个字符串。
# 所以做法是：两套 .colors 并存于磁盘（由 matugen 生成，见 config.toml 的
# [templates.kde_dark] / [templates.kde_light]，模板里钉死 .dark/.light 后缀
# 保证两者互不覆盖），本函数在切明暗时把 kdeglobals 指向对应的那一套。
#
# 已知缺口（与 rofi / fcitx5 同源）：static 主题（gruvbox / kanagawa）的配色
# 由 switch.sh 自己从 assets/ 拷，不经过 matugen，所以 KDE 侧不会变成该主题的
# 色板，只会跟着明暗切到"最后一次 matugen 的那套"。要补齐得给每个静态主题
# 另做一份 .colors，目前没做。
sync_kde_colorscheme() {
    local mode="$1" scheme
    case "$mode" in
        dark)  scheme="MaterialYouDark"  ;;
        light) scheme="MaterialYouLight" ;;
        *) return 0 ;;
    esac

    # 配色文件不存在就绝不碰 kdeglobals —— 一旦指向一个不存在的方案，
    # KDE 会静默退回内置默认配色（亮蓝），比留着上一套还难看。
    if [ ! -f "$HOME/.local/share/color-schemes/$scheme.colors" ]; then
        warn "配色方案 $scheme.colors 不存在，KDE 配色保持不动"
        return 0
    fi

    command -v kwriteconfig6 >/dev/null 2>&1 || {
        warn "没装 kwriteconfig6（kconfig 包），KDE 配色无法切换"
        return 0
    }

    # 先读当前值，相同就不写。KConfig 每次写回都会重排文件格式，也会让所有
    # 在跑的 KDE 应用收到一次无意义的变更通知 —— 没必要每次套主题都触发。
    local cur
    cur="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)"
    [ "$cur" = "$scheme" ] && return 0

    if kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$scheme" 2>/dev/null; then
        log "· KDE 配色: $scheme"
    else
        warn "写入 kdeglobals 失败"
    fi
}

# ---------- 系统级明暗 ----------
# GTK 和 KDE 的"选择机制"完全不同（见各自函数注释），但切换时机永远一致：
# 套主题、切明暗、换壁纸三处都要跟。所以统一从这里驱动，
# 避免将来新增调用点时只改了一边、另一边悄悄不跟。
sync_system_mode() {
    sync_gtk_mode "$1"
    sync_kde_colorscheme "$1"
}

# ---------- 主题的读取与列举 ----------
list_themes() {
    find "$THEMES_DIR" -maxdepth 1 -name '*.theme' -printf '%f\n' 2>/dev/null \
        | sed 's/\.theme$//' | sort
}

load_theme() {
    local name="$1" file="$THEMES_DIR/$1.theme"
    [ -f "$file" ] || { warn "主题不存在: $name"; return 1; }
    unset THEME_DESC THEME_TYPE THEME_ASSETS THEME_MATUGEN_MODE THEME_MODE
    # shellcheck disable=SC1090
    source "$file"
    THEME_NAME="$name"
    : "${THEME_TYPE:=static}"
    : "${THEME_DESC:=$name}"
    return 0
}

current_theme() {
    [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "(未设置)"
}

current_type() {
    local name; name="$(current_theme)"
    load_theme "$name" >/dev/null 2>&1 || { echo ""; return; }
    echo "$THEME_TYPE"
}

# ---------- 找当前壁纸 ----------
# 优先 config.json（ii 的权威来源，QML 就监听它），退回 matugen 写的 path.txt
resolve_wallpaper() {
    local w=""
    if [ -f "$II_CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
        w="$(jq -r '.background.wallpaperPath // empty' "$II_CONFIG_FILE" 2>/dev/null)"
    fi
    if [ -z "$w" ] || [ ! -f "$w" ]; then
        w="$(cat "$II_WALLPAPER_FILE" 2>/dev/null || true)"
    fi
    printf '%s' "$w"
}

# ---------- 终端配色的归属权 ----------
# ii 的 applycolor.sh 会往运行中的终端推 ANSI 转义序列（实时的、不走配置文件）。
# 这套序列永远来自当前壁纸，会和静态主题的 foot.ini 打架。所以按主题类型分工：
#   matugen 主题 → 交给 ii（壁纸驱动，运行中的终端即时换色）
#   static  主题 → 交给我们（foot.ini 说了算，ii 不要插手）
set_terminal_theming() {
    local want="$1"   # true | false
    [ -f "$II_CONFIG_FILE" ] || return 0
    command -v jq >/dev/null 2>&1 || return 0
    local cur
    cur="$(jq -r '.appearance.wallpaperTheming.enableTerminal // empty' "$II_CONFIG_FILE" 2>/dev/null)"
    [ "$cur" = "$want" ] && return 0
    jq --argjson v "$want" '.appearance.wallpaperTheming.enableTerminal = $v' \
        "$II_CONFIG_FILE" > "$II_CONFIG_FILE.tmp" \
        && mv "$II_CONFIG_FILE.tmp" "$II_CONFIG_FILE" \
        && log "· 终端配色归属: $([ "$want" = true ] && echo 'ii（跟随壁纸）' || echo '主题切换器（固定配色）')"
}

# ---------- 应用: 静态主题（固定配色，与壁纸无关）----------
apply_static() {
    local assets="$ASSETS_DIR/${THEME_ASSETS:-$THEME_NAME}"
    [ -d "$assets" ] || { warn "资源目录不存在: $assets"; return 1; }

    local updated=0 foot_updated=0 ghostty_updated=0
    while IFS='|' read -r src dst; do
        [ -z "${src:-}" ] && continue
        if [ -f "$assets/$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp -f "$assets/$src" "$dst" && {
                log "✓ $src"; updated=$((updated+1))
                if [ "$dst" = "$FOOT_CURRENT_FILE" ]; then foot_updated=1; fi
                if [ "$dst" = "$GHOSTTY_CURRENT_FILE" ]; then ghostty_updated=1; fi
            }
        else
            log "· $src（本主题未提供，跳过）"
        fi
    done <<< "$COMPONENT_MAP"

    # foot 配色换了，但运行中的窗口要 touch 主配置才会重读（见 reload_foot）；
    # 静态主题一律把配色放 [colors-dark]（素材里钉了 initial-color-theme=dark），
    # 所以这里固定按 dark 发信号。
    if [ "$foot_updated" -eq 1 ]; then reload_foot dark; fi
    # ghostty 同理，只是重载手段不同（见 reload_ghostty 的注释）
    if [ "$ghostty_updated" -eq 1 ]; then reload_ghostty; fi

    [ "$updated" -gt 0 ] || { warn "没有任何组件被更新"; return 1; }
}

# ---------- 应用: matugen 主题（跟随壁纸自动配色）----------
apply_matugen() {
    local wall="${1:-}"
    local mode="${THEME_MATUGEN_MODE:-dark}"

    # 没显式传壁纸，就用 ii 记的那张
    [ -z "$wall" ] && wall="$(resolve_wallpaper)"

    if [ -z "$wall" ] || [ ! -f "$wall" ]; then
        warn "找不到可用壁纸（参数='${1:-}'，ii 记录='${wall:-}'）"
        warn "matugen 主题需要一张壁纸作为配色输入"
        return 1
    fi

    command -v matugen >/dev/null || { warn "matugen 未安装"; return 1; }

    log "壁纸: $wall"
    log "模式: $mode"
    matugen image "$wall" --mode "$mode" || { warn "matugen 执行失败"; return 1; }
    log "✓ matugen 已生成各组件配色"

    sync_foot_matugen "$mode"
    sync_ghostty_matugen "$mode"
}

# ---------- 壁纸的下游同步 ----------
# 除了各组件配色，换壁纸还有两处"消费者"需要跟着更新：
#   1. hyprlock 读 .wallpaper_current 当锁屏背景
#      （见 hyprlock.conf 的 background.path）
#   2. 6 个 rofi 主题把 ~/.config/rofi/.current_wallpaper 当背景图
# 这两个文件原本由 KooL 的 WallustSwww.sh 维护；接入 ii 后，换壁纸不再
# 经过那个脚本，所以在这里统一同步，否则它们会停留在旧图。
sync_wallpaper_links() {
    local wall="$1"
    [ -n "$wall" ] && [ -f "$wall" ] || return 0

    local lock_bg="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
    local rofi_bg="$HOME/.config/rofi/.current_wallpaper"

    mkdir -p "$(dirname "$lock_bg")"
    cp -f "$wall" "$lock_bg" && log "✓ 锁屏背景已同步"

    mkdir -p "$(dirname "$rofi_bg")"
    if ln -sf "$wall" "$rofi_bg" 2>/dev/null; then
        log "✓ rofi 背景图已同步"
    else
        # ~/.config/rofi 在别的文件系统上时 ln 可能失败，退回复制
        cp -f "$wall" "$rofi_bg" && log "✓ rofi 背景图已同步（复制）"
    fi
}

# ---------- 明暗模式 ----------
# ii 的 toggleLightDark 内部是 switchwall.sh --mode X --noswitch（保留壁纸、重生成配色）。
# 但 switchwall.sh 会顺带把 colors.lua 等文件写成 matugen 版，
# 所以切完若当前是静态主题，必须再把静态配色抢回来。
set_matugen_mode() {
    local mode="$1"
    case "$mode" in
        dark|light) ;;
        *) warn "模式只能是 dark 或 light（给的是 '$mode'）"; return 1 ;;
    esac
    local f="$THEMES_DIR/matugen.theme"
    [ -f "$f" ] || { warn "找不到 $f"; return 1; }
    sed -i "s|^THEME_MATUGEN_MODE=.*|THEME_MATUGEN_MODE=\"$mode\"|" "$f"
    log "· matugen 主题明暗已设为 $mode"

    # 立刻把 gsettings / kdeglobals 掰到同一档，
    # 免得它们继续留着旧值误导后续的 switchwall.sh
    sync_system_mode "$mode"
}

current_matugen_mode() {
    local f="$THEMES_DIR/matugen.theme"
    [ -f "$f" ] || { printf 'dark'; return; }
    ( unset THEME_MATUGEN_MODE
      # shellcheck disable=SC1090
      source "$f"
      printf '%s' "${THEME_MATUGEN_MODE:-dark}" )
}

# 当前主题的明暗（dark | light）。
# matugen 主题看 THEME_MATUGEN_MODE，静态主题看自己的 THEME_MODE（默认 dark）。
# 调用前需先 load_theme。
theme_mode() {
    if [ "${THEME_TYPE:-}" = "matugen" ]; then
        current_matugen_mode
    else
        printf '%s' "${THEME_MODE:-dark}"
    fi
}

toggle_mode() {
    local cur next
    cur="$(current_matugen_mode)"
    if [ "$cur" = "dark" ]; then next="light"; else next="dark"; fi

    printf '\n▸ 切换明暗: %s → %s\n' "$cur" "$next"
    set_matugen_mode "$next"

    if [ -x "$II_SWITCHWALL" ]; then
        # --noswitch = 保留当前壁纸，只按新模式重新生成配色
        "$II_SWITCHWALL" --mode "$next" --noswitch >/dev/null 2>&1 \
            && log "✓ ii 已按新模式重新生成配色" \
            || warn "ii 的 switchwall.sh 执行失败"
    fi

    if [ "$(current_type)" = "static" ]; then
        local name; name="$(current_theme)"
        log "· 当前为静态主题 ($name)，重新套用以恢复配色"
        load_theme "$name" && apply_static
    else
        # matugen 主题：ii 的 switchwall.sh 已经按新模式重跑过 matugen，
        # 但两个终端的"当前配色"文件都得各自重搬一次 —— 不搬的话它们会
        # 停在上一个明暗档上。分工和 change_wallpaper() 里那段完全一样：
        #   foot    一份文件含明暗两段；搬完由 reload_foot 发 SIGUSR 让
        #           在跑的窗口换段，新窗口则读文件里的 initial-color-theme
        #   ghostty 明暗是两份文件，得按 $next 选一份搬过去
        # 注意这里必须放 else 里 —— 静态主题的配色由上面的 apply_static
        # 经 COMPONENT_MAP 投放，搬 matugen 配色会把它整个盖掉。
        sync_foot_matugen "$next"
        sync_ghostty_matugen "$next"
    fi

    sync_wallpaper_links "$(resolve_wallpaper)"

    # 明暗换了，fcitx5 要在 matugen-dark / matugen-light 之间跟着换
    reload_fcitx5

    command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1

    # 整套已经换完，落"手动"记录：本周期内 auto-mode.sh 不再自动覆盖
    mark_manual

    notify-send -a "主题切换" \
        "已切换到 $([ "$next" = dark ] && echo '深色' || echo '浅色')模式" 2>/dev/null || true
    printf '✓ 完成\n\n'
}

# ---------- 换壁纸 ----------
# 壁纸由用户自己挑。换壁纸 = 让 ii 接管壁纸本身，然后按当前主题类型收尾：
#   matugen 主题 → ii 的 switchwall.sh 已经把该做的都做了，无需额外动作
#   static  主题 → switchwall.sh 会顺手把 matugen 配色写进 colors.lua 等文件，
#                 所以必须用当前静态主题再覆盖一遍，否则配色会被壁纸顶掉
change_wallpaper() {
    local img="$1"
    [ -n "$img" ] && [ -f "$img" ] || { warn "壁纸不存在: ${img:-（空）}"; return 1; }

    printf '\n▸ 更换壁纸: %s\n' "$img"

    if [ ! -x "$II_SWITCHWALL" ]; then
        warn "找不到 ii 的 switchwall.sh: $II_SWITCHWALL"
        return 1
    fi

    # 先确定当前主题的明暗，并显式交给 switchwall.sh。
    # 不带 --mode 时它会去读 gsettings 的 color-scheme——那个值可能被 ii
    # 自己的浅色/深色切换改过，和主题文件对不上，于是换张壁纸就把整个
    # 桌面悄悄刷成另一种明暗（边框/GTK/ii 界面全变，终端还是旧的）。
    local name mode="dark"
    name="$(current_theme)"
    if load_theme "$name" >/dev/null 2>&1; then
        mode="$(theme_mode)"
        sync_system_mode "$mode"
    fi

    # ii 负责：设置壁纸（QML 重绘）、写 config.json、跑 matugen、推终端转义序列
    "$II_SWITCHWALL" "$img" --mode "$mode"
    log "✓ ii 已应用壁纸并重绘"

    if [ "${THEME_TYPE:-}" = "static" ]; then
        # 静态主题：把被 matugen 覆盖掉的配色抢回来
        log "· 当前为静态主题 ($name)，重新套用以恢复配色"
        apply_static
    else
        # matugen 主题：ii 的 switchwall.sh 已经跑完 matugen，
        # 但 foot 的"当前主题"文件要单独搬一次——新开的终端窗口读的是它，
        # 不搬的话只有正在跑的终端（走 ANSI 转义序列）会换色。
        # ghostty 同样要搬，且还要按明暗选是 dark 那份还是 light 那份。
        sync_foot_matugen "$mode"
        sync_ghostty_matugen "$mode"
        reload_fcitx5
    fi

    sync_wallpaper_links "$img"

    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 && log "✓ Hyprland 已 reload"
    fi

    notify-send -a "壁纸" -i "$img" "壁纸已更换" "$(basename "$img")" 2>/dev/null || true
    printf '✓ 完成\n\n'
}

# ---------- 主流程 ----------
apply_theme() {
    local name="$1" wall="${2:-}"
    load_theme "$name" || return 1

    printf '\n▸ 切换到主题: %s\n' "${THEME_DESC:-$name}"

    case "$THEME_TYPE" in
        matugen) apply_matugen "$wall" || return 1 ;;
        static)  apply_static         || return 1 ;;
        *) warn "未知主题类型: $THEME_TYPE"; return 1 ;;
    esac

    # 终端配色归属：matugen 交给 ii，static 归我们
    case "$THEME_TYPE" in
        matugen) set_terminal_theming true  ;;
        static)  set_terminal_theming false ;;
    esac

    # GTK 应用 / KDE 配色跟着主题的明暗走，顺手修掉 gsettings 里可能残留的旧模式
    sync_system_mode "$(theme_mode)"

    # 无论哪种主题，都把当前壁纸同步给 hyprlock 当锁屏背景
    sync_wallpaper_links "$(resolve_wallpaper)"

    echo "$name" > "$STATE_FILE"

    # fcitx5 的候选框主题由 matugen 重新生成过（或明暗变了），让它重读一次
    reload_fcitx5

    # 让 Hyprland 边框/阴影即时生效（hyprlock 每次启动时读配置，无需动作；
    # GTK 需新开窗口才看到效果；foot 已由 reload_foot 即时重载）
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 && log "✓ Hyprland 已 reload"
    fi

    notify-send -a "主题切换" -i "preferences-desktop-theme" \
        "已切换到 ${THEME_DESC:-$name}" \
        "foot / ghostty / 边框 / 锁屏 / GTK / fcitx5 已同步" 2>/dev/null || true

    printf '✓ 完成（当前主题: %s）\n\n' "$name"
}

usage() {
    cat <<'EOF'
主题切换器 —— 一次切换一整套配套（foot / ghostty / Hyprland 边框 / hyprlock / GTK / fcitx5）

用法:
  switch.sh <主题名> [壁纸路径]   应用指定主题
  switch.sh -l, --list            列出所有主题
  switch.sh -c, --current         显示当前主题
  switch.sh -t, --type            显示当前主题类型（matugen | static）
  switch.sh -n, --next            切到下一个主题
  switch.sh -r, --reload          重新应用当前主题
                                  （matugen 主题会重读当前壁纸）
  switch.sh -w, --wallpaper <图>  更换壁纸
                                  （交给 ii 设置壁纸，再按当前主题类型收尾）
  switch.sh --toggle-mode         深色/浅色来回切
  switch.sh --set-mode <dark|light>
                                  指定 matugen 主题的明暗并重新应用

想接入新组件（例如以后换终端）: 编辑本脚本里的 COMPONENT_MAP
EOF
}

# ---------- 入口 ----------
case "${1:-}" in
    ""|-h|--help)
        usage; exit 0 ;;
    -l|--list)
        cur="$(current_theme)"
        while read -r t; do
            [ -z "$t" ] && continue
            if [ "$t" = "$cur" ]; then printf '  * %s\n' "$t"; else printf '    %s\n' "$t"; fi
        done < <(list_themes)
        exit 0 ;;
    -c|--current)
        current_theme; exit 0 ;;
    -t|--type)
        current_type; exit 0 ;;
    -w|--wallpaper)
        change_wallpaper "${2:-}"; exit $? ;;
    --toggle-mode)
        toggle_mode; exit $? ;;
    --set-mode)
        set_matugen_mode "${2:-}"; exit $? ;;
    -n|--next)
        mapfile -t all < <(list_themes)
        [ "${#all[@]}" -eq 0 ] && die "没有任何主题"
        cur="$(current_theme)"; idx=-1
        for i in "${!all[@]}"; do [ "${all[$i]}" = "$cur" ] && idx=$i; done
        apply_theme "${all[$(( (idx+1) % ${#all[@]} ))]}"
        exit 0 ;;
    -r|--reload)
        apply_theme "$(current_theme)"; exit 0 ;;
    -*)
        die "未知选项: $1" ;;
    *)
        apply_theme "$1" "${2:-}" ;;
esac
