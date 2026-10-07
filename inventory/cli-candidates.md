# CLI 工具勾选清单（Arch 主力机 → Fedora 44 工作机）

**怎么用**：勾选的会被装到 Fedora 工作机；本表由主力机的包清单筛出（`pacman -Qqe` 609 个 + `pacman -Qqm` 202 个），未勾的不装。
CLI 工具本身不影响桌面稳定性，装错了代价低 —— 所以这一节**全部由你勾**，不替你决定。

**筛选口径**：只收「在终端里用」的工具。浏览器、IDE、影音播放器、游戏、KDE 全家桶、聊天工具、绘图软件等 GUI 应用一律不收。
不确定的照收，行尾标 `⚠️ 待定`。

**注解口径**（2026-10-08 实测 Fedora 44 官方仓库 + RPM Fusion 44 + 各 COPR 元数据）
- `官方有` —— 包名同名，直接 `dnf install`
- `官方名不同: xxx` —— 要装的包名不一样
- `官方无 → xxx` —— 没官方包，给替代路径（cargo / COPR / 源码 / pipx）
- 无标注 = 见前一行同类（同一小节内相邻同源的行会省略）

**已核实的三处细节**（与常见说法不同，别照抄旧笔记）
- `eza`：Fedora 官方是 0.23.5，比 `copr:alternateved/eza` 的 0.23.4 **更新** —— 直接用官方，不用加那个 COPR。
- `iotop`：Fedora 里叫 `iotop-c`（官方没有叫 iotop 的包）。
- `sshfs`：Fedora 里叫 `fuse-sshfs`。

---

## A. 桌面核心（必迁，不由你勾，列在这里备查）

这一节不勾，是「无论如何都要装」的部分，完整映射见 `package-map.md` / `mapping.toml`：

- **Hyprland 栈**：hyprland(≥0.56, copr:sdegler/hyprland)、hyprland-guiutils、hyprlock、hypridle、hyprpicker、hyprsunset、hyprpolkitagent、hyprshot、hyprland-qt-support、xdg-desktop-portal(+gtk/+hyprland)
- **ii 本体**：quickshell-git（ririko66z/dots-hyprland COPR + 本地 rpm 仓库 + versionlock）、matugen（**官方已有 3.1.0**）、darkman（**官方已有 2.2.0**）、translate-shell、cliphist、cava、playerctl、brightnessctl、ddcutil、upower、geoclue2、gammastep
- **截图/录制**：grim、slurp、swappy、satty、wf-recorder、wl-clipboard
- **输入法**：fcitx5(+configtool/gtk/qt/chinese-addons/rime/mozc)、librime、brise
- **字体**：google-noto-*-cjk、google-noto-fonts-all、wqy-*-fonts、twitter-twemoji-fonts、google-material-symbols-vf-rounded-fonts（COPR）、jetbrains-mono-nerd-fonts（COPR）、material-icons-fonts、bibata-cursor-theme（COPR）、adw-gtk3-theme、darkly（COPR）
- **终端**：ghostty（copr:scottames/ghostty，或 avengemedia/danklinux）、kitty
- **系统**：akmod-nvidia-open、microcode_ctl、zram-generator、power-profiles-daemon、thermald

---

## B. 文件与搜索

- [ ] `bat` — 语法高亮 cat（官方有）
- [ ] `eza` — ls 替代（官方有，0.23.5；不需要 alternateved/eza COPR）
- [ ] `broot` — 交互式目录树（官方无 → `cargo install broot`）
- [ ] `nnn` — 终端文件管理器（官方有）
- [ ] `yazi` — 终端文件管理器（官方无 → `cargo install --locked yazi-fm yazi-cli`）
- [ ] `ncdu` — 磁盘占用 TUI（官方有）
- [ ] `duf` — df 的漂亮版（官方有）
- [ ] `dua-cli` — 并行 du（官方有）
- [ ] `dysk` — 另一款 df 替代（官方无 → `cargo install dysk`）
- [ ] `compsize` — btrfs 压缩率统计（官方有）
- [ ] `plocate` — 快速 find / locate（官方有）
- [ ] `ripgrep` — grep 替代（官方有）
- [ ] `chafa` — 终端里看图（官方有）
- [ ] `vivid` — LS_COLORS 主题生成（官方无 → `cargo install vivid`）
- [ ] `zoxide` — 智能 cd（官方有）
- [ ] `less` — 分页器（官方有）
- [ ] `nano` — 简单编辑器（官方有；`nano-syntax-highlighting` 官方无独立包，语法高亮已含在 nano 里）
- [ ] `neovim` — 编辑器（官方有）
- [ ] `unzip` `zip` `unrar` — 压缩包工具（官方都有）
- [ ] `stow` — dotfiles 软链管理（官方有）
- [ ] `which` — 官方有
- [ ] `httpdirfs` — 把 HTTP 目录挂成文件系统（官方有）
- [ ] `sshfs` — 官方名不同: `fuse-sshfs`
- [ ] `rclone` — 云盘同步（官方有）
- [ ] `adbfs-rootless-git` — 免 root 挂载安卓（官方无 → 源码构建）⚠️ 待定
- [ ] `baidupcs-go` — 百度网盘命令行（官方无 → 源码/二进制）⚠️ 待定
- [ ] `cht.sh-git` — 命令速查客户端（官方无 → 其实是个 shell 脚本，装 `curl` 即可）
- [ ] `apg` — 随机密码生成（官方有）

## C. 系统监控

- [ ] `btop` — 资源监控 TUI（官方有）
- [ ] `glances` — 全能监控（官方有）
- [ ] `s-tui` — CPU 温度/频率 TUI（官方有）
- [ ] `nvtop` — GPU 监控（官方有）
- [ ] `iotop` — 磁盘 IO 排行（官方名不同: `iotop-c`）
- [ ] `powertop` — 功耗诊断（官方有）
- [ ] `inxi` — 系统信息（官方有）
- [ ] `hwinfo` — 硬件信息（官方有）
- [ ] `dmidecode` — 官方有
- [ ] `lsscsi` — 官方有
- [ ] `usbutils` — lsusb（官方有）
- [ ] `sysfsutils` — 官方有
- [ ] `smartmontools` — 硬盘 SMART（官方有）
- [ ] `hdparm` — 官方有
- [ ] `turbostat` — 官方无独立包 → 在 `kernel-tools` 里
- [ ] `cpupower` — 官方无独立包 → 在 `kernel-tools` 里
- [ ] `msr-tools` — 官方有
- [ ] `stress` `stress-ng` — 压测（官方都有）
- [ ] `speedometer` — 网速/磁盘速率小条（官方无 → PyPI，pipx 装）⚠️ 待定
- [ ] `tuptime` — 开机时长统计（官方有）
- [ ] `scx-scheds` — sched_ext 调度器（官方按调度器拆包: `scx_layered` / `scx_rusty`）
- [ ] `evhz-git` — 鼠标回报率测试（官方无 → 源码构建）⚠️ 待定
- [ ] `wtfutil-bin` — 终端仪表盘（官方无 → 二进制）⚠️ 待定

## D. 网络

- [ ] `bind` — 提供 dig/nslookup（官方有）
- [ ] `mtr` — traceroute + ping（官方有）
- [ ] `nmap` — 端口扫描（官方有）
- [ ] `arp-scan` — 局域网探测（官方有）
- [ ] `tcpdump` — 抓包（官方有）
- [ ] `nexttrace-bin` — 可视化路由追踪（官方无 → 源码/二进制）⚠️ 待定
- [ ] `stunclient` — STUN 测试（官方无）⚠️ 待定
- [ ] `ethtool` — 网卡工具（官方有）
- [ ] `nss-mdns` — .local 解析（官方有）
- [ ] `dnsmasq` — DNS/DHCP（官方有）
- [ ] `NetworkManager` — nmcli（官方有；工作机默认自带）
- [ ] `iwd` — iwd/iwctl（官方有，跟 wpa_supplicant 二选一）
- [ ] `wpa_supplicant` — 官方有
- [ ] `modemmanager` — 官方有
- [ ] `firewalld` — firewall-cmd（官方有，工作机默认自带）
- [ ] `iptables` — 官方有
- [ ] `inetutils` — telnet/ftp 等（官方有）
- [ ] `ntp` — 官方无同名包 → 用 Fedora 的 `chrony`
- [ ] `s-nail` — 命令行发邮件（官方有）
- [ ] `tailscale` — 官方有
- [ ] `zerotier-one` — 官方无 → RPM Fusion 有
- [ ] `easytier` — 组网工具（官方无 → 源码/二进制）⚠️ 待定
- [ ] `xl2tpd` — L2TP（官方无）⚠️ 待定
- [ ] `aria2` — 下载器（官方有）
- [ ] `curl` — 官方有

## E. 开发工具

- [ ] `git` — 官方有
- [ ] `github-cli` — gh（官方有）
- [ ] `python` + `python-pip` — 官方名不同: `python3` + `python3-pip`
- [ ] `python-pipx` — 官方名不同: `pipx`
- [ ] `uv` — Python 包/环境管理（官方有）
- [ ] `mise` — 多语言版本管理（官方无 → 官方安装脚本）
- [ ] `jdk8-openjdk` `jdk17-openjdk` `jdk21-openjdk` — 官方 F44 只有 `java-25-openjdk` / `java-latest-openjdk`（老版本要 SDKMAN）
- [ ] `miniconda3` — 官方无 → 建议改用 `uv`/venv，别引 conda ⚠️ 待定
- [ ] `jupyterlab` — 官方有
- [ ] `jupyter-notebook` — 官方名不同: `python3-notebook`
- [ ] `mariadb` — 客户端/服务端（官方有）
- [ ] `docker` — 官方名不同: `moby-engine`（或 podman）
- [ ] `qemu-user-static` — 官方有
- [ ] `valgrind` — 内存调试（官方有）
- [ ] `strace` — 系统调用跟踪（官方有）
- [ ] `cpptrace` — C++ 栈回溯库（官方无）⚠️ 待定
- [ ] `tree-sitter-cli` — 官方有
- [ ] `typst` — 排版（官方无 → `cargo install typst-cli`）
- [ ] `mdbook` — 官方有；`mdbook-epub` / `mdbook-graphviz` 官方无 → cargo
- [ ] `texinfo` — 官方有
- [ ] `texlive-basic` `texlive-latex` `texlive-latexextra` — 官方名不同: `texlive-scheme-basic` 等（texlive-* 命名体系不同）
- [ ] `octave` + `octave-control` — 官方有 octave（控制包另算）
- [ ] `cangjie-lts-bin`（+ runtime/tools）— 仓颉语言工具链（官方无 → 官方二进制）⚠️ 待定
- [ ] `task` — taskwarrior（官方有）
- [ ] `taskwarrior-tui` — 官方无 → cargo ⚠️ 待定
- [ ] `debtap` — deb 转 Arch 包（Fedora 上无意义，用 `dpkg`+`alien`）⚠️ 待定
- [ ] `cli11` — C++ 头文件库（官方有）
- [ ] `jq` `yq` — JSON/YAML 处理（官方都有）
- [ ] `sqlite` — 官方有
- [ ] `socat` — 官方有
- [ ] `expect` — 官方有
- [ ] `sshpass` — 官方有
- [ ] `stow` — 见 B 节（不重复勾）

## F. 文本与媒体处理

- [ ] `pandoc-bin` — 文档转换（官方名不同: `pandoc-cli` + `pandoc-common`，另有 `pandoc-pdf`）
- [ ] `asciidoc` — 官方有
- [ ] `aspell` — 拼写检查（官方有；`hunspell` 也在官方）
- [ ] `perl-image-exiftool` — 照片元数据（官方名不同: `perl-Image-ExifTool`）
- [ ] `perl` — 官方有
- [ ] `mediainfo` — 媒体信息（官方有）
- [ ] `sox` — 音频处理（官方有）
- [ ] `shntool` — 无损音频切分（官方有）
- [ ] `mp3gain` — MP3 音量归一（官方有）
- [ ] `loudgain-ffmpeg7` — 响度归一（官方无 → cargo/源码）⚠️ 待定
- [ ] `beets` — 音乐库管理（官方有）
- [ ] `imagemagick` — 官方名不同: `ImageMagick`（命令是 magick）
- [ ] `ffmpegthumbnailer` — 视频缩略图（官方有）
- [ ] `yt-dlp` — 官方有
- [ ] `twitch-downloader-bin` — 官方无 ⚠️ 待定
- [ ] `mplayer` — 终端播放器（官方有 mplayer；但纯 CLI 用途少）⚠️ 待定
- [ ] `libmad` `opusfile` `taglib1` `libgsf` `libspng` — 媒体库，通常由上面的包自动带入，一般不用手动勾 ⚠️ 待定

## G. 剪贴板与截图（输入类）

- [ ] `wl-clipboard` — wl-copy/wl-paste（官方有；ii 脚本重度依赖，基本必勾）
- [ ] `cliphist` — 剪贴板历史（官方有）
- [ ] `wl-clip-persist` — 剪贴板持久化（官方无 → `cargo install wl-clip-persist`）
- [ ] `wtype` — 模拟键盘输入（官方有）
- [ ] `ydotool` — 模拟键鼠（官方有；装完还要起 ydotoold + uinput 权限）
- [ ] `grim` — Wayland 截图（官方有）
- [ ] `slurp` — 区域选择（官方有）
- [ ] `swappy` — 截图标注（官方有）
- [ ] `satty` — 截图标注（官方无 → copr:sdegler/hyprland）
- [ ] `wf-recorder` — 录屏（官方有）
- [ ] `hyprshot` — Hyprland 截图封装（官方无 → copr:sdegler/hyprland）
- [ ] `hyprpicker` — 取色器（官方无 → copr:sdegler/hyprland）
- [ ] `xclip` — X11 剪贴板（Wayland 下基本用不上，`wl-clipboard` 替代）
- [ ] `xcur2png` — 光标主题转 PNG（官方无 → copr:sdegler/hyprland）⚠️ 待定
- [ ] `win2xcur` — Windows 光标转换（官方无）⚠️ 待定

## H. 其他杂项

- [ ] `zsh` — 官方有
- [ ] `zsh-autosuggestions` — 官方有
- [ ] `zsh-syntax-highlighting` — 官方有
- [ ] `zsh-fast-syntax-highlighting-git` — 官方无独立包 → 用上面的官方版即可
- [ ] `zsh-theme-powerlevel10k-bin-git` — 官方无 → git clone 到 ~/.local/share（不需要包）
- [ ] `zplug` — zsh 插件管理器（官方无 → git clone）
- [ ] `starship` — 提示符（官方无 → copr:atim/starship，或 cargo）
- [ ] `atuin` — shell 历史同步（官方有）
- [ ] `tldr` — 例子速查（官方有；`tealdeer` 官方也有）
- [ ] `navi` — 交互式 cheatsheet（官方有）
- [ ] `byobu` — tmux/screen 封装（官方有；也可以直接装 `tmux`）
- [ ] `ccze` — 日志着色（官方有）
- [ ] `lolcat` `cowsay` `figlet` `toilet` `sl` `fortune-mod` `bsd-games` `hollywood` — 玩具（前 7 个官方都有；`hollywood` 官方无 → 源码）⚠️ 待定
- [ ] `udiskie` — 自动挂载 U 盘（官方有）
- [ ] `bluez-utils` — bluetoothctl（官方有）
- [ ] `wireplumber` — wpctl 音量控制（官方有，桌面核心本来就有）
- [ ] `pamixer` — 音量控制（官方有）
- [ ] `playerctl` — 媒体控制（官方有）
- [ ] `cava` — 音频可视化（官方有）
- [ ] `brightnessctl` — 亮度（官方有）
- [ ] `ddcutil` — 外接显示器亮度（官方有）
- [ ] `gammastep` — 色温（官方有）
- [ ] `logrotate` — 日志轮转（官方有）
- [ ] `man-db` `man-pages` — man 手册（官方都有）
- [ ] `haveged` — 熵池（官方有；现代内核基本不需要）
- [ ] `rtkit` — 实时调度（官方有）
- [ ] `protondb-cli` — ProtonDB 查询（官方无）⚠️ 待定
- [ ] `steamtinkerlaunch` — Steam 启动包装（官方无）⚠️ 待定
- [ ] `pkgfile` — 见下节（Arch 专属）

## I. Arch 专属（无 Fedora 对应，需人工决定）

这些不用勾包，勾的是「要不要在工作机上找等价做法」：

- [ ] `paru` — AUR 助手（Fedora: `dnf` + `dnf copr enable`）
- [ ] `yay` — 同上（Fedora: `dnf`）
- [ ] `pacman-contrib` — checkupdates/paccache（Fedora: `dnf-utils`，checkupdates → `dnf check-update`）
- [ ] `downgrade` — 降级（Fedora: `dnf history undo` / `dnf downgrade`）
- [ ] `rebuild-detector` — 重建检测（Fedora: `needs-restarting -r`）
- [ ] `reflector` — 镜像排序（Fedora: dnf fastestmirror 自动做）
- [ ] `pkgfile` — 查文件属于哪个包（Fedora: `dnf provides` 或 `PackageKit-command-not-found`）
- [ ] `archlinux-xdg-menu` — Arch 专用（不迁）
- [ ] `lsb-release` — F44 官方无（脚本里改读 `/etc/os-release`）
- [ ] `base` `base-devel` — Arch 元包（Fedora: `@development-tools` / 基础组）
- [ ] `linux` `linux-zen` `linux-headers` — 内核（Fedora: `kernel` / `kernel-devel` / `kernel-headers`；无 zen）
- [ ] `systemd-sysvcompat` `dracut` `filesystem` `device-mapper` — 发行版底层包（Fedora 自带对应实现）
- [ ] `udev` 相关（`eos-hooks` 等）— EndeavourOS 专属，不迁
- [ ] `welcome` `eos-*` `endeavouros-*` `reflector-simple` `nvidia-inst` — EndeavourOS 全家桶（不迁）
- [ ] `hwdetect` — Arch 安装器脚本（不迁）
- [ ] `timeshift-autosnap` — Arch+pacman 钩子（不迁；要自动快照用 snapper，官方有）
- [ ] `nbfc-linux` — 风扇控制（官方无 → 源码构建，工作机建议放弃）
- [ ] `debtap` — 见 E 节
- [ ] `intel-undervolt` — CPU 降压（官方无；工作机不做）
- [ ] `greetd` `greetd-tuigreet` `nwg-hello` — 登录管理器（工作机保留 GDM，不迁）
- [ ] `foot` — 终端（工作机用 ghostty；官方其实有 foot，真要用直接装）
- [ ] `lib32-*`（约 20 个）— Fedora 不按这套包名打包，32 位依赖由 RPM Fusion 的 steam 自动带入
- [ ] `qt5-styleplugins` `qt6gtk2` — Qt GTK 主题插件（Fedora: `qadwaitadecorations-qt5` + `qt6-qtwayland-adwaita-decoration`）
- [ ] `python-pywal` `wallust-git` `python-backports-zstd` `python-pkg_resources` 等 AUR Python 包 — 已被 matugen / 官方包取代
- [ ] `linuxqq-clipsync-git` `liteloader-qqnt-bin` `maliit-keyboard` `xorg-font-utils` `icoutils` 类 AUR 边角包 — 不迁
