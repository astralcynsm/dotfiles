# dotfiles

把一套深度定制的 Hyprland + quickshell(ii) 桌面从**主力机**迁移到**工作机**的作业包。

不是一堆配置文件的堆砌，是一份**能读懂、能续做**的迁移工程。

---

## 两台机器

| | 主力机 | 工作机 |
|---|---|---|
| 代号 | `primary` | `work` |
| 系统 | EndeavourOS（Arch） | **Fedora Workstation 44** |
| 形态 | HP OMEN 笔记本 | 台式机 |
| CPU / GPU | i5-13500HX / RTX 4060 Max-Q（混合显卡） | i9-13900KF / RTX 3050（**单卡无核显输出**） |
| 显示器 | HDMI-A-1 1920x1080@180 + eDP-1 2560x1440@240 | **待实测** |
| 桌面 | Hyprland 0.56.2（**Lua 配置**）+ quickshell(ii) | 目前是 GNOME（已用半年） |
| 终端 | foot | **ghostty**（不迁移终端本体，只接主题配色） |

**方向**：`primary` 是唯一真相 → 导出进本仓库 → `work` 部署。
反方向（work → primary）不存在，别搞混。

---

## 仓库怎么组织

核心是**两层覆盖模型**：

```
configs/     ← 通用层：与机器无关的一切。目录结构镜像 $HOME
machine/
  primary/   ← 主力机覆盖层：同样的镜像结构，部署时**后**应用，覆盖 configs/
  work/      ← 工作机覆盖层（待 Phase 1 摸底后填写）
```

部署 = 两条 rsync，后者覆盖前者：

```bash
rsync -a configs/                 "$HOME/"
rsync -a machine/<profile>/       "$HOME/"     # 覆盖
```

这样做的三个好处：

1. **路径零心智负担**：`configs/.config/hypr/hyprland.lua` 就是 `~/.config/hypr/hyprland.lua`，没有模板、没有变量替换
2. **"哪台机器不一样"一眼可见**：`diff -r configs/.config/hypr machine/primary/.config/hypr`
3. **加第三台机器 = 加一个目录**

**什么算机器特定**（必须进 `machine/<profile>/`）：

- 显示器配置（`monitors.lua`、`workspaces.lua`）—— 分辨率/输出名/工作区分配
- 笔记本特有（`UserConfigs/Laptops.lua`、`LaptopDisplay.lua`、`Monitor_Profiles/`）
- 挂载路径（`vault-commit/vaults.json` 里的 `/mnt/Storage/...`）
- 机器状态标记（`.initial_startup_done`）

**什么算通用**（留在 `configs/`）：键位、装饰、动画、窗口规则、主题链、输入法、systemd 单元、自写脚本。

机制上，`hyprland.lua` 在**最后** `require("machine")`，由 `machine.lua` 决定这台机器要加载哪些机器特定件。换机器只换 `machine.lua`。

---

## 其他目录

| 目录 | 是什么 |
|---|---|
| `docs/` | 架构说明、已知问题、Fedora 侧笔记、回退手册 |
| `inventory/` | 包清单快照 + Arch→Fedora 映射表 + **待你勾选的 CLI 候选表** |
| `scripts/` | 导出（主力机）、部署（工作机）、体检、分阶段验证 |
| `ii-patches/` | ii 相对上游改了什么（生成物，不参与安装） |

---

## 怎么用

### 在主力机上（导出）

```bash
scripts/export-from-arch.sh --dry-run   # 先看
scripts/export-from-arch.sh             # 正式导出
git add -A && git commit -m "..." && git push
```

导出脚本会自动：排除备份/运行期状态/二进制；**擦除真实密钥**；跑安全闸门。

### 在工作机上（部署）

```bash
git clone git@github.com:astralcynsm/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# ★ 先读这三份，按顺序
#   1. CLAUDE.md      —— 你是谁、硬约束、现在该干什么
#   2. MIGRATION.md   —— 分阶段计划与进度账本
#   3. docs/ARCHITECTURE.md —— 这套东西怎么运作（改东西前必读）

scripts/doctor.sh                       # 当前健康检查
scripts/apply-profile.sh work --dry-run # 看会动什么
scripts/apply-profile.sh work           # 部署（自动备份被覆盖的文件）
```

---

## 当前状态

> **本仓库由主力机侧构建，尚未在工作机上执行任何步骤。**

- ✅ Phase 0（主力机建仓与导出）—— 完成
- ⬜ Phase 1 及之后 —— 见 `MIGRATION.md` 顶部的状态块

**工作机的落地工作交给那边的 Claude Code**，`CLAUDE.md` 就是给它的作业指导书。

---

## 和其它仓库的关系

| 仓库 | 管什么 | 明确不管 |
|---|---|---|
| **dotfiles**（本仓库） | 桌面环境、主题链、输入法、常用 CLI 配置 | 笔记内容、Claude 记忆 |
| `cynsm-workflow` | 笔记工作流 + Claude 记忆 | dotfiles（它的 README 已声明） |

两者并列，互不覆盖。`vault-commit` 脚本本体放在本仓库（`configs/.local/bin/`），
`cynsm-workflow` 保留它自己的副本 —— 两处引用同一个脚本，改的时候记得同步。

旧的 `~/.dotfiles` 裸仓库（内容停在 2026-03-17，hyprlang 时代）已归档为
`~/.dotfiles.bare.bak`，不再维护。本仓库是它的续作。

---

## 三条最容易踩的

1. **`dnf upgrade` 不带参数会被禁**（会动 Hyprland/quickshell，见 `docs/known-issues.md`）
2. **部署时绝不用 `rsync --delete`**（会删掉 ii 运行期生成的文件）
3. **别跑 ii 上游安装器的 files 阶段**（会覆盖本地补丁）
