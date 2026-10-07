-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --

-- NOTE: THIS IS NOT BEING SOURCED by hyprland
-- It is only here as a guide if you want to do it manually
-- The file you should edit is ~/.config/hypr/workspaces.conf
-- Since that is the work space rules being sourced by hyprland
-- use nwg-displays to handle your workspace rules.
--
-- 由 UserConfigs/WorkSpaceRules.conf 转换为 lua (Hyprland >= 0.55)
-- workspace = X, monitor:Y -> hl.workspace_rule({ workspace = "X", monitor = "Y" })

-- You can set workspace rules to achieve workspace-specific behaviors.
-- For instance, you can define a workspace where all windows are drawn without borders or gaps.

-- https://wiki.hyprland.org/Configuring/Workspace-Rules/

-- Assigning workspace to a certain monitor. Below are just examples
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "8", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })


-- example rules (from wiki)
-- hl.workspace_rule({ workspace = "3", rounding = false, decorate = false })
-- hl.workspace_rule({ workspace = "name:coding", rounding = false, decorate = false, gaps_in = 0, gaps_out = 0, border = false, monitor = "DP-1" })
-- hl.workspace_rule({ workspace = "8", border_size = 8 })
-- hl.workspace_rule({ workspace = "name:Hello", monitor = "DP-1", default = true })
-- hl.workspace_rule({ workspace = "name:gaming", monitor = "desc:Chimei Innolux Corporation 0x150C", default = true })
-- hl.workspace_rule({ workspace = "5", on_created_empty = "[float] firefox" })
-- hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })
