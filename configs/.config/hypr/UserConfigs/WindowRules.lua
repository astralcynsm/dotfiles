-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- For window rules and layerrules
-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
--
-- 由 UserConfigs/WindowRules.conf 转换为 lua (Hyprland >= 0.55)
-- windowrule { name=..., match:class=... } -> hl.window_rule({ name=..., match = { class = ... }, ... })
-- layerrule { match:namespace=... }         -> hl.layer_rule({ match = { namespace = ... }, ... })

-- NOTES: This is only for Hyprland > 0.48

-- note for ja: This should NOT be implemented on Debian and Ubuntu

-- windowrule - tags - add apps under appropriate tag to use the same settings
-- browser tags
hl.window_rule({
    name  = "windowrule-1",
    tag   = "+browser",
    match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
})

hl.window_rule({
    name  = "windowrule-2",
    tag   = "+browser",
    match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" },
})

hl.window_rule({
    name  = "windowrule-3",
    tag   = "+browser",
    match = { class = "^(chrome-.+-Default)$" }, -- Chrome PWAs
})

hl.window_rule({
    name  = "windowrule-4",
    tag   = "+browser",
    match = { class = "^([Cc]hromium)$" },
})

hl.window_rule({
    name  = "windowrule-5",
    tag   = "+browser",
    match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },
})

hl.window_rule({
    name  = "windowrule-6",
    tag   = "+browser",
    match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" },
})

hl.window_rule({
    name  = "windowrule-7",
    tag   = "+browser",
    match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" },
})

hl.window_rule({
    name  = "windowrule-8",
    tag   = "+browser",
    match = { class = "^(zen-alpha|zen)$" },
})


-- notif tags
hl.window_rule({
    name  = "windowrule-9",
    tag   = "+notif",
    match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" },
})


-- KooL settings tag
hl.window_rule({
    name  = "windowrule-10",
    tag   = "+KooL_Cheat",
    match = { title = "^(KooL Quick Cheat Sheet)$" },
})

hl.window_rule({
    name  = "windowrule-11",
    tag   = "+KooL_Settings",
    match = { title = "^(KooL Hyprland Settings)$" },
})

hl.window_rule({
    name  = "windowrule-12",
    tag   = "+KooL-Settings",
    match = { class = "^(nwg-displays|nwg-look)$" },
})


-- terminal tags
hl.window_rule({
    name  = "windowrule-13",
    tag   = "+terminal",
    match = { class = "^(Alacritty|kitty|kitty-dropterm)$" },
})


-- email tags
hl.window_rule({
    name  = "windowrule-14",
    tag   = "+email",
    match = { class = "^([Tt]hunderbird|org.gnome.Evolution)$" },
})

hl.window_rule({
    name  = "windowrule-15",
    tag   = "+email",
    match = { class = "^(eu.betterbird.Betterbird)$" },
})


-- project tags
hl.window_rule({
    name  = "windowrule-16",
    tag   = "+projects",
    match = { class = "^(codium|codium-url-handler|VSCodium)$" },
})

hl.window_rule({
    name  = "windowrule-17",
    tag   = "+projects",
    match = { class = "^(VSCode|code-url-handler)$" },
})

hl.window_rule({
    name  = "windowrule-18",
    tag   = "+projects",
    match = { class = "^(jetbrains-.+)$" }, -- JetBrains IDEs
})


-- screenshare tags
hl.window_rule({
    name  = "windowrule-19",
    tag   = "+screenshare",
    match = { class = "^(com.obsproject.Studio)$" },
})


-- IM tags
hl.window_rule({
    name   = "windowrule-20",
    tag    = "+im",
    center = true,
    float  = true,
    size   = { "monitor_w*0.6", "monitor_h*0.7" },
    match  = { class = "^([Ff]erdium)$" },
})

hl.window_rule({
    name  = "windowrule-21",
    tag   = "+im",
    match = { class = "^([Ww]hatsapp-for-linux)$" },
})

hl.window_rule({
    name  = "windowrule-22",
    tag   = "+im",
    match = { class = "^(ZapZap|com.rtosta.zapzap)$" },
})

hl.window_rule({
    name  = "windowrule-23",
    tag   = "+im",
    match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" },
})

hl.window_rule({
    name  = "windowrule-24",
    tag   = "+im",
    match = { class = "^(teams-for-linux)$" },
})

hl.window_rule({
    name  = "windowrule-25",
    tag   = "+im",
    match = { class = "^(im.riot.Riot|Element)$" }, -- Element Matrix client
})


-- game tags
hl.window_rule({
    name  = "windowrule-26",
    tag   = "+games",
    match = { class = "^(gamescope)$" },
})

hl.window_rule({
    name  = "windowrule-27",
    tag   = "+games",
    match = { class = "^(steam_app_\\d+)$" },
})


-- gamestore tags
hl.window_rule({
    name  = "windowrule-28",
    tag   = "+gamestore",
    match = { class = "^([Ss]team)$" },
})

hl.window_rule({
    name  = "windowrule-29",
    tag   = "+gamestore",
    match = { title = "^([Ll]utris)$" },
})

hl.window_rule({
    name  = "windowrule-30",
    tag   = "+gamestore",
    match = { class = "^(com.heroicgameslauncher.hgl)$" },
})

-- file-manager tags
hl.window_rule({
    name  = "windowrule-31",
    tag   = "+file-manager",
    match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" },
})

hl.window_rule({
    name  = "windowrule-32",
    tag   = "+file-manager",
    match = { class = "^(app.drey.Warp)$" },
})


-- wallpaper tags
hl.window_rule({
    name  = "windowrule-33",
    tag   = "+wallpaper",
    match = { class = "^([Ww]aytrogen)$" },
})


-- multimedia tags
hl.window_rule({
    name  = "windowrule-34",
    tag   = "+multimedia",
    match = { class = "^([Aa]udacious)$" },
})

hl.window_rule({
    name  = "windowrule-pano-tag",
    tag   = "+multimedia",
    match = { class = "^(pano-scrobbler)$" },
})

-- multimedia-video tags
hl.window_rule({
    name  = "windowrule-35",
    tag   = "+multimedia_video",
    match = { class = "^([Mm]pv|vlc)$" },
})


-- settings tags
hl.window_rule({
    name   = "windowrule-36",
    tag    = "+settings",
    center = true,
    match  = { title = "^(ROG Control)$" },
})

hl.window_rule({
    name  = "windowrule-37",
    tag   = "+settings",
    match = { class = "^(wihotspot(-gui)?)$" }, -- wifi hotspot
})

hl.window_rule({
    name  = "windowrule-38",
    tag   = "+settings",
    match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, -- Disk usage analyzer
})

hl.window_rule({
    name  = "windowrule-39",
    tag   = "+settings",
    match = { class = "^(gnome-disks|wihotspot(-gui)?)$" },
})

hl.window_rule({
    name  = "windowrule-40",
    tag   = "+settings",
    match = { title = "(Kvantum Manager)" },
})

hl.window_rule({
    name  = "windowrule-41",
    tag   = "+settings",
    match = { class = "^(file-roller|org.gnome.FileRoller)$" }, -- archive manager
})

hl.window_rule({
    name  = "windowrule-42",
    tag   = "+settings",
    match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" },
})

hl.window_rule({
    name   = "windowrule-43",
    tag    = "+settings",
    center = true,
    match  = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
})

hl.window_rule({
    name  = "windowrule-44",
    tag   = "+settings",
    match = { class = "^(qt5ct|qt6ct|[Yy]ad)$" },
})

hl.window_rule({
    name  = "windowrule-45",
    tag   = "+settings",
    match = { class = "(xdg-desktop-portal-gtk)" },
})

hl.window_rule({
    name  = "windowrule-46",
    tag   = "+settings",
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
})

hl.window_rule({
    name  = "windowrule-47",
    tag   = "+settings",
    match = { class = "^([Rr]ofi)$" },
})


-- viewer tags
hl.window_rule({
    name  = "windowrule-48",
    tag   = "+viewer",
    match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, -- system monitor
})

hl.window_rule({
    name  = "windowrule-49",
    tag   = "+viewer",
    match = { class = "^(evince)$" }, -- document viewer
})

hl.window_rule({
    name  = "windowrule-50",
    tag   = "+viewer",
    match = { class = "^(eog|org.gnome.Loupe)$" }, -- image viewer
})


-- Some special override rules
hl.window_rule({
    name    = "windowrule-51",
    no_blur = true,
    opacity = "1.0",
    match   = { tag = "multimedia_video*" },
})


-- POSITION
-- windowrule = center,floating:1 # warning, it cause even the menu to float and center.
hl.window_rule({
    name   = "windowrule-52",
    center = true,
    float  = true,
    size   = { "monitor_w*0.65", "monitor_h*0.9" },
    match  = { tag = "KooL_Cheat*" },
})

hl.window_rule({
    name   = "windowrule-53",
    center = true,
    float  = true,
    match  = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" },
})

hl.window_rule({
    name   = "windowrule-54",
    center = true,
    float  = true,
    match  = { tag = "KooL-Settings*" },
})

hl.window_rule({
    name   = "windowrule-55",
    center = true,
    match  = { title = "^(Keybindings)$" },
})

hl.window_rule({
    name   = "windowrule-56",
    center = true,
    size   = { "monitor_w*0.6", "monitor_h*0.7" },
    match  = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
})

hl.window_rule({
    name             = "windowrule-57",
    move             = { "(monitor_w*0.72)", "(monitor_h*0.07)" },
    float            = true,
    opacity          = "0.95 0.75",
    pin              = true,
    keep_aspect_ratio = true,
    match            = { title = "^(Picture-in-Picture)$" },
})

-- hl.window_rule({ match = { title = "^(Firefox)$" }, move = "72% 7%" })

-- windowrule to avoid idle for fullscreen apps
-- hl.window_rule({ match = { class = "^(*)$" }, idle_inhibit = "fullscreen" })
-- hl.window_rule({ match = { title = "^(*)$" }, idle_inhibit = "fullscreen" })
hl.window_rule({
    name          = "windowrule-58",
    idle_inhibit  = "fullscreen",
    match         = { fullscreen = true },
})


-- windowrule move to workspace
hl.window_rule({
    name      = "windowrule-59",
    workspace = "1",
    match     = { tag = "email*" },
})

hl.window_rule({
    name      = "windowrule-60",
    workspace = "2",
    opacity   = "0.9 0.7",
    match     = { tag = "browser*" },
})

-- hl.window_rule({ match = { class = "^([Tt]hunar)$" }, workspace = "3" })
-- hl.window_rule({ match = { tag = "projects*" }, workspace = "3" })
hl.window_rule({
    name      = "windowrule-61",
    workspace = "5",
    match     = { tag = "gamestore*" },
})

hl.window_rule({
    name      = "windowrule-62",
    workspace = "7",
    opacity   = "0.94 0.86",
    match     = { tag = "im*" },
})

hl.window_rule({
    name      = "windowrule-63",
    workspace = "8",
    no_blur   = true,
    fullscreen = true,
    match     = { tag = "games*" },
})


-- windowrule move to workspace (silent)
hl.window_rule({
    name      = "windowrule-64",
    workspace = "4 silent",
    match     = { tag = "screenshare*" },
})

hl.window_rule({
    name      = "windowrule-65",
    workspace = "6 silent",
    match     = { class = "^(virt-manager)$" },
})

hl.window_rule({
    name      = "windowrule-66",
    workspace = "6 silent",
    match     = { class = "^(.virt-manager-wrapped)$" },
})

hl.window_rule({
    name      = "windowrule-67",
    workspace = "9 silent",
    opacity   = "0.94 0.86",
    match     = { tag = "multimedia*" },
})

hl.window_rule({
    name             = "windowrule-pano-silent",
    workspace        = "9 silent",
    no_initial_focus = true,
    match            = { class = "^(pano-scrobbler)$" },
})


-- FLOAT
hl.window_rule({
    name    = "windowrule-68",
    float   = true,
    opacity = "0.9 0.7",
    size    = { "monitor_w*0.7", "monitor_h*0.7" },
    match   = { tag = "wallpaper*" },
})

hl.window_rule({
    name    = "windowrule-69",
    float   = true,
    opacity = "0.8 0.7",
    size    = { "monitor_w*0.7", "monitor_h*0.7" },
    match   = { tag = "settings*" },
})

hl.window_rule({
    name    = "windowrule-70",
    float   = true,
    opacity = "0.82 0.75",
    match   = { tag = "viewer*" },
})

hl.window_rule({
    name  = "windowrule-71",
    float = true,
    match = { class = "([Zz]oom|onedriver|onedriver-launcher)$" },
})

hl.window_rule({
    name  = "windowrule-72",
    float = true,
    match = { class = "(org.gnome.Calculator)", title = "(Calculator)" },
})

hl.window_rule({
    name  = "windowrule-73",
    float = true,
    match = { class = "^(mpv|com.github.rafostar.Clapper)$" },
})

hl.window_rule({
    name  = "windowrule-74",
    float = true,
    match = { class = "^([Qq]alculate-gtk)$" },
})

-- hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, float = true })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, float = true })

-- windowrule - ######### float popups and dialogue #######
hl.window_rule({
    name   = "windowrule-75",
    float  = true,
    center = true,
    match  = { title = "^(Authentication Required)$" },
})

hl.window_rule({
    name  = "windowrule-76",
    float = true,
    match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" },
})

hl.window_rule({
    name  = "windowrule-77",
    float = true,
    match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" },
})

hl.window_rule({
    name  = "windowrule-78",
    float = true,
    match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" },
})


hl.window_rule({
    name   = "windowrule-79",
    float  = true,
    size   = { "monitor_w*0.7", "monitor_h*0.6" },
    center = true,
    match  = { title = "^(Add Folder to Workspace)$" },
})


hl.window_rule({
    name   = "windowrule-80",
    float  = true,
    size   = { "monitor_w*0.7", "monitor_h*0.6" },
    center = true,
    match  = { title = "^(Save As)$" },
})


hl.window_rule({
    name   = "windowrule-81",
    float  = true,
    size   = { "monitor_w*0.7", "monitor_h*0.6" },
    match  = { initial_title = "(Open Files)" },
})


hl.window_rule({
    name   = "windowrule-82",
    float  = true,
    center = true,
    size   = { "monitor_w*0.16", "monitor_h*0.12" },
    match  = { title = "^(SDDM Background)$" }, --KooL's Dots YAD for setting SDDM background
})

-- END of float popups and dialogue #######

-- OPACITY
hl.window_rule({
    name    = "windowrule-83",
    opacity = "0.9 0.8",
    match   = { tag = "projects*" },
})

hl.window_rule({
    name    = "windowrule-84",
    opacity = "0.9 0.8",
    match   = { tag = "file-manager*" },
})

hl.window_rule({
    name    = "windowrule-85",
    opacity = "0.8 0.7",
    match   = { tag = "terminal*" },
})

hl.window_rule({
    name    = "windowrule-86",
    opacity = "0.8 0.7",
    match   = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" },
})

hl.window_rule({
    name    = "windowrule-87",
    opacity = "0.9 0.8",
    match   = { class = "^(deluge)$" },
})

hl.window_rule({
    name    = "windowrule-88",
    opacity = "0.9 0.8",
    match   = { class = "^(seahorse)$" }, -- gnome-keyring gui
})


-- SIZE

-- hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, size = "25% 25%" })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, size = "25% 25%" })

-- PINNING
-- hl.window_rule({ match = { title = "^(Firefox)$" }, pin = true })

-- windowrule - extras

-- BLUR & FULLSCREEN


-- This not gonna take the focus to the window that appears when hovering over some of the parts of the IntelliJ Products
hl.window_rule({
    name             = "windowrule-89",
    no_initial_focus = true,
    match            = { class = "^(jetbrains-*)" },
})

hl.window_rule({
    name             = "windowrule-90",
    no_initial_focus = true,
    match            = { title = "^(wind.*)$" },
})



hl.window_rule({
    name      = "windowrule-91",
    fullscreen = true,
    immediate = true,
    match     = { class = "^(explorer.exe)$", title = "^(WineDesktop.*)$" },
})

hl.window_rule({
    name   = "yazi-custom",
    tag    = "+file-manager",
    float  = true,
    center = true,
    size   = { "monitor_w*0.8", "monitor_h*0.8" },
    match  = { class = "^(yazi-float)$" },
})

hl.window_rule({
    name  = "qq-default-float",
    match = { class = "^(QQ)$" },
    float = true,
})

hl.window_rule({
    name   = "qq-main-tile",
    match  = { class = "^(QQ)$", title = "^(QQ)$" },
    float  = false,
    tile   = true,
})
-- This will gonna make the VS Code bluer like other apps
-- hl.window_rule({ match = { class = "^(code)$" }, opacity = "0.8" })

-- hl.window_rule({ match = { fullscreen = true }, border_color = "rgb(EE4B55) rgb(880808)" })
-- hl.window_rule({ match = { float = true }, border_color = "rgb(282737) rgb(1E1D2D)" })
-- hl.window_rule({ match = { pin = true }, opacity = "0.8 0.8" })

-- 屏幕共享 picker（xdg-desktop-portal-hyprland 弹出的 "Select what to share"）
-- 不加规则时它会莫名跑到 eDP-1 上。下面让它跟随当前使用的显示器；
-- 想固定到某块屏就把 current 换成 "HDMI-A-1" / "eDP-1"（两种写法都已实测可用）
hl.window_rule({
    name    = "share-picker-monitor",
    match   = { class = "^(hyprland-share-picker)$" },
    monitor = "current",
})

-- LAYER RULES
hl.layer_rule({
    name          = "layerrule-1",
    blur          = true,
    ignore_alpha  = 0,
    match         = { namespace = "rofi" },
})

hl.layer_rule({
    name          = "layerrule-2",
    blur          = true,
    ignore_alpha  = 0,
    match         = { namespace = "notifications" },
})

-- [ii 迁移] illogical-impulse (quickshell) 完整 layer rules
-- 来源: dots-hyprland/dots/.config/hypr/hyprland/rules.lua:132-166
-- 取代原 layerrule-3（quickshell:overview, ignore_alpha=0.5），那条会和新规则冲突
-- 注: 原版首条 xray 是 namespace=".*"（作用于所有 layer），这里收窄到 quickshell:.*，
--     避免改变你 rofi / notifications 的既有观感
hl.layer_rule({ match = { namespace = "quickshell:.*" }, xray = true})
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true})
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true})
hl.layer_rule({ match = { namespace = "quickshell:.*" }, ignore_alpha = 0.79})
hl.layer_rule({ match = { namespace = "quickshell:bar" }, animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:actionCenter" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" }, animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:dock" }, animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, animation = "popin 120%"})
hl.layer_rule({ match = { namespace = "quickshell:lockWindowPusher" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade"})
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, ignore_alpha = 1})
hl.layer_rule({ match = { namespace = "quickshell:overview" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:osk" }, animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:polkit" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:popup" }, xray = false}) -- 防止 bar 提示框颜色异常
hl.layer_rule({ match = { namespace = "quickshell:popup" }, ignore_alpha = 1})
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1})
hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" }, animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:regionSelector" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:screenshot" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true})
hl.layer_rule({ match = { namespace = "quickshell:session" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:session" }, ignore_alpha = 0})
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, animation = "slide right"})
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, animation = "slide left"})
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:osk" }, order = -1})
-- Quickshell: waffles（另一套皮肤，默认不用，留着不碍事）
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, animation = "slide top"})
hl.layer_rule({ match = { namespace = "quickshell:wNotificationCenter" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wStartMenu" }, no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, ignore_alpha = 0})
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, no_anim = true})


-- hl.layer_rule({ match = { tag = "notif*" }, ignore_alpha = 0.5 })

-- hl.layer_rule({ match = { class = "^([Rr]ofi)$" }, ignore_zero = true })
-- hl.layer_rule({ match = { class = "^([Rr]ofi)$" }, blur = true })
-- hl.layer_rule({ match = { class = "^([Rr]ofi)$" }, unset = true })
-- hl.layer_rule({ match = { namespace = "rofi" }, ignore_zero = true })

-- hl.layer_rule({ match = { namespace = "overview" }, ignore_zero = true })
-- hl.layer_rule({ match = { namespace = "overview" }, blur = true })
