-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Commands and Apps to be executed at launch
--
-- 由 UserConfigs/Startup_Apps.conf 转换为 lua (Hyprland >= 0.55)
-- exec-once -> hl.on("hyprland.start", function() hl.exec_cmd(...) end)
-- 注: hl.exec_cmd 本身异步执行, 原命令末尾的 & 已移除

local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"
local UserScripts = os.getenv("HOME") .. "/.config/hypr/UserScripts"

local wallDIR = os.getenv("HOME") .. "/Pictures/wallpapers"
local lock = scriptsDir .. "/LockScreen.sh"
local AutoChange = UserScripts .. "/WallpaperAutoChange.sh"
local livewallpaper = ""

hl.on("hyprland.start", function()
    -- wallpaper stuff
    -- [ii 迁移] awww-daemon 已停用。壁纸现在是 ii 的 QML 图层
    -- （Background.qml 读 config.json 的 background.wallpaperPath），
    -- awww 会和它在同一个 layer 上抢着画，所以必须让位。
    -- hl.exec_cmd("awww-daemon --format xrgb")
    --
    -- 视频壁纸（需要 mpvpaper，当前未安装）:
    -- hl.exec_cmd("mpvpaper '*' -o \"load-scripts=no no-audio --loop\" " .. livewallpaper)

    -- wallpaper random（换壁纸统一走 theme-switcher，见 ~/.config/theme-switcher/README.md）
    -- hl.exec_cmd(AutoChange .. " " .. wallDIR) -- random wallpaper switcher every 30 minutes

    -- Startup
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    -- Polkit (Polkit Gnome / KDE)
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")

    -- starup apps
    hl.exec_cmd("nm-applet --indicator")
    -- hl.exec_cmd("swaync")
    -- hl.exec_cmd("ags")
    hl.exec_cmd("blueman-applet")
    -- hl.exec_cmd("rog-control-center")
    -- hl.exec_cmd("waybar")
    -- hl.exec_cmd("hyprpanel") -- [ii 迁移] 废弃，改用 quickshell
    -- hl.exec_cmd("quickshell")
    -- [帧率修复] QSG_RENDER_LOOP=threaded 必须显式指定，否则 bar 动画只有 62.5fps
    -- 原因：Wayland+EGL → Qt 走 GLES2 后端 → QSGRenderLoop::instance() 里 GLES2
    -- 需要平台声明 ThreadedOpenGL capability，未声明就退回 basic render loop，
    -- 而 basic 模式下动画驱动器退化到 Qt QUnifiedTimer 的 16ms 兜底节拍（=62.5fps）。
    -- 显式 threaded 后跟随 vsync 跑满屏幕刷新率（实测 180.5fps @180Hz）。
    -- 代价：动画运行时 GPU 功耗约 +8W；静态时无额外开销（Qt 按需渲染）。
    --
    -- [保活] 这行原来在这里直接起 quickshell，现在改由 systemd 管：
    --   ~/.config/systemd/user/quickshell-ii.service（Restart=always，上面那个环境变量搬进了 unit），
    --   随本文件末尾的 hyprland-session.target 一起启动。
    -- 原因：exec 起的进程没有守护，被误杀/自行退出后就再也不会回来（2026-09-22 的 Super+C 事故），
    --   而 quickshell 在「一个窗口都不剩」时会自行退出（shell.qml 的 ShellRoot 没有 keepAlive）。
    -- ⚠ 不要在这里再起一份：同名 config 的第二个实例会被 instance.lock 挡掉，
    --   结果是 systemd 那份退出 → Restart=always 反复重启，两个启动路径互相打架。
    -- hl.exec_cmd("env QSG_RENDER_LOOP=threaded qs -c ii") -- illogical-impulse (quickshell) UI 引擎

    -- clipboard manager
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("linuxqq-clipsync")

    -- Rainbow borders
    -- hl.exec_cmd(UserScripts .. "/RainbowBorders.sh")

    -- hl.exec_cmd("easyeffects --gapplication-service")
    -- Starting hypridle to start hyprlock
    hl.exec_cmd("hypridle")

    -- Word Counter
    -- [ii 迁移] 改由 systemd 托管（rime_counter.service，指向同一个 rust 二进制）。
    -- 由文件末尾的 hyprland-session.target 连带拉起，别在这里再起一个，
    -- 两个实例会抢同一个 /tmp/rime_status.json。
    -- Here are list of features available but disabled by default
    -- [ii 迁移] 固定壁纸不再用 awww，改成设 ii 的 config.json 后由 theme-switcher 应用:
    --   ~/.config/theme-switcher/switch.sh --wallpaper ~/Pictures/wallpapers/xxx.png

    -- gnome polkit for nixos
    -- hl.exec_cmd(scriptsDir .. "/Polkit-NixOS.sh")

    -- xdg-desktop-portal-hyprland (should be auto starting. However, you can force to start)
    -- hl.exec_cmd(scriptsDir .. "/PortalHyprland.sh")

    -- custom ones
    -- hl.exec_cmd("mako") -- [ii 迁移] ii 自带通知守护，mako 会争抢 org.freedesktop.Notifications
    hl.exec_cmd("mihomo-party")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("fcitx5 -d --replace")
    hl.exec_cmd("/usr/lib/pam_kwallet_init")
    hl.exec_cmd("/usr/lib/kwalletd6")

    hl.exec_cmd("pano-scrobbler --minimized")

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    -- [ii 迁移] 不能直接 start graphical-session.target —— 它是 RefuseManualStart
    -- 的（"may be requested by dependency only"），原来这行一直是空转。
    -- 改成启动自己的 session target，由它 BindsTo 把 graphical-session.target
    -- 拉起来；WantedBy=graphical-session.target 的单元（rime_counter、solaar）随之启动。
    hl.exec_cmd("systemctl --user start hyprland-session.target")
end)
