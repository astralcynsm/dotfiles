-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Environment variables. See https://wiki.hyprland.org/Configuring/Environment-variables/
--
-- 由 UserConfigs/ENVariables.conf 转换为 lua (Hyprland >= 0.55)
-- env = KEY,value -> hl.env("KEY", "value")

-- Set your defaults editor through ENV in ~/.config/hypr/UserConfigs/01-UserDefaults.conf

-- environment-variables
-- Toolkit Backend Variables
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")

--Run SDL2 applications on Wayland.
--Remove or set to x11 if games that provide older versions of SDL cause compatibility issues
-- hl.env("SDL_VIDEODRIVER", "wayland")

-- xdg Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- QT Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Roll back to original gtk platform theme behavior.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
-- hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
-- hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- hyprland-qt-support
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

-- xwayland apps scale fix (useful if you are use monitor scaling).
-- Set same value if you use scaling in Monitors.conf
-- 1 is 100% 1.5 is 150%
-- see https://wiki.hyprland.org/Configuring/XWayland/
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")

-- Bibata-Modern-Ice-Cursor
-- NOTE! You must have the hyprcursor version to activate this.
-- https://wiki.hyprland.org/Hypr-Ecosystem/hyprcursor/
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

-- firefox
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- electron >28 apps (may help) ##
-- https://www.electronjs.org/docs/latest/api/environment-variables
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- auto selects Wayland if possible, X11 otherwise

-- NVIDIA
-- This is from Hyprland Wiki. Below will be activated nvidia gpu detected
-- See hyprland wiki https://wiki.hyprland.org/Nvidia/#environment-variables

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GSK_RENDERER", "ngl")
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", os.getenv("HOME") .. "/.local/state/quickshell/.venv")
-- [ii 迁移] quickshell 配置名。ii 的脚本路径和 IPC 调用靠这个变量定位（$qsConfig）
hl.env("qsConfig", "ii")

hl.env("XDG_MENU_PREFIX", "arch-") -- 或者 kf6- 取决于你上面链接的文件名前缀

-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card2:/dev/dri/card1")
-- additional ENV's for nvidia. Caution, activate with care
-- hl.env("GBM_BACKEND", "nvidia-drm")

-- hl.env("__GL_GSYNC_ALLOWED", "1") --adaptive Vsync
-- hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
-- hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
-- hl.env("WLR_DRM_NO_ATOMIC", "1")

-- FOR VM and POSSIBLY NVIDIA
-- LIBGL_ALWAYS_SOFTWARE software mesa rendering
-- hl.env("LIBGL_ALWAYS_SOFTWARE", "1") -- Warning. May cause hyprland to crash
-- hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- nvidia firefox (for hardware acceleration on FF)?
-- check this post https://github.com/elFarto/nvidia-vaapi-driver#configuration
-- hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
-- hl.env("EGL_PLATFORM", "wayland")

-- #### Aquamarine Environment Variables #### ( Hyprland > 0.45 )
-- https://wiki.hyprland.org/Configuring/Environment-variables/#aquamarine-environment-variables----ref-httpsgithubcomhyprwmaquamarineblobmaindocsenvmd---
-- hl.env("AQ_TRACE", "1") -- Enables more verbose logging.
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0") -- Set an explicit list of DRM devices (GPUs) to use. It's a colon-separated list of paths, with the first being the primary. E.g. /dev/dri/card1:/dev/dri/card0
-- hl.env("AQ_MGPU_NO_EXPLICIT", "1") -- Disables explicit syncing on mgpu buffers
-- hl.env("AQ_NO_MODIFIERS", "1") -- Disables modifiers for DRM buffers

-- #### Hyprland Environment Variables ####
-- https://wiki.hyprland.org/Configuring/Environment-variables/#hyprland-environment-variables
-- hl.env("HYPRLAND_TRACE", "1") -- Enables more verbose logging.
-- hl.env("HYPRLAND_NO_RT", "1") -- Disables realtime priority setting by Hyprland.
-- hl.env("HYPRLAND_NO_SD_NOTIFY", "1") -- If systemd, disables the 'sd_notify' calls.
-- hl.env("HYPRLAND_NO_SD_VARS", "1") -- Disables management of variables in systemd and dbus activation environments.

-- hl.env("http_proxy", "http://127.0.0.1:7897")
-- hl.env("https_proxy", "http://127.0.0.1:7897")
-- hl.env("HTTPS_PROXY", "http://127.0.0.1:7897")
-- hl.env("HTTP_PROXY", "http://127.0.0.1:7897")
-- hl.env("all_proxy", "socks5://127.0.0.1:7897")
-- hl.env("no_proxy", "localhost,127.0.0.1,::1")

-- Fcitx5 环境变量
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")
