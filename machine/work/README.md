# machine/work —— 工作机覆盖层

**这是什么**：`machine/<profile>/` 是**覆盖层**。`scripts/apply-profile.sh`（默认 profile=work）
先铺通用层 `configs/`，再铺本目录，同名文件**后者覆盖前者**。

工作机 = Fedora Workstation 44 台式机（i9-13900KF + RTX 3050，独显无核显输出）。

---

## 现在这里有什么

| 文件 | 状态 |
|---|---|
| `.config/hypr/machine.lua` | ✅ 桌面版（**不** require 笔记本那两个文件） |
| `.config/hypr/UserConfigs/WorkKeybinds.lua` | ✅ F6 截图家族 ×5（从主力机 Laptops.lua 原样搬；键位一个不能丢） |
| `.config/hypr/monitors.lua` | ⚠️ **骨架**（只有注释）—— P1 实测显示器后填真值 |
| `.config/hypr/workspaces.lua` | ⚠️ **骨架** —— 同上 |
| `profile.toml` | ⚠️ **模板** —— P1 摸底后填 |

## 阶段 1（P1）要在这里产出什么

1. **填 `profile.toml`** —— 硬件实况（显示器型号/分辨率/刷新率、驱动、残留）。
2. **重写 `monitors.lua`** —— 语法照 `machine/primary/` 的抄：
   ```lua
   hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })
   ```
   拿真值的最稳路径：进 Hyprland 会话 → `nwg-displays` 摆好 → Apply → 它生成的
   文件里的 `hl.monitor({...})` 就是答案（**注意它也会重写 workspaces.lua**）。
3. **重写 `workspaces.lua`** —— 单显示器**可以一条都不写**（全落在一块屏上，这是合法状态）。
   多显示器才需要 `hl.workspace_rule({ workspace = "N", monitor = "..." })`。
   ⚠️ 主力机上 **ws 8 是游戏工作区**（WindowRules.lua 里 tag=`games*` 的窗口都丢到 8）——
   工作机若不沿用这个约定，改 WindowRules.lua 前先想清楚。
4. **核对 `machine.lua`** —— 确认它没有 require 笔记本文件；确认它 require 的文件都真实存在
   （缺一个 Hyprland 直接起不来，`scripts/doctor.sh` 的 10.9 会抓）。

## 还欠一个文件（P1 或 P7 时建）

`.config/vault-commit/vaults.json` —— Obsidian 库路径，**机器特定**（主力机在 `/mnt/Storage/...`）。
格式照 `machine/primary/.config/vault-commit/vaults.json` 抄。工作机的库在哪，P1 实测后填。

## 纪律

- **别交付未验证的 Lua**：这个目录里的文件会被原样部署到 `~/.config/hypr/`，
  语法错误 = 桌面起不来。改完至少 `hyprctl configerrors` 干净再提交。
- **改动往哪放**：只在这台机器上成立的（显示器名、路径）→ 放本目录；两台机器都成立的
  （键位、脚本、主题）→ 放 `configs/`。回流协议见 `docs/upstream-sync.md`。
- 本目录的改动请 **commit + push 回仓库**，主力机 `git pull` 后才看得到（否则会被下次导出覆盖）。
