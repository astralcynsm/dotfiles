-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Default Keybinds
-- visit https://wiki.hyprland.org/Configuring/Binds/ for more info
--
-- 由 configs/Keybinds.conf 转换为 lua (Hyprland >= 0.55)
-- dispatcher 映射:
--   exec        -> hl.dsp.exec_cmd()
--   killactive  -> hl.dsp.window.close()
--   layoutmsg   -> hl.dsp.layout(msg)
--   movefocus   -> hl.dsp.focus({ direction = ... })
--   workspace   -> hl.dsp.focus({ workspace = ... })
--   movetoworkspacesilent -> hl.dsp.window.move({ workspace = ..., follow = false })

-- /* ---- ✴️ Variables ✴️ ---- */  --
local mainMod = "SUPER"
local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"
local UserConfigs = os.getenv("HOME") .. "/.config/hypr/UserConfigs"
local UserScripts = os.getenv("HOME") .. "/.config/hypr/UserScripts"

hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("hyprctl dispatch exit 0")) -- exit Hyprland
hl.bind(mainMod .. " + Q", hl.dsp.window.close()) -- close active (not kill)
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh")) -- Kill active process
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh")) -- screen lock
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh")) -- power menu
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw")) -- swayNC notification panel
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scriptsDir .. "/Kool_Quick_Settings.sh")) -- Settings Menu KooL Hyprland Settings

-- Master Layout
hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"))
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"))
hl.bind(mainMod .. " + J", hl.dsp.layout("cyclenext"))
hl.bind(mainMod .. " + K", hl.dsp.layout("cycleprev"))
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"))

-- Dwindle Layout
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit")) -- only works on dwindle layout
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle

-- Works on either layout (Master or Dwindle)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.3"))

-- group
hl.bind(mainMod .. " + G", hl.dsp.group.toggle()) -- toggle group
hl.bind(mainMod .. " + CTRL + tab", hl.dsp.group.next()) -- change focus to another window (原 changegroupactive)

-- Cycle windows if floating bring to top
hl.bind("ALT + tab", hl.dsp.window.cycle_next())
hl.bind("ALT + tab", hl.dsp.window.bring_to_top())

-- Special Keys / Hot Keys
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"), { locked = true, repeating = true }) -- volume up
hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"), { locked = true, repeating = true }) -- volume down
hl.bind("xf86AudioMicMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true }) -- mic mute
hl.bind("xf86audiomute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"), { locked = true }) -- mute
hl.bind("xf86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true }) -- sleep button
hl.bind("xf86Rfkill", hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"), { locked = true }) -- Airplane mode

-- media controls using keyboards
-- hl.bind("xf86AudioPlayPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("xf86AudioPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("xf86AudioPlay", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("xf86AudioNext", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"), { locked = true })
hl.bind("xf86AudioPrev", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"), { locked = true })
hl.bind("xf86audiostop", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"), { locked = true })

-- Screenshot keybindings NOTE: You may need to press Fn key as well
-- [2026-09-20] 改成 --now-focused：只截当前（鼠标所在）那块屏，不再把两块屏拼成一张。
-- 想抓两块拼一起的仍然有 Super+F6 和 Super+Ctrl+Print（它们还走 --now / --in5）。
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now-focused")) -- screenshot (current monitor only)
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area")) -- screenshot (area)
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5")) -- screenshot (5 secs delay)
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10")) -- screenshot (10 secs delay)
hl.bind("ALT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active")) -- screenshot (active window only)

-- screenshot with swappy (another screenshot tool)
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy")) --screenshot (swappy)

-- Resize windows
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Move windows
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }))

-- Swap windows
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.swap({ direction = "d" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Workspaces related
hl.bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special())

-- The following mappings use the key codes to better support various keyboard layouts
-- 1 is code:10, 2 is code 11, etc
-- Switch workspaces with mainMod + [0-9]
hl.bind(mainMod .. " + code:10", hl.dsp.focus({ workspace = 1 })) -- NOTE: code:10 = key 1
hl.bind(mainMod .. " + code:11", hl.dsp.focus({ workspace = 2 })) -- NOTE: code:11 = key 2
hl.bind(mainMod .. " + code:12", hl.dsp.focus({ workspace = 3 })) -- NOTE: code:12 = key 3
hl.bind(mainMod .. " + code:13", hl.dsp.focus({ workspace = 4 })) -- NOTE: code:13 = key 4
hl.bind(mainMod .. " + code:14", hl.dsp.focus({ workspace = 5 })) -- NOTE: code:14 = key 5
hl.bind(mainMod .. " + code:15", hl.dsp.focus({ workspace = 6 })) -- NOTE: code:15 = key 6
hl.bind(mainMod .. " + code:16", hl.dsp.focus({ workspace = 7 })) -- NOTE: code:16 = key 7
hl.bind(mainMod .. " + code:17", hl.dsp.focus({ workspace = 8 })) -- NOTE: code:17 = key 8
hl.bind(mainMod .. " + code:18", hl.dsp.focus({ workspace = 9 })) -- NOTE: code:18 = key 9
hl.bind(mainMod .. " + code:19", hl.dsp.focus({ workspace = 10 })) -- NOTE: code:19 = key 0

-- Move active window and follow to workspace mainMod + SHIFT [0-9]
hl.bind(mainMod .. " + SHIFT + code:10", hl.dsp.window.move({ workspace = 1 })) -- NOTE: code:10 = key 1
hl.bind(mainMod .. " + SHIFT + code:11", hl.dsp.window.move({ workspace = 2 })) -- NOTE: code:11 = key 2
hl.bind(mainMod .. " + SHIFT + code:12", hl.dsp.window.move({ workspace = 3 })) -- NOTE: code:12 = key 3
hl.bind(mainMod .. " + SHIFT + code:13", hl.dsp.window.move({ workspace = 4 })) -- NOTE: code:13 = key 4
hl.bind(mainMod .. " + SHIFT + code:14", hl.dsp.window.move({ workspace = 5 })) -- NOTE: code:14 = key 5
hl.bind(mainMod .. " + SHIFT + code:15", hl.dsp.window.move({ workspace = 6 })) -- NOTE: code:15 = key 6
hl.bind(mainMod .. " + SHIFT + code:16", hl.dsp.window.move({ workspace = 7 })) -- NOTE: code:16 = key 7
hl.bind(mainMod .. " + SHIFT + code:17", hl.dsp.window.move({ workspace = 8 })) -- NOTE: code:17 = key 8
hl.bind(mainMod .. " + SHIFT + code:18", hl.dsp.window.move({ workspace = 9 })) -- NOTE: code:18 = key 9
hl.bind(mainMod .. " + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 })) -- NOTE: code:19 = key 0
hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "-1" })) -- brackets [
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" })) -- brackets ]

-- Move active window to a workspace silently mainMod + CTRL [0-9]
hl.bind(mainMod .. " + CTRL + code:10", hl.dsp.window.move({ workspace = 1, follow = false })) -- NOTE: code:10 = key 1
hl.bind(mainMod .. " + CTRL + code:11", hl.dsp.window.move({ workspace = 2, follow = false })) -- NOTE: code:11 = key 2
hl.bind(mainMod .. " + CTRL + code:12", hl.dsp.window.move({ workspace = 3, follow = false })) -- NOTE: code:12 = key 3
hl.bind(mainMod .. " + CTRL + code:13", hl.dsp.window.move({ workspace = 4, follow = false })) -- NOTE: code:13 = key 4
hl.bind(mainMod .. " + CTRL + code:14", hl.dsp.window.move({ workspace = 5, follow = false })) -- NOTE: code:14 = key 5
hl.bind(mainMod .. " + CTRL + code:15", hl.dsp.window.move({ workspace = 6, follow = false })) -- NOTE: code:15 = key 6
hl.bind(mainMod .. " + CTRL + code:16", hl.dsp.window.move({ workspace = 7, follow = false })) -- NOTE: code:16 = key 7
hl.bind(mainMod .. " + CTRL + code:17", hl.dsp.window.move({ workspace = 8, follow = false })) -- NOTE: code:17 = key 8
hl.bind(mainMod .. " + CTRL + code:18", hl.dsp.window.move({ workspace = 9, follow = false })) -- NOTE: code:18 = key 9
hl.bind(mainMod .. " + CTRL + code:19", hl.dsp.window.move({ workspace = 10, follow = false })) -- NOTE: code:19 = key 0
hl.bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = false })) -- brackets [
hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false })) -- brackets ]

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true }) -- NOTE: mouse:272 = left click
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- NOTE: mouse:273 = right click
