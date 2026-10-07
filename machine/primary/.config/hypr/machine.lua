-- ★ 机器特定层 —— 换机器只替换本文件，configs/ 下的通用配置不动
--
-- 在 ~/.dotfiles 里，本文件对应 machine/<profile>/.config/hypr/machine.lua
--   machine/primary/ = 主力机（HP OMEN 笔记本，i5-13500HX + RTX 4060 Max-Q，混合显卡）
--   machine/work/    = 工作机（Fedora 台式机，i9-13900KF + RTX 3050，单卡无核显输出）
--
-- hyprland.lua 在最后 require 本文件，所以这里的内容优先级最高。

-- 笔记本特有：xf86 功能键（键盘背光/屏幕亮度/飞行模式/华硕功能键）+ F6 截图家族 + 触摸板设备开关
-- 台式机没有这些，迁移时整段不要
require("UserConfigs/Laptops")

-- 合盖时禁用内屏。当前整个文件是注释状态（无实际作用），保留是为了留个位置
require("UserConfigs/LaptopDisplay")

-- nwg-displays 生成：monitor= 与 workspace→monitor 分配
-- ⚠️ 这两个文件是机器特定的，换机器必须重写。改了之后不要再在 nwg-displays 里点 apply（会覆盖）
require("monitors")
require("workspaces")
