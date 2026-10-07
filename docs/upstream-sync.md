# 上游同步

这个仓库里有两个不同含义的「上游」，别混。

---

## 一、本 dotfiles 仓库（主力机 ⇄ 工作机）

**数据流默认单向**：

```
主力机活配置 ──[scripts/export-from-arch.sh]──▶ repo ──[git push]──▶ GitHub
                                                                     │
                                 工作机：git pull ──[scripts/apply-profile.sh]──▶ ~/
```

### 规则

1. **`configs/` 的唯一源头是主力机的活配置。**
   在工作机上直接改部署出来的文件（`~/.config/…` 里那些），改动**不属于**任何一边 ——
   下次 `git pull` + `apply-profile.sh` 会覆盖它（部署不带 `--delete`，但同名文件会被覆盖）。
   要改就改源机，再重跑导出脚本。
2. **例外：`machine/work/` 是工作机的领地。**
   显示器、`machine.lua`、`profile.toml` 就该在工作机上生成并**提交回仓库**（P1/P3 进行）。
   提交后主力机那边不用动它 —— 导出脚本不会碰 `machine/work/`。
3. **「回流」协议** —— 工作机若不得不改 `configs/` 里的文件
   （典型：P3.5 修 hyprctl 调用；P7 的 Arch→Fedora 命令替换）：
   - 改完 **commit + push**（改动先存进 GitHub，别只留在工作机磁盘上）
   - 随后**在主力机上** `git pull`，并把改过的文件**回灌进活配置**
     （直接从 repo `install/cp` 回 `~/.config/…`，或按同样改法手动改活配置）
   - 没做回灌之前，**不要在主力机上跑导出脚本** —— `--delete` 会用旧版本把 repo 里的修复盖回去
   - 这条做之前先跟用户确认（涉及主力机活配置）

   ⚠️ 更好的默认：**能在主力机做的修复就在主力机做**（对两边都有好处，还省掉回流）。
   P3.5 的 hyprctl 修复就属于这类 —— 源机上那些调用同样是坏的。

4. 部署永远不带 `--delete`（原因见 `docs/known-issues.md` R3）。导出才带。

---

## 二、ii 上游（end-4/dots-hyprland）

**只在一台机器上同步。当前定为：主力机**（补丁知识在那边，LOCAL-PATCHES.md 也在那边）。
工作机只收结果 —— 这是 `CLAUDE.md` 的硬约束 4。

为什么不能让工作机自己同步：本地对 ii 的改动散布在 bar、侧栏、设置页等各处
（总数见 `ii/LOCAL-PATCHES.md` 顶部总表），「顺手跑一下上游更新」= 几十处补丁被覆盖。

### 在主力机上同步的流程（给未来的自己）

1. 备份当前 ii 目录：`cp -a ~/.config/quickshell/ii ~/.config/quickshell/ii.bak-$(date +%F)`
2. 把上游最新版铺到**临时目录**（别直接铺进 `~/.config`）
3. 打开 `~/.config/quickshell/ii/LOCAL-PATCHES.md`，**逐节**把本地补丁重放到新树上
4. **桌面实测**：bar 五页、悬浮窗、主题切换、字数统计、听歌统计
5. 更新 `LOCAL-PATCHES.md`（顶部总表 + 对应节），必要时更新 `THEMING-FRAMEWORK.md`
6. 重跑 `scripts/export-from-arch.sh` → 扫描敏感信息 → commit → push
7. 工作机：`git pull` + `scripts/apply-profile.sh work`

### 禁区

- ❌ 跑 ii 安装器的 files 阶段 —— 会覆盖补丁
- ❌ `manage-translations.sh update` 加词条 —— 会删键（LOCAL-PATCHES §11 有记录）
- ❌ 在任何机器上 `rsync --delete` 进 `~/.config/quickshell/ii` —— 会删新增文件

---

## 三、冲突清单

以 `ii/LOCAL-PATCHES.md` 顶部总表为唯一权威（哪些文件是新增、哪些是改过、上游有没有同名的）。
本文档不复制那份清单 —— 两处维护必然分叉。
