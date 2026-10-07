# darkman 活钩子目录（dark 模式）

**这个目录在主力机上真正被执行**（darkman 2.3.1，journal 原文
`Found legacy script path=/home/cynsm/.local/share/dark-mode.d/…`）。
姊妹目录 `light-mode.d/` 对应 light 模式。

## 规则（2026-10-08 用 journal + 二进制字符串查实）

- **只有执行位决定跑不跑**（二进制内错误串 `File not executable; ignoring.`）。
  文件名里的 `.disabled` 只是给人看的注释，darkman 不认；
  停用 = `chmod -x`，恢复 = `chmod +x`。
- 钩子按文件名排序执行，**收不到参数**（legacy 格式；现代格式
  `~/.local/share/darkman/` 单脚本收 `$1` = dark|light，本机未用）。
- 改完以后想确认它真跑了，**别信文件，信 journal**：
  ```bash
  journalctl --user -u darkman | grep -E "Found|Running script" | tail
  ```

## 本机当前这套

| 文件 | 执行位 | 干什么 |
|---|---|---|
| `10-term-theme.disabled` | ✗ 已停 | （旧）切 foot 主题 —— 2026-10-07 咬过一次配色，见 R8 |
| `15-fcitx5-theme` | ✓ 在跑 | 只 `gsettings set color-scheme prefer-dark/light`（fcitx5 的 UseDarkTheme 与 foot 选段都读它）|
| `20-gtk-theme.disabled` | ✗ 已停 | （旧）切 gtk-theme —— 同上次事故 |
| `90-quickshell-ii` | ✓ 在跑 | `exit 0` 空桩 |

背景与事故链：`docs/known-issues.md` R8。
