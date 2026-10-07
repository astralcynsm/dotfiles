# 本地补丁记录（ii 上游代码）

这里记的是**对 ii 上游文件的本地修改**。
从上游重新同步（rsync / git pull + 复制 dots）会**覆盖**这些改动，届时按本文重新施加。

---

## 1. `scripts/colors/switchwall.sh` — matugen ≥3 兼容

**症状**

换壁纸时终端里出现：

```
error: unexpected argument '--source-color-index' found

Usage: matugen [OPTIONS] <COMMAND>
```

**影响（比看上去严重）**

`matugen` 那一步失败后，脚本**不会**中止（没有 `set -e`），继续往下跑
`generate_colors_material.py` 和 `applycolor.sh`。于是：

| 产物 | 是否更新 | 谁在用 |
|---|---|---|
| `material_colors.scss` | ✅ 更新 | `applycolor.sh` → 运行中终端的转义序列 |
| `colors.json` | ❌ **不更新** | `MaterialThemeLoader.qml` → **ii 整个界面的配色** |
| `colors.lua` / `hyprlock` / `foot` / `gtk3` | ❌ **不更新** | Hyprland 边框、锁屏、终端、GTK 应用 |

也就是"换了壁纸，ii 的界面颜色纹丝不动"，只有终端里推的转义序列变了。

**根因**

`matugen --help` 显示：

```
Usage: matugen [OPTIONS] <COMMAND>
```

`--source-color-index` 是 matugen **2.x** 的全局选项，**3.0 起被移除**。
上游 ii 的 `switchwall.sh:184` 无条件带上它：

```bash
matugen_args=(--source-color-index 0)
```

本机 `matugen-bin 3.1.0-1`（官方源 `extra/matugen` 已是 4.2.0，同样没有该选项）。
上游仓库没有任何 matugen 版本约束，所以这是 ii 与新版 matugen 的真实不兼容。

**补丁内容**

把第 184 行改成能力探测：

```bash
    # --- [本地补丁 / LOCAL PATCH] 见 scripts/colors/LOCAL-PATCHES.md ---
    # 上游 ii 假定 matugen 2.x，那里 --source-color-index 是全局选项。
    # matugen >= 3 已移除它，导致本脚本每次换壁纸都在 matugen 这步报错，
    # 于是 colors.json（ii 自己 UI 配色的来源）不会被更新。
    # 这里探测一下能力：支持就照旧带上，不支持就省略。
    matugen_args=()
    if matugen --help 2>&1 | grep -q -- '--source-color-index'; then
        matugen_args+=(--source-color-index 0)
    fi
```

**为什么省略掉是等价的**

2.x 里这个参数用来从图片提取出的多个候选色里挑第 0 个当种子色。
3.x 取消了候选列表，matugen 自己决定种子色，因此没有替代参数——
直接不加即可，实测 `matugen image <图> --mode dark --dry-run --json hex` 正常输出。

**验证方法**

```bash
~/.config/theme-switcher/switch.sh --wallpaper ~/Pictures/wallpapers/<图>.jpg
# 应看到 "✓ ii 已应用壁纸并重绘"，且无 matugen error
stat -c '%y' ~/.local/state/quickshell/user/generated/colors.json   # 时间应是刚才
```

**该补丁以外，`switchwall.sh` 用到的其余参数在 matugen 3.1.0 上均有效**：
`image <path>`、`color hex <hex>`、`--mode dark|light`、`--type scheme-*`（已逐一核对 `--help`）。
