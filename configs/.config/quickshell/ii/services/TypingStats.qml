pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common
import qs.modules.common.functions

// 打字统计（本地新增，非上游）。
//
// 数据源是 fcitx5 词库目录下那个几 KB 的小文件（由用户的
// rime_counter_rs / words_counter.py 落盘）：
//
//   { "per_day":     {"2025-09-27": 6896, …},   // 355 天，按本地日期
//     "last_offsets": {"endeavour_os_main": 38027541},
//     "updated_at":  "2026-09-22 01:42:00" }
//
// 只有几 KB，所以直接 FileView 读、在 QML 里聚合；38 MB 的
// words_input.csv 明细留给阶段 2 的 ii-stats daemon 增量解析。
//
// 聚合全在派生属性里做：per_day 一换（ingest 里整体赋值，不是改字段），
// 下面所有数字跟着重算。
//
// dayStamp 单独用 Timer 每 30 秒对一次表，且**只在跨天时**才真的变
// （QML 的同名赋值不会发通知）——这样跨零点「今日」会自动归零，
// 而 371 个格子的热力图不会每分钟重建一次。
Singleton {
    id: root

    readonly property bool enabled: Config?.options?.sidebar?.typingStats?.enable ?? false
    // 留空则用默认路径；也可以在设置里指到别处
    readonly property string historyFile: {
        const configured = Config?.options?.sidebar?.typingStats?.historyFile ?? "";
        if (configured.length > 0)
            return configured;
        return FileUtils.trimFileProtocol(`${Directories.home}/.local/share/fcitx5/rime/py_wordscounter/words_count_history.json`);
    }

    // ── 原始数据 ────────────────────────────────────────────────────────────
    property var perDay: ({})       // {"YYYY-MM-DD": int}
    property string updatedAt: ""   // 文件里的 updated_at
    property string dayStamp: ""    // "今天"，跨天才变

    readonly property bool available: Object.keys(root.perDay).length > 0
    readonly property string todayKey: root.dayStamp

    // ── 日期工具 ────────────────────────────────────────────────────────────
    function dateKey(d) {
        const m = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return `${d.getFullYear()}-${m}-${day}`;
    }

    function parseKey(key) {
        const parts = key.split("-");
        return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
    }

    function shiftDays(d, n) {
        const x = new Date(d);
        x.setDate(x.getDate() + n);
        return x;
    }

    function countFor(key) {
        return root.perDay[key] ?? 0;
    }

    // 千分位。不用 toLocaleString：不同 locale 的分隔符不一样，中文界面就要逗号
    function groupDigits(n) {
        return String(Math.round(n ?? 0)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    // 色阶：0 是空格子，1..4 由浅到深。留在服务层是为了让页面里的
    // delegate 能只写 TypingStats.levelColor(...) —— delegate 引用页面根的
    // 任何 id 都不安全（见文件末尾的说明）。
    function levelColor(level) {
        switch (level) {
        case 0:
            return Appearance.colors.colLayer1Hover;
        case 1:
            return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.72);
        case 2:
            return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.48);
        case 3:
            return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.24);
        default:
            return Appearance.colors.colPrimary;
        }
    }

    // ── 聚合数字 ────────────────────────────────────────────────────────────
    readonly property int todayCount: root.countFor(root.todayKey)

    readonly property int totalCount: {
        let sum = 0;
        for (const k in root.perDay)
            sum += root.perDay[k];
        return sum;
    }

    readonly property int activeDays: {
        let n = 0;
        for (const k in root.perDay)
            if (root.perDay[k] > 0)
                n++;
        return n;
    }

    readonly property int averagePerActiveDay: root.activeDays > 0 ? Math.round(root.totalCount / root.activeDays) : 0

    // 近 7 天（含今天）
    readonly property var last7Days: {
        const today = root.parseKey(root.todayKey);
        const out = [];
        const names = ["日", "一", "二", "三", "四", "五", "六"];
        for (let i = 6; i >= 0; i--) {
            const date = root.shiftDays(today, -i);
            const key = root.dateKey(date);
            // label 只给星期几的字；「今天」由页面自己替换（服务层不碰翻译）
            out.push({
                key: key,
                count: root.countFor(key),
                label: names[date.getDay()],
                isToday: i === 0
            });
        }
        return out;
    }

    readonly property int last7Count: root.last7Days.reduce((a, d) => a + d.count, 0)
    readonly property int last7Max: Math.max(1, ...root.last7Days.map(d => d.count))

    readonly property int weekCount: root.last7Count // 「本周」按滚动 7 天算，比自然周稳定

    readonly property int monthCount: {
        const ym = root.todayKey.slice(0, 7);
        let sum = 0;
        for (const k in root.perDay)
            if (k.startsWith(ym))
                sum += root.perDay[k];
        return sum;
    }

    readonly property int lastMonthCount: {
        const today = root.parseKey(root.todayKey);
        const d = new Date(today.getFullYear(), today.getMonth() - 1, 1);
        const ym = root.dateKey(d).slice(0, 7);
        let sum = 0;
        for (const k in root.perDay)
            if (k.startsWith(ym))
                sum += root.perDay[k];
        return sum;
    }

    readonly property var bestDay: {
        let bk = "";
        let bc = 0;
        for (const k in root.perDay) {
            const v = root.perDay[k];
            if (v > bc) {
                bc = v;
                bk = k;
            }
        }
        return { key: bk, count: bc };
    }

    // 连续打卡：今天还没打字不算断（还没到零点），所以今天为 0 时从昨天起数
    readonly property int currentStreak: {
        let cursor = root.parseKey(root.todayKey);
        if (root.countFor(root.dateKey(cursor)) === 0)
            cursor = root.shiftDays(cursor, -1);
        let n = 0;
        while (n < 4000 && root.countFor(root.dateKey(cursor)) > 0) {
            n++;
            cursor = root.shiftDays(cursor, -1);
        }
        return n;
    }

    readonly property int longestStreak: {
        const keys = Object.keys(root.perDay).filter(k => root.perDay[k] > 0).sort();
        let best = 0;
        let cur = 0;
        let prev = null;
        for (const k of keys) {
            const d = root.parseKey(k);
            cur = (prev !== null && Math.round((d - prev) / 86400000) === 1) ? cur + 1 : 1;
            prev = d;
            if (cur > best)
                best = cur;
        }
        return best;
    }

    // 星期分布（只统计有记录的日子，不把没开机的日子算成 0）
    readonly property var weekdayAverages: {
        const sum = [0, 0, 0, 0, 0, 0, 0];
        const cnt = [0, 0, 0, 0, 0, 0, 0];
        for (const k in root.perDay) {
            const d = root.parseKey(k);
            const v = root.perDay[k];
            sum[(d.getDay() + 6) % 7] += v; // 0 = 周一
            cnt[(d.getDay() + 6) % 7]++;
        }
        const names = ["一", "二", "三", "四", "五", "六", "日"];
        const out = [];
        for (let i = 0; i < 7; i++)
            out.push({ label: names[i], avg: cnt[i] > 0 ? Math.round(sum[i] / cnt[i]) : 0 });
        return out;
    }

    readonly property int weekdayAvgMax: Math.max(1, ...root.weekdayAverages.map(d => d.avg))

    // ── 热力图（53 周 × 7 天，周一开头，最后一列是本周）────────────────────
    // 色阶取有记录日子的四分位，而不是硬编码阈值 —— 用户作息变了色阶也跟着变
    readonly property var levelThresholds: {
        const vals = [];
        for (const k in root.perDay)
            if (root.perDay[k] > 0)
                vals.push(root.perDay[k]);
        if (vals.length === 0)
            return [0, 0, 0];
        vals.sort((a, b) => a - b);
        const q = p => vals[Math.min(vals.length - 1, Math.floor(vals.length * p))];
        return [q(0.25), q(0.5), q(0.75)];
    }

    function levelFor(count) {
        if (count <= 0)
            return 0;
        const t = root.levelThresholds;
        if (count <= t[0])
            return 1;
        if (count <= t[1])
            return 2;
        if (count <= t[2])
            return 3;
        return 4;
    }

    // ── 卡片内几何 ──────────────────────────────────────────────────────────
    // 格子/柱子的尺寸要按侧栏宽度算。页面把「卡片内容区有多宽」推过来，所有
    // x/y/宽高都由这里算进模型里 —— 一来页面里的 delegate 一个页面根 id 都不用碰，
    // 二来 24 根柱子、371 个格子各自共享同一份算术。
    //
    // 为什么不交给 RowLayout 的 fillWidth 等分：实测 Qt 给 fillWidth 的项分剩余
    // 空间时看 implicitWidth（不是纯等分）。24 列里只有 4 列带轴标签、其余标签是
    // 空串（implicitWidth 0）时，带标签那 4 列能宽出十几倍 —— 最小复现里 70px vs 5px，
    // 柱状图画出来像「几根粗柱子夹一堆竖线」。所以坐标自己算，不碰 Layout。
    property real cardContentWidth: 0
    readonly property int heatmapGap: 2
    readonly property int heatmapCellSize: {
        const available = root.cardContentWidth;
        return Math.max(4, Math.min(14, Math.floor((available - root.heatmapGap * (root.heatmapColumns - 1)) / root.heatmapColumns)));
    }
    readonly property int heatmapStep: root.heatmapCellSize + root.heatmapGap

    // 悬停中的那一格（页面上的 MouseArea 写、标题栏读）
    property var hoveredCell: null

    readonly property int heatmapColumns: 53
    readonly property string heatmapFirstKey: root.heatmapCells.length > 0 ? root.heatmapCells[0].key : ""
    readonly property string heatmapLastKey: root.heatmapCells.length > 0 ? root.heatmapCells[root.heatmapCells.length - 1].key : ""

    // 扁平数组（列优先，index = col * 7 + row）—— 嵌套 Repeater 要跨层取
    // modelData，扁平化之后一个 Repeater 加 x/y 就够了。
    // 坐标/尺寸/圆角一并预计算进元素里（见 heatmapAvailableWidth 的说明）。
    readonly property var heatmapCells: {
        const today = root.parseKey(root.todayKey);
        const todayMondayOffset = (today.getDay() + 6) % 7;
        const thisWeekStart = root.shiftDays(today, -todayMondayOffset);
        const firstStart = root.shiftDays(thisWeekStart, -52 * 7);

        const size = root.heatmapCellSize;
        const step = root.heatmapStep;
        const cells = [];
        for (let col = 0; col < 53; col++) {
            for (let row = 0; row < 7; row++) {
                const date = root.shiftDays(firstStart, col * 7 + row);
                const key = root.dateKey(date);
                const count = root.countFor(key);
                cells.push({
                    key: key,
                    col: col,
                    row: row,
                    count: count,
                    level: root.levelFor(count),
                    future: date > today,
                    isToday: key === root.todayKey,
                    x: col * step,
                    y: row * step,
                    size: size,
                    radius: Math.min(2, Math.floor(size / 3))
                });
            }
        }
        return cells;
    }

    // 数据文件里最后一天（可能是昨天，如果今天还没打字）
    readonly property string lastActiveKey: {
        const keys = Object.keys(root.perDay).filter(k => root.perDay[k] > 0);
        return keys.length > 0 ? keys.sort()[keys.length - 1] : "";
    }

    // ── 打字明细（由 ii-stats-daemon 从 38 MB 的 words_input.csv 增量解析）──
    // 和上面的 per_day 是两条独立的数据流，别混：
    //   per_day             ← words_count_history.json（用户的 rime_counter_rs 落的）
    //   typing_details.json ← daemon 解析 CSV 明细（小时分布 / 高频词 / 段数）
    // 前者只有「每天多少字」，后者才有分布与词频。两个进程各写各的，所以
    // 「今日」的明细可能比 per_day 少一两条 —— 页面上数字以 per_day 为准，
    // 明细只拿来画分布。
    readonly property bool showDetails: Config?.options?.sidebar?.typingStats?.showDetails ?? false
    readonly property string detailsFile: {
        const configured = Config?.options?.sidebar?.typingStats?.detailsFile ?? "";
        if (configured.length > 0)
            return configured;
        return FileUtils.trimFileProtocol(`${Directories.home}/.local/share/ii-stats/typing_details.json`);
    }

    property var details: ({}) // 同样整体赋值，派生属性靠这个通知重算
    readonly property bool detailsAvailable: root.details.all !== undefined
    readonly property var detailsAll: root.details.all ?? ({})
    readonly property var detailsToday: root.details.today ?? ({})
    readonly property int detailsChars: root.details.chars ?? 0
    readonly property int detailsRows: root.details.rows ?? 0
    readonly property string detailsUpdatedAt: root.details.updated_at ?? ""

    readonly property var topWords: root.detailsAll.words ?? []
    readonly property var topPinyins: root.detailsAll.pinyins ?? []

    // 「每小时输入」的几何（同热力图：坐标由服务算，delegate 只管画）
    readonly property int hourGap: 2
    readonly property int hourBarHeight: 54
    readonly property int hourLabelHeight: 14
    readonly property real hourColumnWidth: Math.max(2, (root.cardContentWidth - root.hourGap * 23) / 24)

    // 「每小时输入」的柱状模型（mode = "today" / "all"）。
    // 坐标、高度、要不要写轴标签都在这里定好，delegate 只管把柱子和字画出来。
    function hourDistribution(mode) {
        const source = (mode === "today" ? root.detailsToday.by_hour : root.detailsAll.by_hour) ?? [];
        if (source.length === 0)
            return [];
        const max = Math.max(1, ...source);
        const out = [];
        for (let h = 0; h < 24; h++) {
            const count = source[h] ?? 0;
            out.push({
                "hour": h,
                "count": count,
                "ratio": count / max,
                "x": h * (root.hourColumnWidth + root.hourGap),
                "width": root.hourColumnWidth,
                "barHeight": count > 0 ? Math.max(2, Math.round(root.hourBarHeight * count / max)) : 1,
                "label": h % 6 === 0 ? String(h).padStart(2, "0") : "" // 只写 00/06/12/18，24 个标签会挤成一团
            });
        }
        return out;
    }

    // 高频词的排行模型（前 8 条，ratio 按榜首归一）
    function topEntries(mode) {
        const source = mode === "pinyin" ? root.topPinyins : root.topWords;
        if (source.length === 0)
            return [];
        const top = source.slice(0, 8);
        const max = Math.max(1, ...top.map(e => e.n ?? 0));
        return top.map(e => ({
                    "w": e.w ?? "",
                    "n": e.n ?? 0,
                    "ratio": (e.n ?? 0) / max
                }));
    }

    // ── 读取 ────────────────────────────────────────────────────────────────
    function ingest(raw) {
        if (!raw || raw.trim().length === 0)
            return;

        let obj;
        try {
            obj = JSON.parse(raw);
        } catch (e) {
            // 读到写入过程中的半截文件。不补重读：写完还会再触发一次
            // fileChanged。直接返回，界面上已有的值也不会被刷成空的。
            return;
        }

        const pd = obj.per_day;
        if (!pd || typeof pd !== "object")
            return;

        root.perDay = pd; // 整体赋值 —— 派生属性靠这个通知重算
        root.updatedAt = obj.updated_at ?? "";
    }

    Component.onCompleted: root.dayStamp = root.dateKey(new Date())

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.dayStamp = root.dateKey(new Date())
    }

    function ingestDetails(raw) {
        if (!raw || raw.trim().length === 0)
            return;

        let obj;
        try {
            obj = JSON.parse(raw);
        } catch (e) {
            return; // 写入过程中的半截文件，保留上次的值
        }
        if (!obj || typeof obj.all !== "object")
            return;

        root.details = obj;
    }

    FileView {
        id: historyFileView
        path: root.enabled ? root.historyFile : ""
        watchChanges: true
        printErrors: false // 文件不存在是正常状态（词库没用过 / 路径不对），别刷日志
        onFileChanged: reload()
        onLoaded: root.ingest(historyFileView.text())
    }

    FileView {
        id: detailsFileView
        // 关掉明细开关就连文件都不读（页面上的两张卡也跟着消失）
        path: (root.enabled && root.showDetails) ? root.detailsFile : ""
        watchChanges: true
        printErrors: false // daemon 没跑时文件不存在是正常状态
        onFileChanged: reload()
        onLoaded: root.ingestDetails(detailsFileView.text())
    }
}
