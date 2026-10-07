# ⚠️ 本目录里的 `*-mode.d/` 钩子**从来不会执行**

darkman **不读** `~/.config/darkman/`。它只扫 `$XDG_DATA_HOME` 下的钩子目录，
本机实测跑的是：

```
~/.local/share/dark-mode.d/     ← 真正生效的那套（repo 对应路径 configs/.local/share/…）
~/.local/share/light-mode.d/
```

本目录下 `dark-mode.d/20-quickshell-ii.sh` 与 `light-mode.d/20-quickshell-ii.sh`
是 2026-09-23 放的，**从没跑过**（journal 里 `Found legacy script path=…` 只出现
`~/.local/share/` 的路径）。放在这里只是留档（里面「静态主题就跳过 ii 配色重算」
的护栏逻辑若以后要复活，得先搬去正确的目录）。

机制、证据链、验证方法（`journalctl --user -u darkman | grep -E "Found|Running script"`）
见 `docs/known-issues.md` **R8**。

> 一句话：darkman 的钩子**只认执行位，不看文件名** ——
> 改名 `.disabled` 无效，`chmod -x` 才是停用；放错目录则静默地永不运行。
