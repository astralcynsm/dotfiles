-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- always refer to Hyprland wiki
-- https://wiki.hyprland.org/
--
-- 由 hyprland.conf 转换为 lua (Hyprland >= 0.55)
-- 转换规则:
--   source        -> require("相对路径")     (相对于本文件所在目录, 不含 .lua 扩展名)
--   exec-once     -> hl.on("hyprland.start", function() ... end)
--   $变量         -> local 变量 / 全局变量
--
-- ⚠️ Hyprland >= 0.56 彻底移除了 hyprctl dispatch 的字符串形式。
--    运行时派发必须写 lua 形式: hyprctl dispatch 'hl.dsp.dpms("on")'
--    详见 ~/.dotfiles/docs/known-issues.md

-- Sourcing external config files
-- 原: $configs = $HOME/.config/hypr/configs  (该变量仅用于 hyprlang 的 source 路径, lua 中直接用相对路径 require)
require("configs/Keybinds") -- Pre-configured keybinds

-- ## This is where you want to start tinkering
-- 原: $UserConfigs = $HOME/.config/hypr/UserConfigs
require("UserConfigs/Startup_Apps") -- put your start-up packages on this file

require("UserConfigs/ENVariables") -- Environment variables to load

-- require("UserConfigs/Monitors") -- Its all about your monitor config (old dots) will remove on push to main
-- require("UserConfigs/WorkspaceRules") -- Hyprland workspaces (old dots) will remove on push to main

require("UserConfigs/WindowRules") -- all about Hyprland Window Rules and Layer Rules

require("UserConfigs/UserDecorations") -- Decorations config file

require("UserConfigs/UserAnimations") -- Animation config file

require("UserConfigs/UserKeybinds") -- Put your own keybinds here

require("UserConfigs/UserSettings") -- Main Hyprland Settings.

require("UserConfigs/01-UserDefaults") -- settings for User defaults apps

-- ★ 机器特定层：monitors / workspaces / 笔记本特有内容全在这里
-- 换机器只替换 machine.lua，上面这些通用配置不用动。见 ~/.dotfiles/machine/
require("machine")

-- 注：原来这里还有一个 hl.on("hyprland.start", ...) 调 initial-boot.sh，
-- 但该脚本文件从来不存在（且 .initial_startup_done 标记也在），是空操作，已删除。
