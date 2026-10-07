# cynsm dotfiles —— 工作机 agent 操作手册

## 你是谁

你是 **Fedora 工作机**（profile 名 `work`）上的执行会话。

源机是一台 EndeavourOS 笔记本（profile 名 `primary`），**不在场**——你联系不到它，
也无法从它那里取任何东西。本仓库是那台机器上**已在稳定运行**的桌面配置的快照，
外加一份迁移方案。

所以：**你不是在开发一个新项目，你是在把一套已经跑通的桌面复原到这台机器上。**
遇到"为什么这么写"的疑问，默认答案是"因为在那台机器上验证过，别改"，
而不是"我觉得这样更好"。

## 第一件事

读 `MIGRATION.md` **顶部的状态块**，那里写着当前阶段和下一步。
不要跳过它直接动手。

---

## 硬约束

违反任何一条都会造成难以回退的损害。

1. **不跑不带参数的 `dnf upgrade`。** 只允许升级点名的包。
   **Hyprland 与 quickshell 相关包永不升级** —— 这套配置绑在 Hyprland 0.56 的
   Lua API 语义上，0.57 一旦改 API 就全废。见 `docs/known-issues.md` R1。

2. **不动 GDM。** 不装 greetd / nwg-hello，不改 `/etc/gdm/custom.conf` 的
   `WaylandEnable`，不换登录器。GDM 的 GNOME 会话是**唯一的退路**，全程保留。

3. **不全局设 `QT_IM_MODULE` / `GTK_IM_MODULE`。** 只给 `quickshell-ii.service`
   单独设。原因写在那个 unit 的注释里：Wayland 下全局设会绕过 text-input 协议，
   fcitx5 官方不建议。`/etc/environment` 或 `environment.d` 里放这几个变量 = 错。

4. **不自行同步 ii 上游。** 同步只在源机上做（补丁知识在那边）。
   你要做的只是 `git pull` + `apply-profile.sh`。见 `docs/upstream-sync.md`。

5. **不用 `rsync --delete`** 往任何 `~/.config` 目录里同步。
   会删掉 ii 运行期生成的文件。`apply-profile.sh` 已经刻意不用它。

6. **不编造 API。** Hyprland 的 Lua API 以 `/usr/share/hypr/stubs/hl.meta.lua`
   为唯一权威。找不到对应就如实记录"该功能在 0.56 上不可用"，**不要猜一个名字写上去**。

7. **改源头，不改生成物。** `~/.config/hypr/colors.lua`、
   `~/.local/state/quickshell/user/generated/*`、`hyprlock/colors.conf` 都是
   matugen / 主题切换器**生成**的。改它们等于没改——下次换壁纸就被覆盖。

---

## 目录地图

| 路径 | 一句话 |
|---|---|
| `configs/` | 通用层。目录结构镜像 `$HOME`，`rsync -a configs/ $HOME/` 就是部署 |
| `machine/work/` | **本机覆盖层**。显示器、挂载路径等机器特定项（后应用，覆盖 configs/） |
| `machine/primary/` | 源机覆盖层。**只是资料**，别往本机装 |
| `docs/` | 架构、已知问题、Fedora 笔记、回退手册 |
| `inventory/` | 包清单快照、Arch→Fedora 映射、CLI 候选表 |
| `scripts/` | 导出（源机用）、部署、体检、分阶段验证 |
| `scripts/verify/` | 每个阶段的验收脚本，`doctor.sh` 会全部调用 |

**部署机制**：`configs/.config/hypr/hyprland.lua` 在最后 `require("machine")`，
由 `machine/work/.config/hypr/machine.lua` 决定这台机器加载哪些机器特定件。
换机器只换 `machine.lua` —— 这也是你在这个仓库里最可能要改的文件。

---

## 现在该干什么

`MIGRATION.md` 里当前阶段那一条的"步骤"就是你的 todo list。

每个阶段做完：
1. 跑 `scripts/doctor.sh`（全绿才算过）
2. 更新 `MIGRATION.md` 的**状态块**（阶段号 / 下一步 / 已完成清单）
3. 提交

**每次停止工作前必须更新状态块的"下一步"** —— 那是给"上次会话做到一半断了"用的。

---

## 卡住了怎么办

往 `MIGRATION.md` 的「阻塞」节写：现象 / 已试过什么 / 需要什么信息。
然后**停下来**。

**不要**为了让阶段"看起来完成"而降级验证标准。一个标成 ✅ 其实没验的阶段，
比一个诚实的 ⚠️ 危险得多——后面每个阶段都会踩在它上面。

不要用 `sudo` 做本方案里没写的操作。每个需要 sudo 的步骤都已在文档里列出。

---

## 本机事实

见 `machine/work/profile.toml`（Phase 1 摸底后填写）。

已知的部分：

- Fedora Workstation 44，x86_64，非 atomic 变体
- i9-13900KF + **RTX 3050 单卡，无核显输出**
- 已用半年 GNOME；**试装过 Hyprland 但放弃了** → Phase 1 必须先摸底残留
- 终端是 ghostty（不迁移终端本体，只把主题链接上去）

---

## 反模式清单

这些是交接场景下最容易犯的错，逐条对照：

| ❌ 不要 | 为什么危险 | ✅ 正确做法 |
|---|---|---|
| `dnf upgrade quickshell-git`（发现版本不符时） | 破坏版本闸门，ii 的补丁可能编译不过 | 停下来，写进 MIGRATION.md 的阻塞节 |
| `dnf downgrade hyprland` 到 0.51 让旧写法能用 | 配置是 Lua 0.55+ 格式，0.51 根本读不了 → 完全起不来 | 改写调用方，不改版本 |
| 看到 `QT_IM_MODULE` 被注释掉就"顺手"打开 | 绕过 text-input 协议，源机 unit 注释里解释了为什么 | 保持注释，只给 quickshell-ii.service 设 |
| 跑 dots-hyprland 的 `./setup install` | 会 rsync 覆盖 `~/.config/hypr`，冲掉本仓库铺的东西 | 只取它的 `sdata/dist-fedora/feddeps.toml` 包清单，不跑安装器 |
| 把 `docs/theming-framework.md` 当既成事实 | 那是**未实施的计划**，措辞像"我们已经这么做" | 看文件顶部警告；现状以 `LOCAL-PATCHES.md` 为准 |
| 发现文档缺失就"补一份" | 会生成与源机不符的描述，误导后续会话 | 记阻塞，问源机 |
| `rsync -a --delete` 铺 ii | 删掉运行期生成的文件和上游文件 | 不删；`apply-profile.sh` 已刻意不用 |
| 改 `colors.lua` 调配色 | 生成物，下次换壁纸就没了 | 改 `theme-switcher/themes/*.theme` 或 matugen 模板 |

---

## 验证手法

具体命令写在 `MIGRATION.md` 每个阶段的「验证」节（可直接粘贴执行 + 明确的期望输出）。

统一入口是体检脚本：

```bash
scripts/doctor.sh
```

输出是 PASS/FAIL 表格 + 每个失败项的排查建议。**不要凭感觉判断"应该好了"** ——
跑 doctor，看哪一栏红。
