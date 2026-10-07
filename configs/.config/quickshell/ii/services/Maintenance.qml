pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * 系统维护信息（本地新增，非上游文件）。
 *
 * 上游 `services/Updates.qml` 只有一句 `checkupdates | wc -l`，而且**全 ii 没有任何
 * 界面显示它**（`ServicesConfig.qml` 里那段设置至今是注释掉的）。维护页要的东西更多
 * （AUR / 孤儿包 / 缓存 / 上次升级），所以另起一个服务，**不去改那个上游文件** ——
 * 上游同步时少一处冲突。
 *
 * ⚠ 这里**全是只读查询**：本服务不执行任何更新、删除、清理动作。页面上只把命令
 * 显示出来供复制，真要动系统由用户自己在终端敲（要提权、且不可逆，不该由 UI 代劳）。
 *
 * 本机实测耗时（2026-09-23，EndeavourOS）：checkupdates 0.6s / paru -Qua 4.3s /
 * pacman -Qtdq 0.9s / du -sh /var/cache/pacman/pkg 0.1s。
 * 最慢那条决定了节流：5 分钟。页面每次切回来都会调 refresh()，由这层拦住。
 */
Singleton {
    id: root

    readonly property int minInterval: 300 // 秒
    readonly property int orphanPreview: 8 // 孤儿包只列前几个，全列出来太长

    // ── 数据（-1 / 空串 = 还没查到）────────────────────────────────────
    property int repoUpdates: -1 // 官方仓库可更新数
    property int aurUpdates: -1 // AUR 可更新数（走 paru）
    property int orphanCount: -1
    property var orphanNames: []
    property string cacheSize: "" // 已经带单位，如 "31G"
    property string lastUpgrade: "" // "09-18 22:10"
    property int lastUpgradeDays: -1
    property int installedCount: -1
    property string kernel: ""
    property int flatpakApps: -1

    property double lastFetchAt: 0
    readonly property string lastChecked: root.lastFetchAt > 0
        ? Qt.formatDateTime(new Date(root.lastFetchAt), "HH:mm:ss") : ""

    // 任何一条还在跑 = 「检查中」
    readonly property bool loading: repoProc.running || aurProc.running || orphanProc.running
        || cacheProc.running || upgradeProc.running || kernelProc.running
        || installedProc.running || flatpakProc.running

    function refresh(force = false) {
        if (!force && Date.now() - root.lastFetchAt < root.minInterval * 1000) return;
        root.lastFetchAt = Date.now();
        repoProc.running = true;
        aurProc.running = true;
        orphanProc.running = true;
        cacheProc.running = true;
        upgradeProc.running = true;
        kernelProc.running = true;
        installedProc.running = true;
        flatpakProc.running = true;
    }

    // pacman.log 的行形如：
    //   [2026-09-18T22:10:29+0800] [PACMAN] starting full system upgrade
    // 时间戳就是本地时区，所以按本地时间构造 Date —— 别用 Date.parse，
    // 它不认 "+0800" 这种没冒号的时区写法（ISO 8601 要求 +08:00）。
    function parseUpgradeLine(line) {
        const m = line.match(/^\[(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/);
        if (!m) return;
        root.lastUpgrade = m[2] + "-" + m[3] + " " + m[4] + ":" + m[5];
        // 按「日历天」算，不按 24 小时：18 号晚上升级、23 号凌晨来看，
        // 时间差只有 4 天出头，但人会说「5 天前」。所以两边都取当天 0 点再相减。
        const then = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        root.lastUpgradeDays = Math.max(0, Math.round((today.getTime() - then.getTime()) / 86400000));
    }

    // ── 官方仓库 ───────────────────────────────────────────────────────
    // checkupdates 的退出码有语义：0 = 有更新、2 = 没有更新、其他 = 出错
    //（脚本结尾那个 `exit 2` 就是"没更新"分支）。所以用 pipefail 保住它的退出码，
    // 出错时**保留上次的值** —— 否则数据库被锁 / 断网会被显示成「0 个更新」。
    Process {
        id: repoProc
        command: ["bash", "-c", "set -o pipefail; checkupdates 2>/dev/null | wc -l"]
        property int lastExit: -1
        stdout: StdioCollector {
            id: repoOut
            onStreamFinished: repoProc.apply()
        }
        onExited: (exitCode, exitStatus) => {
            repoProc.lastExit = exitCode;
            repoProc.apply();
        }
        // stdout 收集完和 onExited 谁先谁后不保证，所以两边都调一次；
        // 退出码还没回来时（lastExit = -1）直接返回，不会误采信。
        function apply() {
            if (repoProc.lastExit !== 0 && repoProc.lastExit !== 2) return;
            const t = repoOut.text.trim();
            if (t.length === 0) return;
            const n = parseInt(t);
            if (!isNaN(n)) root.repoUpdates = n;
        }
    }

    // ── AUR ────────────────────────────────────────────────────────────
    // paru -Qua 列出可更新的 AUR 包，没更新就是空输出。
    // 这条**不**校验退出码：paru 查 AUR 要联网，失败时 stderr 已丢弃、stdout 也空，
    // 会被算成 0 —— 有意的取舍，宁可少一行提示也不要把判定逻辑搞复杂。
    Process {
        id: aurProc
        command: ["bash", "-c", "paru -Qua 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (!isNaN(n)) root.aurUpdates = n;
            }
        }
    }

    // ── 孤儿包 ─────────────────────────────────────────────────────────
    // pacman -Qtdq 没有孤儿包时退出码是 1、输出为空 —— 那不是错误，所以不看退出码。
    Process {
        id: orphanProc
        command: ["bash", "-c", "pacman -Qtdq 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                root.orphanCount = lines.length;
                root.orphanNames = lines.slice(0, root.orphanPreview);
            }
        }
    }

    // ── 包缓存 ─────────────────────────────────────────────────────────
    Process {
        id: cacheProc
        command: ["bash", "-c", "du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t.length > 0) root.cacheSize = t;
            }
        }
    }

    // ── 上次系统升级 ───────────────────────────────────────────────────
    Process {
        id: upgradeProc
        command: ["bash", "-c", "grep -a 'starting full system upgrade' /var/log/pacman.log 2>/dev/null | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: root.parseUpgradeLine(text)
        }
    }

    // ── 系统信息 ───────────────────────────────────────────────────────
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t.length > 0) root.kernel = t;
            }
        }
    }

    Process {
        id: installedProc
        command: ["bash", "-c", "pacman -Qq | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (!isNaN(n)) root.installedCount = n;
            }
        }
    }

    // flatpak 没装、或装了但一个 app 都没有，这里都是 0 → 页面上那一行不显示
    Process {
        id: flatpakProc
        command: ["bash", "-c", "flatpak list --app 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (!isNaN(n)) root.flatpakApps = n;
            }
        }
    }
}
