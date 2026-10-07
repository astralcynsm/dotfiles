-- ════════════════════════════════════════════════════════════════════════════
-- 工作机专属键位 —— F6 截图家族 ×5
--
-- 来源：主力机 UserConfigs/Laptops.lua 第 24-29 行，**逐字保留**。
-- 为什么要搬：用户要求「键位一个不能丢」；这 5 条是肌肉记忆的一部分
-- （主力机键盘没有 PrintScreen 键，截图都绑在 F6 家族上）。
--
-- 调用的是通用层的脚本：configs/.config/hypr/scripts/ScreenShot.sh ✓ 两台机器都有
-- ════════════════════════════════════════════════════════════════════════════

local mainMod = "SUPER"
local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"

-- Screenshot keybindings using F6 (no PrinSrc button)
hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now")) -- screenshot
hl.bind(mainMod .. " + SHIFT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area")) -- screenshot (area)
hl.bind(mainMod .. " + CTRL + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5")) -- screenshot (5 secs delay)
hl.bind(mainMod .. " + ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10")) -- screenshot (10 secs delay)
hl.bind("ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active")) -- screenshot (active window only)
