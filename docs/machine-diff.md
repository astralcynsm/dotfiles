# 机器差异清单：HP OMEN 笔记本（主力机）→ Fedora 台式机（工作机）

> 全部条目基于 2026-10-08 对仓库内容的逐文件核对，不是拍脑袋的清单。
> 「工作机对策」列写的是**已做了什么 / P1–P3 要做什么**。

## 总览

| | 主力机（primary） | 工作机（work） |
|---|---|---|
| 形态 | HP OMEN 笔记本，i5-13500HX | 台式机，i9-13900KF |
| GPU | RTX 4060 Max-Q（混合显卡） | RTX 3050，**单卡无核显输出** |
| 显示器 | HDMI-A-1 1920x1080@180 + eDP-1 2560x1440@240 scale 1.6 | **未知，P1 实测** |
| 输入 | 笔记本键盘 + 触摸板 + MCHOSE G7 鼠标 + 数位板 | 未知，P1 实测 |
| 系统 | Arch / EndeavourOS | Fedora Workstation 44 |

## A. 整块剥离（已归入 machine/primary，不进通用层）

| 内容 | 现在在哪 | 工作机对策 |
|---|---|---|
| `machine.lua`（机器层入口，`hyprland.lua` 末尾 require 它） | `machine/primary/.config/hypr/` | **work 版已提供**（见下 B 节），P3 核对 |
| `Laptops.lua`：8 条 xf86 硬件键（键盘背光 ×2、`xf86Launch1/3/4` 的 asusctl/rog 功能、屏幕亮度 ×2、触摸板开关）+ 触摸板 `hl.device` 段 | `machine/primary/…/UserConfigs/` | 不加载（work machine.lua 不 require）|
| `LaptopDisplay.lua`（合盖禁用内屏；全身是一段注释） | 同上 | 同上 |
| `monitors.lua`（nwg-displays 生成：HDMI-A-1 + eDP-1 的 `position = "-1600x0"`） | `machine/primary/.config/hypr/` | **P1 实测真实输出名 → P3 重写** work 版 |
| `workspaces.lua`（含 9/10 号工作区 → eDP-1 的分配） | 同上 | 同上 |
| `Monitor_Profiles/`（显示器方案档案） | 同上 | 用不上，留档 |

## B. 带走（不是硬件绑定，是用户习惯）

| 内容 | 为什么带 | 落点 |
|---|---|---|
| **F6 截图家族 ×5**：`SUPER+F6`（立即）、`+SHIFT+F6`（区域）、`+CTRL+F6`（5 秒延迟）、`+ALT+F6`（10 秒延迟）、`ALT+F6`（当前窗口） | 它们躺在 `Laptops.lua` 里只是因为该文件是"笔记本杂项"的集散地，**与硬件无关**。按「键位一个不能丢」带走 | 已放 `machine/work/.config/hypr/UserConfigs/WorkKeybinds.lua`（原件逐字复制，已是 Lua 现代形式），由 work 的 `machine.lua` require。**用户若不要，删这个文件的对应行即可** |
| NVIDIA 环境变量 ×4：`LIBVA_DRIVER_NAME=nvidia`、`__GLX_VENDOR_LIBRARY_NAME=nvidia`、`NVD_BACKEND=direct`、`GSK_RENDERER=ngl` | 工作机也是 N 卡 | 已在**通用层** `configs/.config/hypr/UserConfigs/ENVariables.lua`（59–62 行），不需要动 |

## C. 明知差异：留着无害（暂时不处理）

| 内容 | 位置 | 判定 |
|---|---|---|
| MCHOSE G7 鼠标、OpenTabletDriver 虚拟数位板 ×2（**硬编码 `output = "HDMI-A-1"`**）、Wacom 笔 的设备规则 | `configs/.config/hypr/UserConfigs/UserSettings.lua` 149–169 行（**通用层**） | 工作机没有这些设备 → `hl.device` 对不存在的设备名是 no-op，**无害**。洁癖做法是把它们搬去 machine 层，但那要动主力机活配置 + 重导出 —— 值不值等 P3 后用户拍板 |
| 触摸板 input 参数（`touchpad`/`touchdevice`/`tablet` 段） | 同上 57–75 行 | 同上：无触摸板 = no-op |
| `TouchPad.sh`、`BrightnessKbd.sh` 脚本本体 | `configs/.config/hypr/scripts/`（通用层） | 它们的**绑定**在 `Laptops.lua`（机器层）→ 工作机不会调用。`TouchPad.sh` 的旧式调用已在源机修掉（`hl.device` + 真设备名动态探测，2026-10-08，R7）；工作机无触摸板时脚本会弹「未找到设备」并退出 |
| `WorkSpaceRules.lua` | `configs/.config/hypr/UserConfigs/` | **孤儿文件**：全树没有任何 `require` 指向它（hyprland.lua 里的引用是注释）。无害，留档——别被它误导 |
| 合盖 switch 那 4 行 | `Laptops.lua` 40–53 行 | 已全部是注释 |

## D. 工作机专属（P1–P3 产出，不来自主力机）

- `machine/work/profile.toml` —— P1 摸底回填（硬件/显示器/驱动/残留）
- `machine/work/.config/hypr/monitors.lua`、`workspaces.lua` —— P1 实测 → P3 重写
  （work 版现已放**占位骨架**，先保证 `require` 不炸，P3 填真值）
- `machine/work/.config/hypr/machine.lua` —— 已提供初版（不 require 笔记本件），P3 核对

## E. 待 P1 实测回填

| 项 | 怎么测 |
|---|---|
| 显示器输出名/分辨率/刷新率/缩放 | `hyprctl monitors -j`（Hyprland 装了之后）或 `wlr-randr` |
| 显卡驱动状态 | `nvidia-smi`、`lspci -k \| grep -A3 VGA` |
| GNOME 时期的 Hyprland 残留 | COPR 列表、`~/.config/hypr` 是否已存在、旧 systemd 单元 |
| 键鼠设备名（若要写 `hl.device` 规则） | `hyprctl devices` |
| 挂载路径习惯 | 外接盘挂哪里（`/run/media/$USER/…` vs `/mnt`），涉及 vault-commit 等脚本 |
