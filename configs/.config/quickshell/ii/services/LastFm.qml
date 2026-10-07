pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell

/**
 * last.fm 历史统计（本地新增，非上游文件）。
 *
 * 职责划分（2026-09-22 定的多源方案，别把两件事混起来）：
 *   · **正在播的那首** → MprisController（本地 MPRIS：实时、带进度/时长/封面）
 *   · **历史统计**     → 本服务（user.getrecenttracks / user.getTopArtists）
 *
 * last.fm 只收「已经 scrobble 完」的曲目 —— 正在播的那条虽然会出现在
 * recenttracks 里，但**没有 date 字段**，也不进历史。所以它做不了实时在播，
 * 别拿它当播放器状态用（本服务只用它给「在播」做兜底标注）。
 *
 * 今日统计只做「曲数 / Top 艺人 / Top 专辑 / 重复播放」：
 * last.fm 的接口**不返回单曲时长**，逐首查 track.getInfo 又太贵（每首一次请求），
 * 所以这里没有「今天听了几小时」—— 那个只能靠 MPRIS 本地估算。
 */
Singleton {
    id: root

    // ── 配置 ───────────────────────────────────────────────────────────
    // Config 是异步加载的（Config.ready 之后才有值）：ready 之前给个空壳，
    // 免得下面的绑定在 options 还没填好时求值、拿到 undefined 刷一屏报错。
    readonly property var cfg: Config.ready ? Config.options.stats.lastFm : ({})
    readonly property bool configured: ((root.cfg.apiKey ?? "").length > 0) && ((root.cfg.username ?? "").length > 0)
    readonly property bool enabled: root.configured && (root.cfg.enable ?? true)
    readonly property int minInterval: 90 // 秒 —— 设置里填更小也按这个兜底（last.fm 有速率限制）

    // ── 状态 ───────────────────────────────────────────────────────────
    property bool loading: false
    property string errorMessage: ""
    property string updatedAt: "" // "HH:mm:ss"
    property bool truncated: false // 今日条目超过翻页上限，只统计了前 maxPages*pageSize 条

    // ── 今日（本地时区 0 点起）─────────────────────────────────────────
    property var recentTracks: [] // 时间倒序 [{artist,title,album,cover,uts,time,isNow}]
    property int todayCount: 0 // 不含「正在播」那条
    property var topArtists: [] // [{name,count,cover}]
    property var topAlbums: [] // [{name,artist,count,cover}]
    property var repeats: [] // [{artist,title,count}] 只留 count >= 2
    property var albumWall: [] // [{album,artist,cover}] 按首次出现顺序去重

    // ── 近 7 天 ────────────────────────────────────────────────────────
    property var weekArtists: [] // [{name,count}]
    property int weekTotal: 0

    readonly property int pageSize: 200
    readonly property int maxPages: 5 // 1000 条/天封顶，正常人听不到
    // last.fm 没有封面时返回的是这张固定占位图，别把它当封面显示
    readonly property string placeholderCoverHash: "2a96cbd8b46e442fc41c2b86b821562f"

    property double lastFetchAt: 0
    property var _accum: []
    property bool _weekLoading: false

    // ── 对外入口 ───────────────────────────────────────────────────────
    // 配置就绪（或用户刚把 key 填好）时自己补一刀。
    // 必须这么做：页面是在 Component.onCompleted 里调 refresh() 的，那一刻
    // Config 往往还没加载完 → enabled=false → 请求被静默 return 掉，
    // 之后再没人触发（实测 harness 里日志一声不吭就是这原因）。
    onEnabledChanged: {
        if (root.enabled)
            root.refresh();
    }

    // 页面/组件在「显示出来」和「切换进来」时调一次即可，节流在这里兜底，
    // 调用方不用自己判断该不该刷（右栏面板是常驻加载的，必须靠这层拦住）。
    function refresh(force = false) {
        if (!root.enabled || root.loading) return;
        const intervalMs = Math.max(root.minInterval, root.cfg.refreshInterval ?? 120) * 1000;
        if (!force && Date.now() - root.lastFetchAt < intervalMs) return;
        root.loading = true;
        root.errorMessage = "";
        root._accum = [];
        root.fetchTodayPage(1);
        root.fetchWeek();
    }

    function todayStartUnix() {
        const d = new Date();
        d.setHours(0, 0, 0, 0);
        return Math.floor(d.getTime() / 1000);
    }

    function apiUrl(extra) {
        return "https://ws.audioscrobbler.com/2.0/?api_key=" + encodeURIComponent(root.cfg.apiKey)
            + "&user=" + encodeURIComponent(root.cfg.username)
            + "&format=json" + extra;
    }

    // ── 今日：逐页取（last.fm 单页最多 200 条）─────────────────────────
    function fetchTodayPage(page) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.apiUrl("&method=user.getrecenttracks&limit=" + root.pageSize
                                    + "&from=" + root.todayStartUnix() + "&page=" + page));
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 200) {
                root.finishToday("HTTP " + xhr.status);
                return;
            }
            let data;
            try {
                data = JSON.parse(xhr.responseText);
            } catch (e) {
                root.finishToday("响应解析失败：" + e);
                return;
            }
            if (data.error) {
                root.finishToday("last.fm 报错 " + data.error + "：" + (data.message ?? ""));
                return;
            }

            const recent = data.recenttracks ?? {};
            let list = recent.track ?? [];
            // 只有一条时 last.fm 返回的是对象而不是数组 —— 这坑很常见
            if (!Array.isArray(list)) list = [list];
            root._accum = root._accum.concat(list);

            const totalPages = parseInt(recent["@attr"]?.totalPages ?? 1);
            if (page < totalPages && page < root.maxPages) {
                root.fetchTodayPage(page + 1);
            } else {
                root.truncated = totalPages > root.maxPages;
                root.finishToday("");
            }
        };
        xhr.send();
    }

    function finishToday(err) {
        root.loading = false;
        root.lastFetchAt = Date.now();
        if (err.length > 0) {
            root.errorMessage = err;
            console.log("[LastFm] 拉取失败：" + err);
            return;
        }

        const artistMap = {};
        const albumMap = {};
        const trackMap = {};
        const wallSeen = {};
        const tracks = [];
        const wall = [];
        let counted = 0;

        for (const t of root._accum) {
            // last.fm 用 ";" 分隔多艺人（合作曲很常见）。不拆的话
            // "Culprate; Siskiyou" 会自成一档，Top 榜会被这种长名字占满。
            // 只拆 ";" —— "&" 不能拆，"Simon & Garfunkel" 那种是一个艺人名。
            const artists = (t.artist?.["#text"] ?? "").split(";").map(s => s.trim()).filter(s => s.length > 0);
            const artist = artists.join(" & "); // 显示用：时间线里保持一行
            const title = (t.name ?? "").trim();
            const album = (t.album?.["#text"] ?? "").trim();
            const cover = root.pickCover(t.image);
            const uts = parseInt(t.date?.uts ?? 0);
            const isNow = (t["@attr"]?.nowplaying === "true") || uts === 0;
            if (!isNow) counted++;

            tracks.push({
                "artist": artist,
                "title": title,
                "album": album,
                "cover": cover,
                "uts": uts,
                "time": isNow ? "" : root.hhmm(uts),
                "isNow": isNow
            });

            for (const a of artists) { // 合作曲：每个艺人都记一笔
                if (!artistMap[a]) artistMap[a] = { "name": a, "count": 0, "cover": cover };
                artistMap[a].count++;
                if (artistMap[a].cover.length === 0) artistMap[a].cover = cover;
            }

            const albumKey = album.length > 0 ? album + "␟" + artist : "␟" + artist; // ␟ = 占位分隔，避免 "A"+"B" 与 "AB"+"" 撞键
            if (!albumMap[albumKey]) albumMap[albumKey] = { "name": album, "artist": artist, "count": 0, "cover": cover };
            albumMap[albumKey].count++;
            if (albumMap[albumKey].cover.length === 0) albumMap[albumKey].cover = cover;

            const trackKey = artist + "␟" + title;
            trackMap[trackKey] = (trackMap[trackKey] ?? 0) + 1;

            if (album.length > 0 && !wallSeen[albumKey] && cover.length > 0) {
                wallSeen[albumKey] = true;
                wall.push({ "album": album, "artist": artist, "cover": cover });
            }
        }

        const byCount = (a, b) => b.count - a.count;
        root.recentTracks = tracks;
        root.todayCount = counted;
        root.albumWall = wall;
        root.topArtists = Object.values(artistMap).sort(byCount);
        root.topAlbums = Object.values(albumMap).sort(byCount);
        root.repeats = Object.keys(trackMap)
            .filter(k => trackMap[k] >= 2)
            .map(k => {
                const parts = k.split("␟");
                return { "artist": parts[0], "title": parts[1], "count": trackMap[k] };
            })
            .sort(byCount)
            .slice(0, 8);
        root.updatedAt = Qt.formatDateTime(new Date(), "HH:mm:ss");
        root._accum = [];
        console.log("[LastFm] 今日 " + root.todayCount + " 首 / " + root.topArtists.length + " 位艺人 / "
                    + root.topAlbums.length + " 张专辑；榜首 " + (root.topArtists[0]?.name ?? "-"));
    }

    // ── 近 7 天 Top 艺人 ───────────────────────────────────────────────
    function fetchWeek() {
        if (root._weekLoading) return;
        root._weekLoading = true;
        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.apiUrl("&method=user.getTopArtists&period=7day&limit=10"));
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root._weekLoading = false;
            if (xhr.status !== 200) return; // 周榜是附加信息，失败就不显示，不覆盖今日那块的状态
            try {
                const data = JSON.parse(xhr.responseText);
                if (data.error) return;
                let artists = data.topartists?.artist ?? [];
                if (!Array.isArray(artists)) artists = [artists];
                root.weekTotal = parseInt(data.topartists?.["@attr"]?.total ?? 0);
                root.weekArtists = artists.map(a => ({
                    "name": a.name ?? "",
                    "count": parseInt(a.playcount ?? 0)
                }));
                console.log("[LastFm] 近 7 天 " + root.weekTotal + " 首；榜首 " + (root.weekArtists[0]?.name ?? "-"));
            } catch (e) {
                // 静默：周榜坏了不影响今日
            }
        };
        xhr.send();
    }

    // ── 小工具 ─────────────────────────────────────────────────────────
    // last.fm 的 image 是个 [{size, #text}] 数组，从大到小挑第一个非占位图
    function pickCover(images) {
        if (!images) return "";
        for (const size of ["extralarge", "large", "medium", "small"]) {
            const hit = images.find(i => i.size === size);
            const url = hit?.["#text"] ?? "";
            if (url.length > 0 && url.indexOf(root.placeholderCoverHash) === -1) return url;
        }
        return "";
    }

    function hhmm(uts) {
        const d = new Date(uts * 1000);
        return String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0");
    }

    // Top 艺人/专辑里前面几名占多少 —— 页面用来说明「今天听得多集中」
    function shareOf(list, n) {
        if (!list || list.length === 0) return 0;
        let total = 0;
        for (const item of list) total += item.count;
        if (total === 0) return 0;
        let top = 0;
        for (let i = 0; i < Math.min(n, list.length); i++) top += list[i].count;
        return top / total;
    }
}
