pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common

// 中文输入法字数统计。
//
// 数据来自用户自写的 rime_counter_rs（~/.local/bin/rime_counter_rs）。
// 那个程序是个常驻 daemon：用 inotify 盯着 fcitx5 的词库目录
// （~/.local/share/fcitx5/rime/py_wordscounter/），把结果写成一个很小的
// JSON 到 /tmp/rime_status.json，格式是 waybar 的自定义模块协议：
//
//   { "text":     "2074 字",          // 给 bar 上显示的短文本
//     "tooltip":  "<span …>…</span>", // Pango 标记的富文本
//     "class":    "active",           // 有没有数据 / 输入法状态
//     "alt":      "ime" }
//
// 这里不去跑任何计算，只做两件事：读那个 JSON、把 tooltip 从 Pango
// 翻译成 Qt 能认的富文本（见 pangoToQt）。
//
// 用 FileView + watchChanges（inotify）而不是 Timer 轮询——daemon 一写文件
// 就立刻反映到 bar 上，不用等下一个轮询周期。
//
// daemon 没跑时文件不存在，FileView 默认会往日志里写
// "Read of … failed: File does not exist."，所以关掉 printErrors。
// 实测过这个组合的行为（FileView 会在父目录上重置监视）：
//   文件不存在 → loadFailed，text() 为空
//   文件被创建 / 被改写 → fileChanged → reload() → loaded
//   文件被删掉 → loadFailed，text() 清空（这里不采信，保留上一次的显示值）
//   文件被重建 → fileChanged → loaded，自动恢复
// 所以 daemon 挂掉再起来不需要任何额外逻辑。
Singleton {
    id: root

    readonly property bool enabled: Config?.options?.bar?.wordCount?.enable ?? false
    readonly property string statusFile: Config?.options?.bar?.wordCount?.statusFile ?? ""

    property string text: ""      // bar 上显示
    property string tooltip: ""   // 已转成 Qt 富文本
    property string state: ""     // JSON 的 class 字段
    property string alt: ""       // JSON 的 alt 字段

    // 读到过一次有效数据才让 bar 显示这个组件——daemon 没跑时
    // 不要留一个永远是 "--" 的摆设占着位置
    readonly property bool available: root.state.length > 0

    function ingest(raw) {
        if (!raw || raw.trim().length === 0)
            return;

        let obj;
        try {
            obj = JSON.parse(raw);
        } catch (e) {
            // 大概率是读到了写入过程中的半截文件。不用补一次重读：
            // daemon 写完还会再触发一次 fileChanged，下一次就读到完整的了。
            // 这里直接返回，也就不会把界面上已有的值刷成空的。
            return;
        }

        root.text = obj.text ?? "";
        root.tooltip = root.pangoToQt(obj.tooltip ?? "");
        root.state = obj.class ?? "";
        root.alt = obj.alt ?? "";
    }

    // Pango 标记 → Qt 富文本。
    //
    // daemon 是按 Pango 写的（waybar 的 tooltip 吃 Pango），Qt 不认：
    //   - Pango 把样式写成属性：<span weight='bold' color='#a6e3a1'>
    //   - Qt 的富文本把裸换行当空白，整段会挤成一行，所以 \n 得变 <br/>
    //
    // 颜色和粗体必须拆成两个标签，这是实测出来的（见下），
    // Qt 的 <span style="…"> **只认 font-weight / font-family，不认 color**：
    //
    //   <span style="color:#a6e3a1">…</span>                    → 灰的，没生效
    //   <span style="font-weight:bold">…</span>                 → 粗体，生效
    //   <span style="font-weight:bold;color:#a6e3a1">…</span>   → 只有粗体，颜色丢
    //   <font color="#a6e3a1">…</font>                          → 绿，生效
    //   <b>…</b>                                                → 粗，生效
    //
    // 所以 weight+color 的组合要展开成 <b><font color="…">…</font></b>。
    //
    // 这里不再截断行数：tooltip 现在走 StyledPopup（独立 PanelWindow），
    // 不受 bar 那 40px 的高度限制。早先用 StyledToolTip 时它渲染在 bar
    // 窗口里、只容得下 3 行，才需要砍掉后 7 天的明细。
    function pangoToQt(s) {
        if (!s)
            return "";

        const smallPx = Appearance?.font.pixelSize?.smaller ?? 12;

        return s
            .replace(/<span\s+weight='([^']*)'\s+color='([^']*)'\s*>([\s\S]*?)<\/span>/g,
                     (_, weight, color, inner) => {
                         // Pango 的 weight 不只是 bold，还有 heavy/semibold 这些
                         const isBold = /^(bold|heavy|ultrabold|semibold|demibold)$/i.test(weight);
                         const colored = `<font color="${color}">${inner}</font>`;
                         return isBold ? `<b>${colored}</b>` : colored;
                     })
            .replace(/<span\s+size='small'>/g,
                     `<span style="font-size:${smallPx}px;font-family:monospace">`)
            .replace(/\n/g, "<br/>");
    }

    FileView {
        id: statusFileView
        path: root.enabled ? root.statusFile : ""
        watchChanges: true
        printErrors: false // 文件不存在是正常状态（daemon 没跑），别刷日志
        onFileChanged: reload()
        onLoaded: root.ingest(statusFileView.text())
    }
}
