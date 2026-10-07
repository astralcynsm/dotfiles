pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// 本地新增：外观 preset 系统。
//
// preset = 一组 Config.options.appearance.* 的快照，存成 JSON 放在
// ~/.config/illogical-impulse/appearance-presets/ 下。套用一个 preset 就是把它的键
// 逐个写回 Config —— **preset 不是模式，是一次性赋值**，套完仍可在设置页里逐项微调。
//
// 为什么放用户配置区而不是 ii 目录内：ii 更新时可能带 --delete，会连新增文件一起清掉。
//
// 文件格式（两种写法都认）：
//   { "name": "...", "description": "...", "values": { "rounding.scale": 0, ... } }
//   { "rounding.scale": 0, ... }        // 直接平铺
// values 里的键是「appearance 下的相对路径」，套用时统一补 "appearance." 前缀。
//
// ⚠ JsonObject 只能写已定义的 key —— 这里用到的每个键都必须先在 modules/common/Config.qml
//   的 appearance 段里存在，否则 setNestedValue 会静默写不进去（不报错，但也不生效）。
//
// ⚠ setNestedValue 会把 "true"/"false"/纯数字形式的**字符串**用 JSON.parse 转成对应类型，
//   所以 JSON 里写 "0.6" 和 0.6 效果相同；但曲线名这类真正的字符串不受影响。

Singleton {
    id: root

    readonly property string presetDir: `${Directories.shellConfig}/appearance-presets`

    // 目录里的 preset 名（不含 .json 后缀），按字典序
    property list<string> presetNames: []
    // 上次操作的结果，给设置页显示用
    property string lastAppliedName: ""
    property string lastError: ""

    property string pendingName: ""

    // ── 枚举目录 ────────────────────────────────────────────────────────
    // ii 没有目录枚举 API，用 ls 最稳（Process 的既有用法见 services/SystemInfo.qml）。
    // 目录不存在时 ls 失败，但 2>/dev/null 吞掉错误、stdout 为空，列表就是空的，不会崩。
    Process {
        id: listProc
        running: true
        command: ["bash", "-c", `ls -1 "${root.presetDir}" 2>/dev/null | sed -n 's/\\.json$//p' | sort`]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                root.presetNames = listCollector.text.split("\n")
                    .map(s => s.trim())
                    .filter(s => s.length > 0);
            }
        }
    }

    // 手动刷新（用户往目录里丢了个新 JSON 后，不用重启 ii）
    function refresh() {
        listProc.running = false;
        listProc.running = true;
    }

    // ── 读取并套用 ──────────────────────────────────────────────────────
    // 用 Process + cat 而不是 FileView：FileView 是声明式的，给「运行时才知道路径」
    // 的场景用起来别扭；cat 的退出码还能顺便区分「文件不存在」和「JSON 写错了」。
    Process {
        id: readProc
        running: false
        command: []
        stdout: StdioCollector {
            id: readCollector
            onStreamFinished: {
                const txt = readCollector.text;
                if (!txt || txt.trim().length === 0) return; // 读不到内容时交给 onExited 报错
                try {
                    const data = JSON.parse(txt);
                    const values = data.values ?? data;
                    // 元数据键别当成配置项写进去
                    if (values.name !== undefined) delete values.name;
                    if (values.description !== undefined) delete values.description;
                    const n = root.applyValues(values);
                    root.lastAppliedName = root.pendingName;
                    root.lastError = "";
                    console.log(`[AppearancePresets] 套用 "${root.pendingName}"，写入 ${n} 项`);
                } catch (e) {
                    root.lastError = `JSON 解析失败: ${e}`;
                    console.log(`[AppearancePresets] ${root.lastError}`);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.lastError = `读取失败: "${root.pendingName}.json" 不存在或不可读 (exit ${exitCode})`;
                console.log(`[AppearancePresets] ${root.lastError}`);
            }
        }
    }

    function applyPreset(name) {
        if (!name || name.length === 0) return false;
        pendingName = name;
        lastError = "";
        readProc.command = ["cat", `${root.presetDir}/${name}.json`];
        readProc.running = true;
        return true;
    }

    // 把展开后的 values 逐个写回 Config。
    // setNestedValue 的路径是相对 Config.options 的，所以这里补 "appearance." 前缀。
    function applyValues(values) {
        let count = 0;
        for (const key in values) {
            Config.setNestedValue(`appearance.${key}`, values[key]);
            ++count;
        }
        return count;
    }
}
