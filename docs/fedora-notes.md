# Fedora Workstation 44 迁移 · 事实核实

> 本文件的每一条都标注了核实状态：**`✓ 已核实`** / **`⚠️ 部分核实`** / **`? 未核实`**。
> 诚实标注比看起来完整重要 —— 凡是没查到实据的，下面一律写「未核实」，不写成结论。
>
> 核实日期：2026-10-08。核实环境：主力机（Arch / EndeavourOS），**非** Fedora 机器。
> 涉及「工作机上才能验」的条目，用 ⚠️ 标注并写明**怎么验**。

---

## 0. 核实方法（可复现）

本次核实没有依赖博客或二手教程，主要手段是**直接读仓库元数据** —— 也就是工作机 `dnf` 真正会读的那份数据。因此下列结论的效力等同「在工作机上 `dnf repoquery`」。

| 手段 | 用途 |
|---|---|
| Fedora 44 GA 仓库 `primary.xml.zst`（`mirrors.kernel.org/fedora/releases/44/Everything/x86_64/os/repodata/`） | 官方包名 + 版本（76,353 个包） |
| Fedora 44 updates 仓库 `primary.xml.zst`（`.../updates/44/Everything/x86_64/repodata/`） | 同上（26,892 个包） |
| Fedora 44 GA 仓库 `filelists.xml.gz` | 包内**文件路径**（用来验硬编码路径） |
| RPM Fusion free/nonfree 的 44 仓库 `primary.xml` | NVIDIA 与第三方包 |
| COPR 的 `download.copr.fedorainfracloud.org/.../<chroot>/repodata/` | COPR 的**真实包表**（绕开被 Anubis 反爬挡住的 COPR 网页） |
| `api.github.com/repos/end-4/ii-package-builds/releases/tags/packages-fedora` | ii 官方 Fedora 构建产物 |
| `rpmfusion.org/Howto/NVIDIA?action=raw` | NVIDIA 安装指导原文 |

**COPR 实测可用性一览**（`repomd.xml` HTTP 码，2026-10-08）：

| COPR | fedora-44-x86_64 |
|---|---|
| `sdegler/hyprland` | ✓ 200 |
| `ririko66z/dots-hyprland` | ✓ 200 |
| `scottames/ghostty` | ✓ 200 |
| `deltacopy/darkly` / `alternateved/eza` / `atim/starship` | ✓ 200（经 packages.redhat.com 302 后 200） |
| `tofik/nwg-shell` | ✓ 200 |
| `leloubil/wl-clip-persist` | ✓ 200 |
| **`solopasha/hyprland`** | **✗ 404**（连 fedora-42/43 也 404 —— 项目已不可用，**不要用**） |

---

## 1. Hyprland 本体在 Fedora 44 从哪来

### 结论

**★ 官方仓库里没有 Hyprland，也没有任何 hypr\* 组件。COPR 不是「可选优化」，是唯一途径。**

这是本次核实最硬的一条发现。`packages.fedoraproject.org/pkgs/hyprland/hyprland/fedora-44.html` 会返回 **HTTP 200**，页面上却只列到 `0.45.2-1.fc42` —— 页面存在但包**已被退役**（retired）。用 HTTP 200 判断「包存在」在这里会得到错的答案；必须以仓库元数据为准。

Fedora 44 GA + updates 仓库里**一个都没有**的 hypr\* 包：

```
hyprland  hyprland-guiutils  hyprland-qt-support  hyprsunset
hyprlock  hypridle  hyprpicker  hyprshot  hyprpolkitagent
xdg-desktop-portal-hyprland
```

→ **`sdegler/hyprland` 是正解**，理由不止「能用」：

1. **版本与主力机逐一对齐**（见附录 B），连 `hyprland-0.56.2` 都一模一样 —— 这是「键位一个不能丢」最有力的保障。
2. **ii 上游自己就用它**。`dots-hyprland/sdata/dist-fedora/feddeps.toml` 第 2 行原文：
   > `# "solopasha/hyprland" is not up to date to the current Hyprland version, replaced with the fork "sdegler/hyprland"`

   并在 `[copr] repos` 里启用 `sdegler/hyprland`。
3. COPR 的 `hyprland` 包提供 **`/usr/share/wayland-sessions/hyprland.desktop`**（还有 `hyprland-uwsm.desktop`）→ 直接满足「保留 GDM 双会话」。
4. COPR 的 `hyprland.desktop` 的 `Exec` 是 `/usr/bin/start-hyprland`（二进制已确认存在于包内），与主力机 Arch 上完全一致 → **不引入新的启动路径差异**。

**状态：`✓ 已核实`**（依据：Fedora 44 GA/updates/filelists 元数据 + `sdegler/hyprland` 的 repodata + ii 的 `feddeps.toml` 原文）

### 对迁移的影响

- 「保留 GDM 双会话」不需要动 GDM：装完 COPR 后 GDM 会多出 `Hyprland` 会话项。
- ⚠️ **GDM 里有两个 Hyprland 项**，要选 **`Hyprland`**，**不要选** `Hyprland (uwsm-managed)`。主力机不用 uwsm（`~/.config/hypr` 全树无 uwsm 引用），选错会改变整个进程树与 `systemd --user` 的归属，`hyprland-session.target` 那套保活逻辑会错位。
- 必须在 `dnf upgrade` 前想清楚更新策略：COPR 包和 Fedora 官方 Qt/wayland 的 ABI 漂移是 Hyprland COPR 的经典翻车点（`sdegler/hyprland` 的 Fedora Discussion 主题里就有 F42 Qt 6.9→6.10 后 `hypridle`/`hyprpolkitagent`/`hyprsysteminfo` 集体坏掉的记录）。

### 备选（未采用，仅记录）

- `AshBuk/Hyprland-Fedora`：把依赖 vendor 进 `/usr/libexec/hyprland/vendor/` 并用 RPATH 隔离，宣称「Zero ABI conflicts」。**但此次未核实它是否有 fedora-44 chroot**（COPR 网页被 Anubis 挡，也没在本地找到可探的下载路径）。若将来 `sdegler` 出问题，这是第一顺位备选。**`? 未核实`**

---

## 2. ii / quickshell 在 Fedora 44 怎么装

### 结论

**★ 好消息：ii 的官方 Fedora 构建产物就是为 fc44 做的，而且 `quickshell-git` 的 commit 与主力机 pin 的完全一致。**

`api.github.com/repos/end-4/ii-package-builds/releases/tags/packages-fedora`（tag 发布日 2026-05-09）的全部 4 个 asset：

```
matugen-4.1.0-0.fc44.x86_64.rpm
quickshell-git-0.2.1.770.git7511545-0.fc44.x86_64.rpm
quickshell-git-0.2.1.770.git7511545-1.fc44.x86_64.rpm
quickshell-git-0.2.1.770.git7511545-2.fc44.x86_64.rpm
```

`7511545` 就是主力机 AUR `illogical-impulse-quickshell-git` 那个 pin 版本（`0.2.1.770.git7511545`）—— 版本串一字不差。**所以「quickshell 版本对齐」这件事本身不需要做任何工作。**

**状态：资产存在性与版本号 `✓ 已核实`**

### ⚠️ Qt 版本风险（必须知道的一条）

Fedora 44 官方 Qt 是 **`qt6-qtbase-6.10.2`**（`✓ 已核实`，来自 GA 仓库元数据）。

历史上出过事：issue **end-4/dots-hyprland#2407**（Fedora 43）报告 `quickshell-git` 的 RPM 要求 Qt 6.9，而 F43 已升到 Qt 6.10，`dnf` 解不出依赖，装不上。该 issue **已关闭，且关闭时无任何评论、没有贴出解决方案**（`✓ 已核实`，读的是 issue 页面本身）。当时那个构建的 shortcommit 是 `db1777c`，**不是**现在的 `7511545`。

上述 asset 里 `-0` / `-1` / `-2` 三个 release 号，形态上像是针对这类依赖问题的重打包。**但「fc44 后缀存在」≠「在 Qt 6.10.2 上装得上」** —— 我无法在不碰工作机的前提下验证 RPM 的 `Requires` 能否解析。

**状态：`⚠️ 部分核实` —— 存在性已验，可安装性未验。**

**在工作机上的第一件事就是验它**（装之前，先只装元数据）：

```bash
sudo dnf install --assumeno \
  ./quickshell-git-0.2.1.770.git7511545-2.fc44.x86_64.rpm
# 看它报的依赖是否解得开；--assumeno 不会真的改动系统
# 备选：rpm -qpR ./quickshell-git-*.rpm | grep -i qt6   # 看它到底要哪个版本
```

### 两条安装路径（选一条，别混用）

ii 官方 `sdata/dist-fedora/install-deps.sh` 的机制（`✓ 已核实`，读的就是这个脚本）：

1. 把 `$HOME/.cache/illogical-impulse-repo` 清空重建
2. 从上面的 GitHub API 拉 asset，`curl --max-time 10 -L --fail --show-error --progress-bar`
3. **每下一个就 `createrepo_c` 一次**
4. `--repofrompath=illogical-impulse,file://$HOME/.cache/illogical-impulse-repo --nogpgcheck`
5. 开头 `sudo dnf versionlock delete quickshell-git 2>/dev/null`，结尾 `[ -n $nolock_qs ] || sudo dnf versionlock add quickshell-git || true`
6. 除非 `SKIP_SYSUPDATE=true`，否则 `sudo dnf upgrade --refresh -y`
7. 用 `yq` 把 transaction ID 记进 `.dnf.transaction_ids`，方便 `dnf history undo`

**★ 第 5 步在 Fedora 44 上会静默失效** —— 见第 10 节，`dnf5` 没有 versionlock 插件，命令不存在；而脚本把它挂在 `|| true` 后面，所以**不会有任何报错，也不会有任何保护**。装完 `quickshell-git` 在下一次 `dnf upgrade` 时会被一起升级，可能直接破坏 ii。第 10 节给了替代做法。

**★ 另一条：`[groups.illogical-impulse]` 会装 `matugen` 4.1.0，这个版本必须拦住** —— 见第 3 节 matugen 条目。

**替代路径**：`ririko66z/dots-hyprland` COPR 也有 `quickshell-git`，但它是该 COPR 自己的重打包，版本是 `0.2.1^713.git26531fc` —— **commit 不是 `7511545`**。如果你更愿意用 COPR 而不是本地 file:// 仓库，就要接受版本漂移。**不建议**：主力机的 ii 是在 `7511545` 上验证过的。

**状态：安装机制 `✓ 已核实`；「哪条路更适合工作机」属决策，不在此文件范围。**

---

## 3. Fedora 44 包可用性矩阵

以下全部来自 **GA + updates 仓库元数据**（`✓ 已核实`）。`官方版本` 一栏是 2026-10-08 的快照。

### 3.1 官方仓库有（直接 `dnf install`）

| 包 | 官方版本 | 备注 |
|---|---|---|
| `hyprland` 系列 | **无** | 见第 1 节，全退役 |
| `matugen` | **3.1.0** | 源包 `rust-matugen`；★ 与主力机 `matugen-bin 3.1.0` **完全同版本** |
| `darkman` | 2.2.0 | 主力机 2.3.1，小版本差 |
| `quickshell` | 0.2.1^git20260209.**dacfa9d** | 官方快照，**commit 不是** `7511545` |
| `qt6-qtbase` / `qt6-qtdeclarative` | **6.10.2** | |
| `grim` / `slurp` / `wf-recorder` / `swappy` | 1.5.0 / 1.5.0 / 0.6.0 / 1.5.1 | |
| `cliphist` / `wl-clipboard` | 0.7.0 / 2.2.1^git20251124 | |
| `fcitx5` / `fcitx5-rime` / `fcitx5-chinese-addons` | 5.1.19 / 5.1.13 / 5.1.12 | |
| `librime` / `brise` | 1.16.1 / 0.38.20180515 | `brise` 是 Fedora 的 rime 数据包 |
| `tesseract` + `tesseract-langpack-eng` + `-chi_sim` | 5.5.3 / 4.1.0 / 4.1.0 | ★ OCR 所需中文包名已确认存在 |
| `translate-shell` | 0.9.7.1 | |
| `adw-gtk3-theme` | 6.4 | ii 的 `feddeps.toml` 里叫 `adw-gtk3-theme`，对得上 |
| `kvantum` / `qt6ct` | 1.1.6 / 0.11 | |
| `material-icons-fonts` / `twitter-twemoji-fonts` | 4.0.0 / 14.0.2 | |
| `eza` | 0.23.4 | 不需要 `alternateved/eza` COPR |
| `ripgrep` `clang`(22.1.1) `rust`/`cargo`(1.94.1) `jq` `yq` `rsync` `cmake` `wget2` `bc` `xdg-utils` `unzip` | | |
| `jemalloc` `kdialog` `upower` `wtype` `ydotool` `playerctl` `cava` `pavucontrol` `wireplumber` `brightnessctl` `ddcutil` `geoclue2` `fuzzel` `wlogout` `qalculate-qt` | | |
| `xdg-desktop-portal` + `-gtk` + `-kde` | 1.21.1 / 1.15.3 / 6.6.4 | `-hyprland` 从 COPR 来 |
| `dolphin` `plasma-systemsettings` `plasma-nm` `plasma-systemmonitor` | 25.12.3 / 6.6.4 | |
| `gnome-keyring` | 50.0 | |
| `network-manager-applet` `blueman` | 1.36.0 / 2.4.6 | `nm-applet` / `blueman-applet` 的包 |
| `polkit-kde` | 6.6.4 | ★ 路径有坑，见附录 A |
| `pam-kwallet` | 6.6.4 | ★ 路径有坑，见附录 A |
| `kitty` `foot` | 0.43.1 / 1.26.1 | 备用终端 |
| `dnf5` `dnf5-plugins` | 5.4.6.0 | |

### 3.2 官方没有 → 某个 COPR 有

| 包 | 来源 | 版本 | COPR chroot |
|---|---|---|---|
| `hyprland` | `sdegler/hyprland` | **0.56.2** | fc44 ✓ |
| `hyprlock` / `hypridle` / `hyprpicker` / `hyprsunset` | 同上 | 0.9.6 / 0.1.8 / 0.4.7 / 0.4.0 | fc44 ✓ |
| `hyprland-guiutils` / `hyprland-qt-support` | 同上 | 0.2.2 / 0.1.0 | fc44 ✓ |
| `xdg-desktop-portal-hyprland` | 同上 | 1.4.1 | fc44 ✓ |
| `hyprpolkitagent` | 同上 | 0.2.0 | fc44 ✓ ★ 顺手解决附录 A 的 polkit 路径问题 |
| `hyprshot` | 同上 | 1.3.0 | fc44 ✓ |
| `satty` | 同上 | 0.20.0 | 主力机 0.22.0 |
| `mpvpaper` | 同上 | 1.8 | 主力机当前未启用视频壁纸 |
| `qdirstat`…（其余见 `sdegler` 包表） | 同上 | | |
| `nwg-displays` | **`tofik/nwg-shell`** | 0.4.3 | fc44 ✓（主力机 0.4.4） |
| `nwg-look` `nwg-clipman` | 同上 | 1.1.1 / 0.2.8 | fc44 ✓ |
| `wl-clip-persist` | **`leloubil/wl-clip-persist`** | **0.4.1** | fc44 ✓（主力机 0.5.0） |
| `ghostty` | **`scottames/ghostty`** | 见第 8 节 | fc44 ✓ |
| `jetbrains-mono-nerd-fonts` | `ririko66z/dots-hyprland` | 3.4.0 | fc44 ✓ |
| `bibata-cursor-theme` | 同上 | 2.0.7 | fc44 ✓ |
| `microtex` | 同上 | 1.0^1.git0e3707f | fc44 ✓ |
| `songrec` | 同上 | 0.4.3^1.gitf819e15 | fc44 ✓ |
| `starship` | `atim/starship` | ✓ | fc44 ✓ |
| `darkly`（Kvantum/风格） | `deltacopy/darkly` | ✓ | fc44 ✓ |

**注**：`nwg-displays` 在 `tofik/nwg-shell` 里 —— 这个名字要留意，**不是**上游作者自己的账号（`nwg-piotr/nwg-shell` 是 404）。这是本次核实里唯一一个「官方没有、ii 也没配、得自己找 COPR」的包。

### 3.3 四处都没有

| 包 | 状态 | 影响 / 对策 |
|---|---|---|
| `nwg-displays` | 官方 ✗ / RPM Fusion ✗ / ii 的 COPR ✗ → 但 `tofik/nwg-shell` **有** | 见 3.2，不是问题 |
| `polkit-gnome` | 官方 ✗ | ii 不用它；`hyprpolkitagent` 顶上 |
| `mpvpaper` `satty` | 官方 ✗ / RPM Fusion ✗ → `sdegler` 有 | 见 3.2 |
| `pano-scrobbler` | 官方 ✗ / RPM Fusion ✗ | 第三方音乐 scrobble 客户端（`Startup_Apps.lua:96`）。**`? 未核实`** 其 Fedora 安装途径（Flatpak / AppImage / COPR 都有可能，需工作机上现查） |

### 3.4 ★ matugen 版本必须钉住 3.1.0

三个来源给的是**三个不同版本**：

| 来源 | 版本 | 判断 |
|---|---|---|
| Fedora 44 官方 | **3.1.0** | ★ **用这个** —— 与主力机 `matugen-bin-3.1.0-1` 完全一致 |
| `sdegler/hyprland` COPR | 3.0.0 | 低于主力机 |
| ii 的 `packages-fedora` release | **4.1.0** | ★ **必须拦住** |

理由（`✓ 已核实`，来自 matugen v4 的 release notes 与下游 issue）：

- 4.0 改了**默认 JSON 输出**，要新的 `--old-json-output` 才拿回 3.x 格式；
- 4.0 新增**交互式取色器**：不给 `--source-color-index` 时 CLI 会**停下来等你选色**。下游工具（HyprPanel）因此在脚本里拿到空的 matugen 输出 —— 因为脚本没法回答交互提示。
- 新增 `base16.*` 模板关键字与 `format` / `set_alpha` 过滤器，模板语法有变。

主力机的 `~/.config/matugen/config.toml` 是 3.x 形态（`[config] version_check = false` + `[templates.<名>]` 的 `input_path`/`output_path`），由 ii 的 `switchwall.sh` 在**换壁纸时后台调用** —— 正是「无人值守脚本」场景。换到 4.1.0 大概率表现为**换壁纸后配色不更新**，而且不报错（脚本拿不到输出）。

**对策**：`dnf install matugen`（官方 3.1.0），并且**不要**执行 ii 安装脚本的 `illogical-impulse` 组，或执行后立刻 `dnf downgrade` / 用 `excludepkgs` 挡掉。

**状态：版本事实 `✓ 已核实`；「4.1.0 会不会真的坏」`⚠️ 部分核实`** —— 依据是 v4 release notes + 下游用户的同类报告，没有在主力机上实测（主力机就是 3.1.0，装了 4.1.0 才能测）。

---

## 4. NVIDIA 驱动（RTX 3050 / 独显直出）

### 结论

**★ RPM Fusion nonfree 的 44 仓库里 NVIDIA 齐全。当前可用主版本：`615.71.09`（另有 `595.58.03` 分支）。**

实测包名与版本（`✓ 已核实`，来自 RPM Fusion nonfree 44 仓库元数据，93 个 nvidia 相关包）：

```
akmod-nvidia-615.71.09          akmod-nvidia-595.58.03      akmod-nvidia-open-595.58.03
kmod-nvidia-615.71.09           kmod-nvidia-595.58.03       kmod-nvidia-open-595.58.03
xorg-x11-drv-nvidia-615.71.09   nvidia-settings-615.71.09   nvidia-persistenced-615.71.09
xorg-x11-drv-nvidia-cuda-libs-615.71.09   ...-devel / -kmodsrc / -libs / -power / -xorg-libs
# 另有 legacy 分支：390xx(390.157) / 470xx(470.256.02) / 580xx(580.178.04)
```

RTX 3050 是 Ampere，主线 `akmod-nvidia` 与 `akmod-nvidia-open` 都支持。

**状态：包存在性与版本 `✓ 已核实`**

### ★ 内核参数：不要手动加 `nvidia-drm.modeset=1`

`rpmfusion.org/Howto/NVIDIA?action=raw` 原文（`✓ 已核实`，直接读的页面源码）：

> 该参数「was previously set and should be cleared from current installations」，它会「produces a bad interaction with a Fedora Kernel specific patch」（与 Fedora 内核针对 early boot display / simpledrm 的补丁冲突）。结论：**「don't use nvidia-drm.modeset=1 parameter from cmdline」**。

同一页说明：KMS「**not enabled by default in the main NVIDIA driver**」，而是**由 RPM Fusion 的 kernel 包替用户打开**（所以更不需要你写在 cmdline 上）。

清除 / 恢复的命令（页面原文）：

```bash
sudo grubby --update-kernel=ALL --args='nvidia-drm.modeset=0'          # 清除先前误加的
sudo grubby --update-kernel=ALL --remove-args='nvidia-drm.modeset=0'   # 恢复
```

**⚠️ 注意：这条与先前方案里的假设相反。** 之前的草稿打算「加 `nvidia-drm.modeset=1`」，按 RPM Fusion 原文这是**错的**，会造成早期启动显示异常甚至进不去。工作机上执行前请再对着 RPM Fusion 页面确认一遍（页面会随驱动版本更新）。

**★ 未使用 `fbdev`**：这一版 Howto 页面**通篇没有出现 `fbdev` 一词**。它的「Graphic console」一节讲的是 legacy BIOS 下的 `vesafb`（`video=vesafb:mtrr:3`）；LUKS/Plymouth 提示符场景建议 `plymouth.use-simpledrm=1`。所以「NVIDIA 570+ 默认开 fbdev 所以不用加 `nvidia_drm.fbdev=1`」这句话**本页没有依据**，不要写进正式步骤。

**状态：`✓ 已核实`（本页原文）**

### initramfs

页面原文：把 nvidia 打进 initramfs **「we do not recommended it」**。若确实需要自动重建，给的做法是：

```bash
sudo systemctl edit akmods@.service
# ExecStartPost=/usr/bin/dracut --force --add-drivers "nvidia nvidia-drm nvidia-modeset nvidia-uvm" /boot/initramfs-%i.img %i
sudo systemctl daemon-reload
```

**注**：先前摘要里写的「RPM Fusion 通过 `omit_drivers+=" nvidia ... "` 把 nvidia 排除出 initramfs」—— 本页**没有**这句，属于未经核实的细节，**不要照抄**。

### 驱动更新后的动作

页面原文：装完要「wait until the kmod has been built. This can take up to **5 minutes** on some systems」，然后用 `modinfo -F version nvidia` 验证 —— 正常应打印版本号，而不是 `modinfo: ERROR: Module nvidia not found`。Akmods 会自己检查缺失的 kmod 并重建。

### Secure Boot

页面原文只说：「If you have secure boot enabled in BIOS/EFI, **you must sign the nvidia kmod**」，否则「disable secure boot, or follow the **Secure Boot HowTo**」；并强调**必须在装 kmod 之前**搞定签名，否则「Failure to do so will disable the driver and result in a blank screen」。

**`kmodgenca -a` + `mokutil --import` 这两条具体命令属于另一个页面（Secure Boot HowTo）的内容，本次未核实其原文。** **`? 未核实`** —— 工作机若 Secure Boot 开着，先读 RPM Fusion 的 Secure Boot Howto 再动手，别按记忆敲。

### 对迁移的影响

- 这块是**唯一可能让机器进不去图形界面**的部分，建议排在工作机开工顺序的**最前面**、且一次只改一样。
- 如果工作机当前 GNOME 跑得好好的、用的是 nouveau 或已在用 nvidia 专有驱动，要先确认现状再动（`lsmod | grep -E 'nvidia|nouveau'`、`dnf list installed '*nvidia*'`）。

---

## 5. XDG_MENU_PREFIX

### 结论

**★ 对本次迁移，这个变量基本无关 —— 因为 ii 根本不读它。**

实测：在 `~/.config/quickshell/ii` 全树 grep `XDG_MENU_PREFIX`，**零命中**；`XDG_CURRENT_DESKTOP` 只有 1 处引用。所以「Fedora 的 `XDG_MENU_PREFIX` 是什么值」不会影响 ii 的启动器行为。

**状态：`✓ 已核实`（本机全树 grep 的否定证据）**

### 值本身

按 freedesktop Desktop Menu Spec，`$XDG_CONFIG_DIRS/menus/${XDG_MENU_PREFIX}applications.menu` 决定主菜单布局；GNOME 会话设 `XDG_MENU_PREFIX=gnome-`（**含尾随连字符**），使解析到 `gnome-applications.menu`（Fedora 上由 `gnome-menus` 包提供）。

**但这只在「读 `.menu` 文件做菜单分类」的程序里起作用** —— `fuzzel` 的分类、`alacarte` 之类。**`? 未核实`**：我没有在 Fedora 44 上实读这个值（本机是 Arch，值不可类推）。

**怎么在工作机上验（10 秒）**：

```bash
# 在 Hyprland 会话里（不是 GDM 登录前的 tty 里）
env | grep XDG_MENU_PREFIX
ls /etc/xdg/menus/ | grep -i gnome
```

### 对迁移的影响

- **可以不做任何事。** 若日后发现 ii 启动器里某类应用不显示，再回来查这个变量。
- 想稳妥的话，在工作机的 `~/.config/hypr/UserConfigs/ENVariables.lua` 里显式补一条 `hl.env("XDG_MENU_PREFIX", "gnome-")` 也无害 —— 但**没有依据说这是必需的**，属于「加了不出错」而非「必须加」。

---

## 6. fcitx5 环境变量注入

### 结论

主力机现在的三层结构（`✓ 已核实`，读的都是本机活文件）：

| 位置 | 内容 | 备注 |
|---|---|---|
| `/etc/environment` | `XMODIFIERS=@im=fcitx`、`SDL_IM_MODULE=fcitx` **生效**；`GTK_IM_MODULE`/`QT_IM_MODULE` **故意注释掉** | 本机既有约定，见 MEMORY |
| `~/.config/hypr/UserConfigs/ENVariables.lua` | `hl.env("GTK_IM_MODULE","fcitx")` / `QT_IM_MODULE` / `XMODIFIERS` / `SDL_IM_MODULE` 四条齐全 | **Hyprland 会话内**生效 |
| `~/.config/systemd/user/quickshell-ii.service` | `Environment=QT_IM_MODULE=fcitx` | quickshell 是 Qt 但不走 `text-input`，必须单独给 |

**这套结构在 Fedora 上可以整体照搬**，因为 `ENVariables.lua` 和 unit 文件都进了仓库的 `configs/`。

### ★ Fedora 特有的坑：`imsettings`

Fedora 有个别家没有的包 **`imsettings`**，它会**主动设置输入法相关环境变量并启动输入法框架**。有 Fedora 44 KDE 用户报告：把 `XMODIFIERS` 放进 `~/.config/environment.d/` 后，**XWayland 应用（Steam）仍拿不到**，最后是**移除 `imsettings`** 才好；症状是 `xprop -root XIM_SERVERS` 里只有 `@server=ibus, @server=none`，没有 fcitx5。`imsettings` 会**静默把 `XMODIFIERS` 改写成 `@im=none`**。

**状态：`⚠️ 部分核实`** —— 依据是 Fedora Discussion 上一个用户的实战记录（单一样本，且那人是 KDE 会话），**没有**在 Fedora 44 + Hyprland + GDM 组合上验证过。

**怎么在工作机上验**：

```bash
env | grep -E 'IM_MODULE|XMODIFIERS'      # 看值是否被改写
ps aux | grep -E 'fcitx5|ibus-daemon'      # 看 ibus 是否在抢
rpm -q imsettings                          # 是否装了
xprop -root XIM_SERVERS                    # 期望看到 fcitx5，而不是只有 @server=ibus
```

### ibus 的冲突

Fedora 把 ibus 作为默认框架，且与 GNOME 深度绑定。**两边同时装时环境变量会互相打架**（只能有一个框架占住输入流）。注意：

- ibus 是 gnome-shell 的依赖，**不要卸载** `ibus`/`ibus-data` —— 会连带拆掉 GNOME，而你要保留 GDM 双会话。
- 真正要做的是**在 Hyprland 会话里不让 ibus-daemon 起来**（Hyprland 会话本身不会自动起 ibus；风险点在于某些 XDG autostart 项）。检查 `~/.config/autostart/` 与 `/etc/xdg/autostart/` 里有没有 ibus 相关项。
- 主力机 `Startup_Apps.lua:92` 有 `fcitx5 -d --replace` —— `--replace` 参数本身就意味着「顶掉已有的输入法进程」，在 GNOME 会话里会顶掉 ibus，在 Hyprland 会话里是对的。

### GDM Wayland 会不会读 `~/.profile`

**`? 未核实`。** 这一条我查到的说法互相矛盾（fcitx 官方 wiki 说 `~/.bash_profile` 对 GDM/SDDM/LightDM 有效；但那是 X11 会话时代的 Xsession 机制，Wayland 会话下会话环境主要由 systemd user manager 的 `environment.d` 与 PAM 提供）。

**结论上不影响本项目**：因为本项目的做法是**用 `ENVariables.lua` 在 Hyprland 会话内设**，再用 `quickshell-ii.service` 给 systemd 服务单独设 —— 两条路径都绕开了「图形会话是否 source `~/.profile`」这个问题。**不要**为了省事把 `QT_IM_MODULE` 全局塞进 `/etc/environment`：那正是主力机刻意注释掉的坑，而且会污染 GNOME 会话。

---

## 7. SELinux

### 结论

**Fedora 44 Workstation 默认 SELinux `enforcing` + `targeted` 策略。** 官方文档原文：「In Fedora, enforcing mode is enabled by default when the system was initially installed with SELinux.」`/etc/selinux/config` 里是 `SELINUX=enforcing` / `SELINUXTYPE=targeted`。新装机器上 `getenforce` 返回 `Enforcing`。

**状态：`✓ 已核实`（Fedora 官方文档 + 多个一致来源）**

### 对本次迁移意味着什么

**`⚠️ 部分核实`** —— 以下是从 `targeted` 策略的语义推出的判断，**没有**在 F44 上实测：

1. `targeted` 策略主要约束**系统服务**，用户会话进程一般是 `unconfined_u`，**日常桌面使用基本感知不到**。所以「Fedora 上跑 Hyprland 会被 SELinux 挡住」这个担心**没有依据**。
2. 真正可能被挡的候选：
   - `ydotool` / `wtype` 走 `/dev/uinput` —— 这**主要是 unix 权限**（`uinput` 组）问题，不一定触发 SELinux；但 `ydotool` 用 systemd 服务跑时会被当服务管，**可能**出 AVC。
   - 自写的 systemd user unit（`ii-stats.service`、`rime_counter.service`、`db-sync.service`、`rescrobbled.service` 等）读 `$HOME` 下的自定义路径 —— user unit 通常在 `unconfined` 域。
   - `qs`（quickshell）如果是从 COPR 装的，运行在用户域。
3. **不要**为省事把 SELinux 全局设成 permissive。真出问题时的正确姿势：

```bash
sudo ausearch -m avc -ts recent           # 看最近的拒绝记录
sudo setenforce 0                          # 临时 permissive（重启失效），只用于定位
sudo setenforce 1                          # 立刻改回来
sudo ausearch -m avc -ts recent | audit2allow -M mypol && sudo semodule -i mypol.pp   # 兜底
```

### 怎么在开工前确认现状

```bash
getenforce
sestatus | head -5
```

**状态：默认值 `✓ 已核实`；对 Hyprland 栈的具体影响 `? 未核实`** —— 建议的做法是：**先什么都不做**，等真出现 AVC 再逐个处理，而不是预防性地关掉。

---

## 8. ghostty 终端

### 结论

**★ Fedora 44 官方仓库和 RPM Fusion 里都没有 ghostty。必须走 COPR。**

- 官方 GA + updates 仓库：`ghostty` ✗（零命中）
- RPM Fusion free + nonfree：`ghostty` ✗
- **`scottames/ghostty` COPR：fedora-44-x86_64 ✓ 200**，包内容包括 `ghostty`、`ghostty-devel`、`gtk4-layer-shell`、`gtk4-layer-shell-devel`、`zig015`（构建用的 Zig 工具链，也被打出来了）

**状态：`✓ 已核实`（三处仓库元数据 + COPR repodata）**

其他途径（**`⚠️ 部分核实`** —— 来自搜索汇总，未逐个实探）：

| 途径 | 状态 |
|---|---|
| `scottames/ghostty` COPR | ✓ 已核实（首选） |
| Terra 仓库（`dnf install --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever'`） | ⚠️ 有记录但未实探 |
| Snap（`sudo snap install ghostty --classic`） | ⚠️ |
| Flathub | ⚠️ 有资料说**尚未上架**，打包工作仍在进行 |
| 源码 / AppImage | ⚠️ 兜底 |

**注意**：`pgdev/ghostty` 这个 COPR 在 Fedora Discussion 上有 fedora-44 返回 404 的报告（挡了 Silverblue 用户的升级），**别用**。

### 对迁移的影响

用户已经说明了：**terminal 本体不迁移（工作机上已装 ghostty），但要在这边做主题适配。** 所以这条的作用是：

1. **确认工作机上那份 ghostty 是从哪来的** —— 如果是从 COPR 装的，版本可能与主力机不同，`~/.config/ghostty/config` 里的键名兼容性要对着版本核。⚠️ **做完主题适配后，务必在工作机上用同版本 ghostty 验证一遍**，别只在本机（Arch 版）验完就发。
2. Reload 机制（本机已验证过）：`ghostty +reload-config` **不存在**，要发 D-Bus：

```bash
gdbus call --session --dest com.mitchellh.ghostty \
  --object-path /com/mitchellh/ghostty \
  --method org.gtk.Actions.Activate reload-config [] {}
```

---

## 9. `dnf check-update` 退出码

### 结论

**三条退出码，与「脚本里的 0 = 成功」直觉相反：**

| 退出码 | 含义 |
|---|---|
| **100** | **有可用更新**（同时会打印可更新的包列表） |
| **0** | 没有可用更新 |
| **1** | 出错（网络/仓库不可用等） |

dnf man page 原文：「DNF exit code will be **100** when there are updates available and a list of the updates will be printed, **0** if not and **1** if an error occurs.」这个行为与 yum 一致，已存在 10 年以上，「All tooling in the wild expects this」。

**状态：`✓ 已核实`（dnf man page 原文 + 多方一致）**

### 对迁移的影响

**这是本次核实里最容易写出静默 bug 的一条。** 在 `set -e` 的脚本里写：

```bash
dnf check-update          # ✗ 有更新时返回 100 → set -e 直接终止脚本
```

正确写法：

```bash
if dnf check-update >/dev/null 2>&1; then
    echo "无更新"
else
    case $? in
        100) echo "有更新" ;;
        *)   echo "检查出错" >&2; exit 1 ;;
    esac
fi
```

**注意**：`dnf check-update` 返回 100 时**不能**当失败处理。另外，`check-update` 报有更新**不保证** `dnf upgrade` 真的会装上（升级要满足依赖约束）。

---

## 10. `dnf versionlock` 与 dnf5

### ★★ 结论：Fedora 44 上 `dnf versionlock` 命令不存在

这是本次核实最有价值的发现之一，直接让 ii 的安装脚本少一层保护。

**证据链（全部 `✓ 已核实`，来自 Fedora 44 GA 仓库元数据 + filelists）：**

1. Fedora 41 起 **`dnf` 默认指向 dnf5**（`/usr/bin/dnf` → `dnf5`；旧版仍在，为 `/usr/bin/dnf4` / `/usr/bin/dnf-3`）。F41 change proposal「Switch to DNF5 (system-wide)」于 2024-04-09 由 FESCo 以 5 票赞成 2 票反对通过。
2. Fedora 44 的 dnf5 版本是 **`dnf5-5.4.6.0`**。
3. `dnf5-plugins-5.4.6.0` 提供的 `/usr/lib64/dnf5/plugins/` 下**全部** `.so`：

```
automatic_cmd_plugin.so      builddep_cmd_plugin.so       changelog_cmd_plugin.so
config-manager_cmd_plugin.so copr_cmd_plugin.so           diff.so
manifest_cmd_plugin.so       needs_restarting_cmd_plugin.so
repoclosure_cmd_plugin.so    repomanage_cmd_plugin.so     reposync_cmd_plugin.so
```

→ **没有 `versionlock`。** （`copr_cmd_plugin.so` **在**，所以 `dnf copr enable` 可用 —— 但需要先 `dnf install dnf5-plugins` 才会被装上。）

4. Fedora 44 里**唯一**名字含 versionlock 的包是 **`python3-dnf-plugin-versionlock-4.10.1`** —— 版本号 4.x，这是 **dnf4 的 Python 插件**（`/usr/lib/python3.14/site-packages/dnf-plugins/versionlock.py` + `/etc/dnf/plugins/versionlock.conf`）。dnf5 **不加载** dnf4 的 Python 插件。

**所以**：在 Fedora 44 上敲 `sudo dnf versionlock add quickshell-git` 会得到「没有这个命令」类的错误。

### 对 ii 安装脚本的实际影响

`install-deps.sh` 里两处：

```bash
sudo dnf versionlock delete quickshell-git 2>/dev/null   # ② 错误被 2>/dev/null 吞掉
[ -n $nolock_qs ] || sudo dnf versionlock add quickshell-git || true   # ③ 错误被 || true 吞掉
```

**两处都会静默失败** —— 脚本照常跑完，看起来一切正常，**但 `quickshell-git` 完全没有被锁**。下一次 `dnf upgrade --refresh`（脚本自己第 6 步就会跑，除非 `SKIP_SYSUPDATE=true`）就可能把 `quickshell-git` 升到别的版本，直接毁掉 ii。

**这是「看起来成功、实际没保护」的典型，比报错更危险。**

### 替代做法（F44 上可用，按推荐度）

**A. 在本地 repo 文件里 exclude（最贴合原意，推荐）**

给 `illogical-impulse` 那个 `file://` 仓库写 `.repo` 时加上 `exclude`：

```ini
# /etc/yum.repos.d/illogical-impulse.repo
[illogical-impulse]
name=illogical-impulse (local)
baseurl=file:///home/<user>/.cache/illogical-impulse-repo
enabled=1
gpgcheck=0
exclude=quickshell-git matugen
```

`exclude` 的意思是「这个包不从本仓库装/升」。配合官方 `matugen`（3.1.0）正好把第 3.4 节那个坑也一起挡了。

**B. 全局 excludepkgs（更粗暴，但覆盖面大）**

```ini
# /etc/dnf/dnf.conf
excludepkgs=quickshell-git
```

**⚠️ 未核实**：dnf5 的 `dnf.conf` 是否仍认 `excludepkgs` 这个名字（dnf5 有 `--setopt=excludepkgs=`，配置项名可能为 `exclude`）。**`? 未核实`** —— 工作机上用 `man 5 dnf5.conf | grep -iA2 exclude` 确认。

**C. 用 dnf4 显式执行**

装了 `python3-dnf-plugin-versionlock` 之后，用 dnf4 的二进制跑：

```bash
sudo dnf4 versionlock add quickshell-git     # 二进制名待工作机确认（dnf4 / dnf-3）
```

**`⚠️ 部分核实`**：dnf4 插件确实存在（版本 4.10.1），但「dnf4 的二进制在 F44 上叫什么、能否与 dnf5 共存操作同一个 rpmdb」**未核实**。这是三条里最不推荐的。

**★ 无论选哪条，装完都要验：**

```bash
dnf repoquery --whatprovides quickshell-git    # 或 dnf list --showduplicates quickshell-git
rpm -q quickshell-git                           # 记录当前 NEVRA
```

并且**回归测试**：`sudo dnf upgrade --refresh --assumeno` 看它是否还在升级列表里。

---

## 附录 A. 硬编码路径移植陷阱（本次核实新发现）

主力机的配置文件里有若干**绝对路径**，在 Fedora 上位置不同 —— 这些**不会报错，只会静默不工作**。全部 `✓ 已核实`（用 Fedora 44 GA 仓库的 `filelists.xml.gz` 逐个查的实际文件路径）。

| 配置文件:行 | 现有写法 | Fedora 44 实际路径 | 后果 |
|---|---|---|---|
| `~/.config/hypr/UserConfigs/Startup_Apps.lua:91` | `/usr/lib/polkit-kde-authentication-agent-1` | **`/usr/libexec/kf6/polkit-kde-authentication-agent-1`**（`polkit-kde-6.6.4`） | pkexec 提权弹窗**永远不出现**，需要授权的操作静默失败 |
| `Startup_Apps.lua:93` | `/usr/lib/pam_kwallet_init` | **`/usr/libexec/pam_kwallet_init`**（`pam-kwallet-6.6.4`） | KDE 应用的 wallet 解锁失效 |
| `Startup_Apps.lua:94` | `/usr/lib/kwalletd6` | **`/usr/bin/kwalletd6`** | 同上 |

### ★ 最优解：用 `hyprpolkitagent` 绕开整张表

`sdegler/hyprland` COPR 提供 `hyprpolkitagent-0.2.0`，装完后可执行文件在 **`/usr/libexec/hyprpolkitagent`**，并自带 `/usr/lib/systemd/user/hyprpolkitagent.service`。

而主力机的 `~/.config/hypr/scripts/Polkit.sh` **已经**在候选列表里探这个路径：

```bash
"/usr/libexec/hyprpolkitagent"     # ← 第 3 个候选，Polkit.sh 里本来就有
```

→ **只要装上 `hyprpolkitagent`，`Polkit.sh` 不改一个字就能在 Fedora 上工作**（它在 `Startup_Apps.lua:34` 就被调用，早于第 91 行）。然后：

- **把 `Startup_Apps.lua:91` 那行注释掉或删掉**（它是 JaKooLit 留下的冗余，C 语言注释原文写的是 `-- custom ones`，而不是 polkit 必须项）。
- `polkit-gnome` 在 Fedora 44 官方**不存在**，`Polkit.sh` 列表里的前几个 gnome 路径在 Fedora 上会落空 —— 这没关系，它是「第一个存在的就用」。

**⚠️ 未核实**：`hyprpolkitagent` 与 Fedora 的 `polkit`（polkitd）DBus 接口版本是否完全兼容。**`? 未核实`** —— 装完在工作机上验一条需要授权的操作（例如 `pkexec true` 或在 ii 设置里点一个需要密码的开关）。

### 其他非绝对路径但值得注意的

- `Startup_Apps.lua:65` `linuxqq-clipsync` —— 用户自写脚本（在 `~/.local/bin/`），随 `configs/.local/bin/` 一起迁移，**没问题**。
- `Startup_Apps.lua:90` `mihomo-party`、`:96` `pano-scrobbler` —— 第三方 GUI 程序，**不在任何 Fedora 仓库里**（`? 未核实`其 Flatpak/COPR 途径）。这两个是 `hl.exec_cmd` 调用，命令不存在时**只会在日志里留一行失败，不影响 Hyprland 启动**。
- `Startup_Apps.lua:37/40` `nm-applet` / `blueman-applet` —— 包名分别是 `network-manager-applet` / `blueman`，**官方仓库有**（✓ 已核实）。
- `Startup_Apps.lua:64` `wl-clip-persist` —— 官方/RPM Fusion 都没有，走 `leloubil/wl-clip-persist` COPR（✓ 已核实，fc44 有 `0.4.1`）。

---

## 附录 B. 版本对齐表（主力机 vs Fedora 44 可得）

`✓ 已核实` —— 左列来自本机 `pacman -Q`，右列来自 Fedora/COPR 仓库元数据。

| 组件 | 主力机（Arch） | Fedora 44 可得 | 差异 |
|---|---|---|---|
| Hyprland | **0.56.2-2** | `sdegler` **0.56.2** | **完全一致** ★ |
| hyprlock | 0.9.6-3 | `sdegler` 0.9.6 | 一致 |
| hypridle | 0.1.8-2 | `sdegler` 0.1.8 | 一致 |
| hyprpicker | 0.4.7-4 | `sdegler` 0.4.7 | 一致 |
| hyprsunset | 0.4.0-3 | `sdegler` 0.4.0 | 一致 |
| hyprland-guiutils | 0.2.2-3 | `sdegler` 0.2.2 | 一致 |
| hyprland-qt-support | 0.1.0-14 | `sdegler` 0.1.0 | 一致 |
| quickshell | AUR pin **git7511545** | ii release **git7511545** | **完全一致** ★ |
| **matugen** | **3.1.0** | 官方 **3.1.0** | **完全一致** ★（**勿用** ii 的 4.1.0） |
| darkman | 2.3.1-1 | 官方 2.2.0 | 小版本落后 |
| nwg-displays | 0.4.4-1 | `tofik/nwg-shell` 0.4.3 | 小版本落后 |
| satty | 0.22.0-1 | `sdegler` 0.20.0 | 落后 |
| wl-clip-persist | 0.5.0-2 | `leloubil` 0.4.1 | 落后 |
| fcitx5 | 5.1.22-1 | 官方 5.1.19 | 落后 |
| librime | 1:1.17.0-5 | 官方 1.16.1 | 落后 |
| tesseract | 5.5.3-1 | 官方 5.5.3 | 一致 |
| qt6ct | 0.11-8 | 官方 0.11 | 一致 |
| Qt6 | — | 官方 **6.10.2** | 见第 2 节的风险 |

**读法**：Hyprland 全家桶 + quickshell + matugen 这**三块最要紧的**在 Fedora 上是**版本完全一致**的 —— 这是「键位一个不能丢」最强的技术保障。其余落后都在小版本级别，风险面主要在「新特性没有」而不是「行为变了」。

---

## 附录 C. 开工前在工作机上该跑的一串验证命令

按顺序，每条都对应上面某个 ⚠️ / ? 条目。**只读，不改系统。**

```bash
# ── 环境基线 ──────────────────────────────
cat /etc/fedora-release
getenforce
dnf --version                      # 确认是 dnf5 还是 dnf4
rpm -q dnf5-plugins                # copr 子命令要先装它

# ── 第 2 节：quickshell-git 能否装上（关键）──
rpm -qpR ~/.cache/illogical-impulse-repo/quickshell-git-*.rpm | grep -i qt6
sudo dnf install --assumeno ~/.cache/illogical-impulse-repo/quickshell-git-*.rpm

# ── 第 3 节：matugen 版本必须是 3.1.0 ──────
dnf list --showduplicates matugen

# ── 第 4 节：NVIDIA 现状（改之前先看清）────
lsmod | grep -E 'nvidia|nouveau'
dnf list installed '*nvidia*' 2>/dev/null
cat /proc/cmdline                 # 看有没有遗留的 nvidia-drm.modeset
mokutil --sb-state                # Secure Boot 开没开

# ── 第 5 节：XDG_MENU_PREFIX（在 Hyprland 会话里跑）
env | grep XDG_MENU_PREFIX

# ── 第 6 节：输入法环境是否被 imsettings 改写 ──
rpm -q imsettings
env | grep -E 'IM_MODULE|XMODIFIERS'
xprop -root XIM_SERVERS

# ── 第 10 节：versionlock 确认不存在 ────────
dnf versionlock list 2>&1 | head -3    # 预期报「没有这个命令」

# ── 附录 A：硬编码路径逐个对 ───────────────
for p in /usr/libexec/kf6/polkit-kde-authentication-agent-1 \
         /usr/libexec/pam_kwallet_init /usr/bin/kwalletd6 \
         /usr/libexec/hyprpolkitagent; do
  [[ -e "$p" ]] && echo "✓ $p" || echo "✗ $p"
done

# ── ghostty 是从哪来的 ─────────────────────
dnf list installed ghostty 2>/dev/null || rpm -q ghostty
ghostty --version
```

---

## 附录 D. 本次核实的**未核实**清单（诚实汇总）

| # | 条目 | 状态 | 怎么验 |
|---|---|---|---|
| 1 | `quickshell-git`(fc44, git7511545) 在 Qt 6.10.2 上能否解依赖 | ⚠️ 部分核实 | 第 2 节 / 附录 C |
| 2 | matugen 4.1.0 是否会真的破坏换壁纸配色 | ⚠️ 部分核实 | 换壁纸后看 colors.json 是否更新 |
| 3 | `AshBuk/Hyprland-Fedora` 是否有 fedora-44 chroot | ? 未核实 | COPR 网页（需绕 Anubis）或 `dnf copr enable` 试 |
| 4 | Secure Boot 签名步骤（`kmodgenca` / `mokutil`）原文 | ? 未核实 | RPM Fusion **Secure Boot Howto** 页 |
| 5 | `XDG_MENU_PREFIX` 在 Fedora 44 上的实际值 | ? 未核实 | 附录 C 有命令；**对迁移无影响**（第 5 节） |
| 6 | `imsettings` 对 fcitx5 的具体干扰程度 | ⚠️ 部分核实 | 附录 C 有命令 |
| 7 | GDM Wayland 会话是否 source `~/.profile` | ? 未核实 | 本项目不依赖它（第 6 节） |
| 8 | SELinux 是否会对 ydotool / 自定义 user unit 报 AVC | ? 未核实 | 真出问题再 `ausearch -m avc` |
| 9 | `pano-scrobbler`、`mihomo-party` 的 Fedora 安装途径 | ? 未核实 | 工作机上现查（Flatpak 大概率有） |
| 10 | dnf5 的 `excludepkgs` 配置项名 | ? 未核实 | `man 5 dnf5.conf` |
| 11 | `dnf4` 二进制在 F44 上能否与 dnf5 共用 rpmdb | ⚠️ 部分核实 | 不推荐走这条路 |
| 12 | `hyprpolkitagent` 与 Fedora polkitd 的兼容性 | ? 未核实 | 装完点一个需要授权的操作 |
| 13 | ghostty 的 Flatpak / Terra / Snap 途径 | ⚠️ 部分核实 | COPR 已够用，无需备选 |
| 14 | RPM Fusion「通过 `omit_drivers` 把 nvidia 排除出 initramfs」 | ? **未经核实，勿照抄** | Howto 原文只说「不推荐打进 initramfs」 |

**另：`packages.fedoraproject.org` 的包页面对已退役包会返回 HTTP 200 且只在版本表里露馅** —— 本次评估中这个陷阱一度把 `hyprland`、`hyprlock`、`hypridle` 全部误判为「存在」。**任何后续核实都不要用「页面能打开」当判据，一律读仓库元数据。**
