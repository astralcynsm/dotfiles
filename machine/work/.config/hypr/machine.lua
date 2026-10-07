-- ════════════════════════════════════════════════════════════════════════════
-- ★ 机器特定层 —— 工作机（Fedora 台式机，i9-13900KF + RTX 3050，独显无核显输出）
--
-- 仓库里: machine/work/.config/hypr/machine.lua
-- 部署后: ~/.config/hypr/machine.lua
--
-- hyprland.lua 在**最后** require 本文件 —— 这里的内容优先级最高。
-- ⚠️ 本文件缺失 = Hyprland 起不来。
--
-- 和主力机（HP OMEN 笔记本）的差异，就体现在这里 require 了什么：
--   * **不** require UserConfigs/Laptops        ← xf86 亮度键/华硕键/触摸板，台式机没有
--   * **不** require UserConfigs/LaptopDisplay  ← 合盖逻辑，台式机没有
--   * monitors / workspaces 是重写的（工作机显示器不同）
-- ════════════════════════════════════════════════════════════════════════════

-- F6 截图家族 ×5 —— 从主力机 Laptops.lua 原样搬来的一张"键位习惯"保单。
-- （主力机上是 F6 而非 PrintScreen：笔记本键盘没那个键。照搬 = 习惯不断；
--   工作机键盘若想另加 PrintScreen，是**加**不是换。）
require("UserConfigs/WorkKeybinds")

-- nwg-displays 生成的两份：monitor= 与 workspace→monitor 分配
-- ⚠️ 现在还是骨架（只有注释）—— 单显示器时这样也是能跑的（Hyprland 自动配置），
--    P1 实测显示器后填真值；改完不要再在 nwg-displays 里点 apply（会覆盖）
require("monitors")
require("workspaces")
