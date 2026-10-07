pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions

// 系统指标（本地新增，非上游）。
//
// 数据来自 ii-stats-daemon（systemd user 服务，见 ~/.local/bin/ii-stats-daemon）
// 每 10 秒重写的 system_summary.json：
//
//   { "updated_at": "…",
//     "current":  { cpu, mem{...}, temps{...}, gpu{...}, fans[], bat{...}, disk{...},
//                   load{...}, gpu_procs[] },
//     "today":    { cpu{avg,max,curve[200]}, mem{…}, cpu_temp{…}, gpu_temp{…},
//                   gpu_power{…}, date },
//     "history":  [ {date, samples, cpu_avg, cpu_max, gpu_temp_max}, … 30 天 ] }
//
// 曲线是 24 小时切成 200 段的平均，空桶是 null；Graph 控件收不了 null，
// 所以这里负责补成 0..1 的 list<real>（沿用前一个有效值）。
Singleton {
    id: root

    readonly property bool enabled: Config?.options?.sidebar?.systemMonitor?.enable ?? false
    readonly property string summaryFile: {
        const configured = Config?.options?.sidebar?.systemMonitor?.summaryFile ?? "";
        if (configured.length > 0)
            return configured;
        return FileUtils.trimFileProtocol(`${Directories.home}/.local/share/ii-stats/system_summary.json`);
    }

    property var summary: ({})
    property double loadedAtMs: 0
    property int tick: 0 // 每 10 秒 +1，仅用来让 fresh / 时间显示重新求值

    readonly property bool available: Object.keys(root.summary).length > 0
    readonly property string updatedAt: root.summary.updated_at ?? ""
    // 采集器挂了（或没起）时页面要能自己说出来，别让用户看着旧数字
    readonly property bool fresh: root.available && (Date.now() - root.loadedAtMs) < 30000

    readonly property var cur: root.summary.current ?? ({})
    readonly property var cpu: root.cur.cpu
    readonly property var mem: root.cur.mem ?? ({})
    readonly property var temps: root.cur.temps ?? ({})
    readonly property var gpu: root.cur.gpu ?? ({})
    readonly property var bat: root.cur.bat ?? ({})
    readonly property var disk: root.cur.disk ?? ({})
    readonly property var loadInfo: root.cur.load ?? ({})
    readonly property var fans: root.cur.fans ?? []
    readonly property var gpuProcs: root.cur.gpu_procs ?? []
    readonly property var today: root.summary.today ?? ({})
    readonly property var historyDays: root.summary.history ?? []

    // ── 今日曲线（0..1，给 Graph 用）────────────────────────────────────────
    // 指标表：key 对应 daemon 里的字段名，scale 是归一化的满量程
    readonly property var metricList: [
        {
            "key": "cpu",
            "name": Translation.tr("CPU"),
            "icon": "planner_review",
            "scale": 100
        },
        {
            "key": "gpu_temp",
            "name": Translation.tr("GPU 温度"),
            "icon": "thermometer",
            "scale": 100
        },
        {
            "key": "gpu_power",
            "name": Translation.tr("GPU 功耗"),
            "icon": "bolt",
            "scale": 60
        },
        {
            "key": "mem",
            "name": Translation.tr("内存"),
            "icon": "memory",
            "scale": 100
        },
        {
            "key": "cpu_temp",
            "name": Translation.tr("CPU 温度"),
            "icon": "device_thermostat",
            "scale": 100
        }
    ]

    readonly property var metricKeys: root.metricList.map(m => m.key)

    function metricAt(index) {
        return root.metricList[index] ?? root.metricList[0];
    }

    function metricData(key) {
        return root.today[key] ?? ({});
    }

    function curveFor(key) {
        const metric = root.metricList.find(m => m.key === key) ?? root.metricList[0];
        const source = root.metricData(metric.key).curve ?? [];
        const out = [];
        let last = 0;
        for (let i = 0; i < source.length; i++) {
            const value = source[i];
            if (value !== null && value !== undefined)
                last = value;
            out.push(Math.max(0, Math.min(1, last / metric.scale)));
        }
        return out;
    }

    readonly property int curvePoints: root.metricData("cpu").curve?.length ?? 0

    // ── 格式化 ──────────────────────────────────────────────────────────────
    // 放在服务里而不是页面里：Repeater 的 delegate 引用页面根的 id 是不安全的
    // （见 SidebarLeftContent.qml 里缓存那段注释），而单例随便哪个 delegate 都能读。
    function percentText(value) {
        return (value === undefined || value === null) ? "--" : Math.round(value) + "%";
    }

    function tempText(value) {
        return (value === undefined || value === null) ? "--" : Math.round(value) + "°";
    }

    function wattsText(value) {
        return (value === undefined || value === null) ? "--" : value.toFixed(1) + " W";
    }

    function mbText(value) {
        if (value === undefined || value === null)
            return "--";
        return value >= 1024 ? (value / 1024).toFixed(1) + " GB" : Math.round(value) + " MB";
    }

    function gibText(value) {
        return (value === undefined || value === null) ? "--" : value.toFixed(1) + " G";
    }

    function whText(value) {
        return (value === undefined || value === null) ? "--" : value.toFixed(1) + " Wh";
    }

    function uptimeText(hours) {
        if (hours === undefined || hours === null)
            return "--";
        const total = Math.round(hours * 60);
        return Math.floor(total / 60) + "h " + (total % 60) + "m";
    }

    function clockText(mhz) {
        return (mhz === undefined || mhz === null) ? "--" : Math.round(mhz) + " MHz";
    }

    // 近 7 天（最新的在后）的平均 / 峰值柱状图用
    readonly property var last7History: root.historyDays.slice(0, 7).reverse()
    readonly property real historyCpuMax: Math.max(1, ...root.last7History.map(d => d.cpu_max ?? 0))

    function ingest(raw) {
        if (!raw || raw.trim().length === 0)
            return;
        let obj;
        try {
            obj = JSON.parse(raw);
        } catch (e) {
            return; // 半截文件：保留上次的值
        }
        if (!obj || typeof obj !== "object")
            return;
        root.summary = obj;
        root.loadedAtMs = Date.now();
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.tick++
    }

    FileView {
        id: summaryView
        path: root.enabled ? root.summaryFile : ""
        watchChanges: true
        printErrors: false // 采集器没跑时文件不存在是正常状态
        onFileChanged: reload()
        onLoaded: root.ingest(summaryView.text())
    }
}
