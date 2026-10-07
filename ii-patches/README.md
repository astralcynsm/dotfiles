# ii-patches —— ii 上游代码的本地补丁（整树快照 + 记账）

## 资产在哪

对 ii 上游（[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)）的全部本地修改
**以整树快照**的形式保存在：

```
configs/.config/quickshell/ii/      ← 954 个文件 / 6.1 MB
```

之所以不存 `.patch` 文件：改动与上游代码纠缠很深（bar、侧栏五页、设置页、悬浮窗各处交织），
且实际工作流一直是 rsync 复制式而不是 patch 式。整树快照 = 部署后与主力机逐字节一致。

## 权威登记册

**`configs/.config/quickshell/ii/LOCAL-PATCHES.md`**（1559 行 / 13 节）是唯一权威账目，
记录了每处补丁的内容、原因、验证方法。它自己的结构是：
顶部一张「哪些文件会被上游同步覆盖」总表 + 各节内的补充表（如 §11 外观参数化）。
**本文件不复制那份清单，避免两处分叉 —— 要计数、要清单，去读它。**

同步 ii 上游前必须：先读那顶部的总表（标了"新/改"以及"上游有同名文件吗"）。

## quickshell.lock

钉死 quickshell 二进制的 revision（`qs --version` 必须命中最后一行 sha）。
配套验证脚本：`scripts/verify/20-quickshell.sh`。

## 上游 base commit：**没有记录**（诚实声明）

2026-09 起对 ii 的改进是直接 rsync 复制式跟进的，**没记过上游 base commit**。
这意味着没有 commit 级 diff 可用。未来同步 ii 上游的正确姿势不是 diff，而是：
把上游最新铺到临时目录 → 按 `LOCAL-PATCHES.md` 逐节重放 → 实机验证。
流程见 `docs/upstream-sync.md`。

## 相关

- 同步流程与"回流"规则：`docs/upstream-sync.md`
- 上游同步会覆盖补丁这一事实的风险条：`docs/known-issues.md` R2
- 主题框架（⚠️ 未实施，别当事实）：`docs/theming-framework.md`
