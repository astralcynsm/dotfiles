import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

/**
 * Obsidian 库 → GitHub：提交弹框 / 速记弹框。
 *
 * 所有 git 逻辑都在 ~/.local/bin/vault-commit 里（可在终端单独跑、单独测），
 * 这里只负责：识别当前是哪个库 → 显示变更摘要 → 收 commit message → 显示结果。
 *
 * 入口：
 *   · 键位 → hl.dsp.global("quickshell:vaultCommitOpen" / "quickshell:vaultCaptureOpen")
 *   · 或   → qs -c ii ipc call vaultCommit commit / capture
 *
 * 骨架照抄 cheatsheet/Cheatsheet.qml，两处刻意的不同：
 *   1. Process / IpcHandler / GlobalShortcut 挂在 Scope 上，**不在** PanelWindow 里 ——
 *      否则按 Esc 关窗会把正在飞的 git push 一起带走。
 *   2. 不用 GlobalFocusGrab.addDismissable（别的窗口一拿焦点面板就自己关，
 *      见 memory: quickshell-overview-focus-and-keyboard），改用自绘 scrim + 点外部关闭。
 *      也没有退场动画 —— 避开 memory: quickshell-qml-animation-traps 里的续命竞态。
 */
Scope {
    id: root

    readonly property string script: `${Directories.home}/.local/bin/vault-commit`

    // ── 面板状态 ────────────────────────────────────────────────────────
    property bool panelOpen: false
    property string mode: "commit"    // commit | capture
    property string phase: "idle"     // idle|detecting|loading|editing|picking|busy|clean|done|error
    readonly property bool busy: root.phase === "busy"

    // ── 「顺手同步」：干净库按 G 也走一遍 apply（脚本会拉另一台机器推的提交）──
    property string applyMsg: ""      // applyProc 用的 message（同步路径没有输入框可读）
    property bool syncOnly: false     // 本次 apply 是同步而非提交（决定结果怎么展示）
    property string cleanText: ""     // clean 态的提示文字（同步结果写在这）

    // ── 圆角：跟预设走，但设下限 ─────────────────────────────────────────
    // 方角预设把 normal 缩到 ≈5px（当前 scale≈0.28），弹框第一眼像直角（用户反馈）；
    // 预设本来就圆（large ≥ 16）时则完全跟随，不跟外观参数化打架。
    readonly property int cardRadius: Math.max(Appearance.rounding.large, 16)
    readonly property int innerRadius: Math.max(Appearance.rounding.normal, 10)

    // ── 当前库 ──────────────────────────────────────────────────────────
    property string vaultKey: ""
    property string vaultName: ""
    property string vaultLabel: ""

    // ── 变更摘要（vault-commit status 的返回）────────────────────────────
    property var status: null
    // 全部用三元判空：status 为 null 时 QML 里访问 .files 会抛异常
    readonly property var fileList: (root.status && root.status.files) ? root.status.files : []
    readonly property int fileCount: (root.status && root.status.count) ? root.status.count : 0
    readonly property int insCount: (root.status && root.status.insertions) ? root.status.insertions : 0
    readonly property int delCount: (root.status && root.status.deletions) ? root.status.deletions : 0
    readonly property int aheadCount: (root.status && root.status.ahead) ? root.status.ahead : 0
    readonly property int shownFiles: Math.min(root.fileList.length, 8)
    readonly property int hiddenFiles: root.fileList.length - root.shownFiles

    // ── 全部库（配了多个时才显示「写到哪个库」的切换行）──────────────────
    property var vaults: []

    // ── 识别不到库时的候选 ──────────────────────────────────────────────
    property var candidates: []
    readonly property var candidateItems: {
        const out = [];
        for (let i = 0; i < root.candidates.length; i++)
            out.push(`${root.candidates[i].label} · ${root.candidates[i].name}`);
        return out;
    }

    // ── 输入与提示 ──────────────────────────────────────────────────────
    property string inputText: ""
    property string prefixText: ""    // 速记模式的日期前缀，用来判断「用户一个字都没写」
    property string errorText: ""
    property string okText: ""

    // ══ 打开 / 关闭 ════════════════════════════════════════════════════
    // busy 时按快捷键：不静默吞掉，把面板摆出来让人看见「还有活没干完」。
    // （2026-10-11 事故：capture 子进程挂死 → busy 永久为真 → 所有快捷键无声失灵，
    //   连点 X 关窗也救不回来——close() 里的 !busy 判断把 phase 也一并锁死了）
    function openCommit() {
        if (root.busy) { root.panelOpen = true; return; }
        root.mode = "commit";
        root.openAndDetect();
    }

    function openCapture() {
        if (root.busy) { root.panelOpen = true; return; }
        root.mode = "capture";
        root.openAndDetect();
    }

    function openAndDetect() {
        root.inputText = "";
        root.prefixText = "";
        root.errorText = "";
        root.okText = "";
        root.applyMsg = "";
        root.syncOnly = false;
        root.cleanText = "";
        root.status = null;
        root.candidates = [];
        root.vaults = [];
        root.vaultKey = "";
        root.vaultName = "";
        root.vaultLabel = "";
        root.phase = "detecting";
        root.panelOpen = true;
        listProc.running = true;
        detectProc.running = true;
    }

    function close() {
        root.panelOpen = false;
        if (!root.busy) root.phase = "idle";
    }

    // ══ 工具 ═══════════════════════════════════════════════════════════
    // 脚本约定：任何情况都往 stdout 打一行 JSON，ok:false 时退出码通常仍是 0
    // → 一律判 ok 字段，不判退出码
    function parseJson(text, fallbackError) {
        const t = (text === undefined || text === null) ? "" : `${text}`.trim();
        if (t === "") return { ok: false, error: fallbackError };
        try {
            return JSON.parse(t);
        } catch (e) {
            return { ok: false, error: `${fallbackError}（输出不是 JSON：${t.substring(0, 120)}）` };
        }
    }

    function statusColor(s) {
        if (s.indexOf("D") >= 0) return Appearance.colors.colError;
        if (s.indexOf("A") >= 0) return Appearance.m3colors.m3tertiary;
        return Appearance.colors.colPrimary;
    }

    // ══ 各阶段的处理 ════════════════════════════════════════════════════
    function onDetected(text) {
        const r = root.parseJson(text, Translation.tr("vault-commit detect returned nothing (is the script executable?)"));
        if (r.ok) {
            root.adoptVault(r.key, r.name, r.label);
            return;
        }
        if (r.candidates && r.candidates.length > 0) {
            root.candidates = r.candidates;
            root.phase = "picking";
            return;
        }
        root.errorText = r.error || Translation.tr("Unknown error");
        root.phase = "error";
    }

    function adoptVault(key, name, label) {
        root.vaultKey = key;
        root.vaultName = name;
        root.vaultLabel = label;
        if (root.mode === "capture") {
            root.phase = "loading";
            prefixProc.running = true;
        } else {
            root.phase = "loading";
            statusProc.running = true;
        }
    }

    function onList(text) {
        // 拿不到就算了，静默：切换行不出现而已，主流程照走
        const r = root.parseJson(text, "");
        if (r.ok && r.vaults && r.vaults.length > 0) root.vaults = r.vaults;
    }

    // 换目标库。
    // · 速记：只换目标，已写的内容原样留着（笔记标题跟写到哪个库无关）
    // · 提交：重拉新库的变更摘要，已写的 message 清掉（那条消息是给旧库写的）
    function switchVault(key) {
        if (root.busy || root.phase === "loading" || key === root.vaultKey) return;
        for (let i = 0; i < root.vaults.length; i++) {
            const v = root.vaults[i];
            if (v.key !== key) continue;
            root.vaultKey = v.key;
            root.vaultName = v.name;
            root.vaultLabel = v.label;
            root.errorText = "";
            if (root.mode === "commit") {
                root.status = null;
                root.inputText = "";
                root.phase = "loading";
                statusProc.running = true;
            }
            return;
        }
    }

    function onTitlePrefix(text) {
        root.prefixText = `${text === undefined || text === null ? "" : text}`.replace(/\n+$/, "");
        root.inputText = root.prefixText;
        root.phase = "editing";
    }

    function onStatus(text) {
        const r = root.parseJson(text, Translation.tr("vault-commit status returned nothing"));
        if (!r.ok) {
            root.errorText = r.error || Translation.tr("Unknown error");
            root.phase = "error";
            return;
        }
        root.status = r;
        const ahead = r.ahead ? r.ahead : 0;
        if (r.clean && ahead === 0) {
            // 没改动 → 不再只报「没有需要提交的改动」，顺手同步一次远端。
            // 双机并用（Arch 晚 / Fedora 白天）：另一台昨晚推的，这里一按就下来。
            root.syncOnly = true;
            root.applyMsg = "（同步）";
            root.phase = "loading";
            applyProc.running = true;
        } else {
            root.inputText = "";
            root.phase = "editing";
        }
    }

    function submit() {
        if (root.busy || root.phase !== "editing") return;
        const text = root.inputText.replace(/[ \t]+$/, "");
        if (text === "") {
            root.errorText = root.mode === "capture"
                ? Translation.tr("Note title cannot be empty")
                : Translation.tr("Commit message cannot be empty");
            return;
        }
        // 速记模式下，用户只留着预填的日期前缀没写内容 → 拒绝（文件名会变成光秃秃一个日期）
        if (root.mode === "capture" && text === root.prefixText.replace(/[ \t]+$/, "")) {
            root.errorText = Translation.tr("Add a title after the date");
            return;
        }
        root.errorText = "";
        root.phase = "busy";
        if (root.mode === "capture") captureProc.running = true;
        else {
            root.syncOnly = false;
            root.applyMsg = text;
            applyProc.running = true;
        }
    }

    function onApplied(text) {
        // 陈旧结果（Esc 关窗后进程仍在飞，用户已开了新会话）→ 丢掉，别回写面板状态
        if (!root.syncOnly && root.phase !== "busy") return;
        const r = root.parseJson(text, Translation.tr("vault-commit apply returned nothing"));
        if (r.ok) {
            root.syncOnly = false;
            root.okText = r.hash;
            root.phase = "done";
            Quickshell.execDetached(["notify-send", "-a", "Shell",
                Translation.tr("Pushed %1").arg(root.vaultName), r.hash]);
            doneTimer.restart();
            return;
        }
        // 「顺手同步」的结果（stage:no-changes / pull 失败）：不是提交失败。
        // 成功那档不弹通知 —— 弹框就开在眼前，提示条够了；失败那档值得 critical。
        if (root.syncOnly && (r.stage === "no-changes" || r.stage === "pull")) {
            root.syncOnly = false;
            if (r.stage === "no-changes") {
                root.cleanText = r.error || Translation.tr("Nothing to commit");
                root.phase = "clean";
            } else {
                root.errorText = r.error || Translation.tr("Unknown error");
                root.phase = "error";
                Quickshell.execDetached(["notify-send", "-a", "Shell", "-u", "critical",
                    Translation.tr("Commit failed: %1").arg(root.vaultName), r.error || ""]);
            }
            return;
        }
        // 失败退回编辑态（不是 error 态）：message 留在框里，回车就能原样重试。
        // push 失败时脚本已经把提交留在本地了，重试会走「无改动 → 只补推」那条路。
        root.syncOnly = false;
        root.errorText = r.error || Translation.tr("Unknown error");
        root.phase = "editing";
        Quickshell.execDetached(["notify-send", "-a", "Shell", "-u", "critical",
            Translation.tr("Commit failed: %1").arg(root.vaultName), r.error || ""]);
    }

    function onCaptured(text) {
        const r = root.parseJson(text, Translation.tr("vault-commit capture returned nothing"));
        if (r.ok) {
            root.okText = r.title;
            root.phase = "done";
            Quickshell.execDetached(["notify-send", "-a", "Shell",
                Translation.tr("Note created"), r.title]);
            doneTimer.restart();
            return;
        }
        root.errorText = r.error || Translation.tr("Unknown error");
        root.phase = "editing";
    }

    // ══ 进程（全部挂在 Scope 上，不随弹框销毁）══════════════════════════
    Process {
        id: detectProc
        running: false
        command: [root.script, "detect"]
        stdout: StdioCollector {
            id: detectOut
            onStreamFinished: root.onDetected(detectOut.text)
        }
    }

    Process {
        id: listProc
        running: false
        command: [root.script, "list"]
        stdout: StdioCollector {
            id: listOut
            onStreamFinished: root.onList(listOut.text)
        }
    }

    Process {
        id: statusProc
        running: false
        command: [root.script, "status", root.vaultKey]
        stdout: StdioCollector {
            id: statusOut
            onStreamFinished: root.onStatus(statusOut.text)
        }
    }

    Process {
        id: prefixProc
        running: false
        command: [root.script, "title-prefix"]
        stdout: StdioCollector {
            id: prefixOut
            onStreamFinished: root.onTitlePrefix(prefixOut.text)
        }
    }

    Process {
        id: applyProc
        running: false
        command: [root.script, "apply", root.vaultKey, root.applyMsg]
        stdout: StdioCollector {
            id: applyOut
            onStreamFinished: root.onApplied(applyOut.text)
        }
    }

    Process {
        id: captureProc
        running: false
        command: [root.script, "capture", root.vaultKey, root.inputText]
        stdout: StdioCollector {
            id: captureOut
            onStreamFinished: root.onCaptured(captureOut.text)
        }
    }

    Timer {
        id: doneTimer
        interval: 1400
        onTriggered: root.close()
    }

    // busy 看门狗：正常操作秒级到几十秒（apply 里含 push）。超时 = 子进程疑似挂住，
    // 干掉它并复位——否则 phase 永远卡 busy，所有快捷键静默失灵，只能重启 quickshell
    // 才能救（2026-10-11 事故：xdg-open 前台等 Obsidian 主进程退出，等到了天荒地老）。
    // 注：杀进程后 StdioCollector 仍会补一条「返回为空」的迟到结果，可能把这里的提示
    // 换成更朴素的错误文案——两者都在说「这轮没成」，可接受。
    Timer {
        id: busyWatchdog
        interval: 120000
        repeat: false
        running: root.busy
        onTriggered: {
            root.errorText = Translation.tr("Operation timed out (the process seems stuck). Reset, please retry.");
            root.phase = "editing";
            applyProc.running = false;
            captureProc.running = false;
        }
    }

    // ══ 入口 ═══════════════════════════════════════════════════════════
    IpcHandler {
        target: "vaultCommit"
        function commit(): void { root.openCommit(); }
        function capture(): void { root.openCapture(); }
        function close(): void { root.close(); }
    }

    GlobalShortcut {
        name: "vaultCommitOpen"
        description: "Open vault commit dialog"
        onPressed: root.openCommit()
    }

    GlobalShortcut {
        name: "vaultCaptureOpen"
        description: "Open vault quick-note dialog"
        onPressed: root.openCapture()
    }

    GlobalShortcut {
        name: "vaultCommitClose"
        description: "Close vault dialog"
        onPressed: root.close()
    }

    // ══ 内联小组件 ═══════════════════════════════════════════════════════
    // 一律用 Appearance 的 token 取色，别写死颜色，这样 preset / 主题换了跟着变。

    // 胶囊数字：+12 / −3
    component StatChip: Rectangle {
        id: chip
        property string label
        property color accent: Appearance.colors.colPrimary
        implicitWidth: chipLabel.implicitWidth + 18
        implicitHeight: chipLabel.implicitHeight + 6
        radius: Appearance.rounding.full
        color: ColorUtils.transparentize(chip.accent, 0.84)
        StyledText {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.label
            color: chip.accent
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
        }
    }

    // 提示条（error / clean / done）。
    // 没直接用 NoticeBox：它固定取 colPrimaryContainer，那色跟本弹框卡片用的
    // m3surfaceContainerHigh 几乎同色（#2d2a2f vs #2b2a2a），亮底上等于看不见；
    // 而且 error 场景它也不变红。这里改成按语义色淡淡的染一层。
    component VaultNotice: Rectangle {
        id: notice
        property string icon: "info"
        property string message: ""
        property color accent: Appearance.colors.colPrimary
        implicitHeight: noticeRow.implicitHeight + 20
        radius: root.innerRadius
        color: ColorUtils.transparentize(notice.accent, 0.88)
        border.width: 1
        border.color: ColorUtils.transparentize(notice.accent, 0.72)
        RowLayout {
            id: noticeRow
            anchors { fill: parent; margins: 10 }
            spacing: 10
            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: notice.icon
                iconSize: Appearance.font.pixelSize.huge
                color: notice.accent
            }
            StyledText {
                Layout.fillWidth: true
                text: notice.message
                color: Appearance.m3colors.m3onSurface
                wrapMode: Text.WordWrap
            }
        }
    }

    // ══ 弹框 ═══════════════════════════════════════════════════════════
    Loader {
        id: panelLoader
        active: root.panelOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            // 选择器卡片的尺寸：wrapper 和它的阴影替身都用这一份，省得公式写两遍
            readonly property real pickerWidth: Math.min(440, panelWindow.width - 100)
            readonly property real pickerHeight: Math.min(440, 176 + root.candidates.length * 52)

            visible: panelLoader.active
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:vaultCommit"
            WlrLayershell.layer: WlrLayer.Overlay
            // Exclusive 是协议级键盘独占：面板出现瞬间盲打，字符不会漏给底下的 Obsidian
            // （结论来自 overview/Overview.qml 的实测）
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            mask: Region { item: scrim }

            // 点外部关闭
            Rectangle {
                id: scrim
                anchors.fill: parent
                color: Appearance.colors.colScrim

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: root.close()
                }
            }

            // ── 主对话框 ────────────────────────────────────────────────
            Rectangle {
                id: dialog
                anchors.centerIn: parent
                visible: root.phase !== "picking"
                z: 1
                // m3surfaceContainerHigh 正是 SelectionDialog 用的那一档，圆角也对齐（同一份 cardRadius）：
                // 认库失败切到选择器时，两者同屏切换不跳色、不跳角、不跳透明度。
                // 用**不透明**的 m3 原色而不是 colLayer3/colLayer0 —— 后者会跟随用户的透明度设置，
                // 卡片会透出底下终端的字（实测很难看），而 SelectionDialog 本身就是不透明的，这样才齐。
                color: Appearance.m3colors.m3surfaceContainerHigh
                radius: root.cardRadius
                readonly property real padding: 18

                implicitWidth: Math.min(560, panelWindow.width - 80)
                implicitHeight: contentColumn.implicitHeight + dialog.padding * 2

                // 吞掉点击，免得穿透到 scrim 上把面板关了
                MouseArea { anchors.fill: parent }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: dialog.padding
                    spacing: 14

                    // ── 标题行 ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialSymbol {
                            text: root.mode === "capture" ? "edit_note" : "book_2"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.m3colors.m3onSurface
                        }

                        StyledText {
                            Layout.fillWidth: true
                            color: Appearance.m3colors.m3onSurface
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            text: {
                                const who = root.vaultLabel || root.vaultName;
                                if (root.phase === "detecting") return Translation.tr("Detecting vault…");
                                if (!who) return Translation.tr("Vault");
                                return root.mode === "capture"
                                    ? Translation.tr("Quick note to %1").arg(who)
                                    : Translation.tr("Commit to %1").arg(who);
                            }
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            colBackground: "transparent"
                            onClicked: root.close()
                            contentItem: MaterialSymbol {
                                text: "close"
                                iconSize: Appearance.font.pixelSize.large
                                color: Appearance.m3colors.m3onSurface
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    // ── 目标库切换（配了多个库时才出现）──
                    // 默认是识别出来的那个库；这里可以随时改到另一个。
                    // 提交模式也留着 —— 认错库时不用关掉重开。
                    Flow {
                        Layout.fillWidth: true
                        visible: root.vaults.length > 1 && root.phase !== "detecting"
                        enabled: !root.busy && root.phase !== "loading"
                        spacing: 8

                        Repeater {
                            model: root.vaults

                            delegate: RippleButton {
                                id: vaultChip
                                required property var modelData
                                readonly property bool isCurrent: modelData.key === root.vaultKey

                                implicitHeight: 30
                                horizontalPadding: 12
                                buttonRadius: Appearance.rounding.full
                                colBackground: vaultChip.isCurrent
                                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.84)
                                    : ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.92)
                                colBackgroundHover: vaultChip.isCurrent
                                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.76)
                                    : ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.86)
                                onClicked: root.switchVault(modelData.key)

                                contentItem: RowLayout {
                                    spacing: 6
                                    MaterialSymbol {
                                        visible: vaultChip.isCurrent
                                        text: "check"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colPrimary
                                    }
                                    StyledText {
                                        text: modelData.label || modelData.name
                                        color: vaultChip.isCurrent
                                            ? Appearance.colors.colPrimary
                                            : ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.35)
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: vaultChip.isCurrent ? Font.Medium : Font.Normal
                                    }
                                }
                            }
                        }
                    }

                    // ── 分隔线 ──
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        visible: root.phase !== "detecting"
                        color: Appearance.m3colors.m3outline
                    }

                    // ── 读取中 ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        Layout.bottomMargin: 6
                        spacing: 12
                        visible: root.phase === "detecting" || root.phase === "loading"

                        MaterialLoadingIndicator {
                            implicitSize: 22
                            loading: true
                        }
                        StyledText {
                            Layout.fillWidth: true
                            color: Appearance.m3colors.m3onSurface
                            text: root.mode === "capture" ? Translation.tr("Creating note…") : Translation.tr("Reading changes…")
                        }
                    }

                    // ── 变更摘要（只读，给写 message 的人看）──
                    // 比卡片亮一档的容器（也是不透明的 m3 原色）：把「只读的信息」和下面的
                    // 「输入」分开，整个弹框也不再是一张平底。
                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.mode === "commit" && root.phase === "editing"
                                 && (root.fileCount > 0 || root.aheadCount > 0)
                        implicitHeight: summaryColumn.implicitHeight + 20
                        color: Appearance.m3colors.m3surfaceContainerHighest
                        radius: root.innerRadius

                        ColumnLayout {
                            id: summaryColumn
                            anchors { fill: parent; margins: 10 }
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    visible: root.fileCount > 0
                                    color: Appearance.m3colors.m3onSurface
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    font.weight: Font.Medium
                                    text: Translation.tr("%1 files changed").arg(root.fileCount)
                                }
                                StatChip {
                                    visible: root.fileCount > 0
                                    label: `+${root.insCount}`
                                    accent: Appearance.m3colors.m3tertiary
                                }
                                StatChip {
                                    visible: root.fileCount > 0
                                    label: `−${root.delCount}`
                                    accent: Appearance.colors.colError
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    visible: root.aheadCount > 0
                                    color: ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.4)
                                    text: Translation.tr("%1 unpushed commits").arg(root.aheadCount)
                                }
                            }

                            Repeater {
                                model: root.shownFiles
                                delegate: RowLayout {
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // M/A/D 做成小色章，扫一眼就知道是什么改动
                                    Rectangle {
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        radius: Appearance.rounding.verysmall
                                        color: ColorUtils.transparentize(
                                            root.statusColor(root.fileList[index].status), 0.82)
                                        StyledText {
                                            anchors.centerIn: parent
                                            text: root.fileList[index].status
                                            color: root.statusColor(root.fileList[index].status)
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.Bold
                                        }
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        color: Appearance.m3colors.m3onSurface
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        elide: Text.ElideMiddle
                                        text: root.fileList[index].path
                                    }
                                }
                            }

                            StyledText {
                                visible: root.hiddenFiles > 0
                                color: ColorUtils.transparentize(Appearance.m3colors.m3onSurface, 0.4)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                // 复用已有的键（ClockWidgetPopup 也在用），别另造
                                text: Translation.tr("... and %1 more").arg(root.hiddenFiles)
                            }
                        }
                    }

                    // ── 输入框 ──
                    MaterialTextField {
                        id: inputField
                        Layout.fillWidth: true
                        visible: root.phase === "editing" || root.phase === "busy"
                        enabled: root.phase === "editing"
                        placeholderText: root.mode === "capture"
                            ? Translation.tr("Note title…")
                            : Translation.tr("Commit message…")

                        // 单向绑定 + onTextEdited 回写：不会成环，也能让 root 主动改内容
                        text: root.inputText
                        onTextEdited: root.inputText = text
                        onAccepted: root.submit()

                        // 每次进入编辑态都重新聚焦；速记模式把光标放到日期前缀之后
                        Connections {
                            target: root
                            function onPhaseChanged() {
                                if (root.phase !== "editing") return;
                                inputField.forceActiveFocus();
                                inputField.cursorPosition = root.mode === "capture"
                                    ? inputField.length
                                    : 0;
                            }
                        }
                    }

                    // ── 结果提示 ──
                    VaultNotice {
                        Layout.fillWidth: true
                        visible: root.errorText !== ""
                        icon: "error"
                        accent: Appearance.colors.colError
                        message: root.errorText
                    }

                    VaultNotice {
                        Layout.fillWidth: true
                        visible: root.phase === "clean"
                        icon: "check_circle"
                        message: root.cleanText || Translation.tr("Nothing to commit")
                    }

                    VaultNotice {
                        Layout.fillWidth: true
                        visible: root.phase === "done"
                        icon: "check_circle"
                        accent: Appearance.m3colors.m3tertiary
                        message: root.mode === "capture"
                            ? Translation.tr("Created %1").arg(root.okText)
                            : Translation.tr("Pushed %1").arg(root.okText)
                    }

                    // ── 按钮行 ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: root.phase !== "detecting" && root.phase !== "loading"

                        StyledText {
                            Layout.fillWidth: true
                            visible: root.phase === "editing"
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            text: Translation.tr("Enter to confirm · Esc to cancel")
                        }
                        Item {
                            Layout.fillWidth: true
                            visible: root.phase !== "editing"
                        }

                        DialogButton {
                            buttonText: (root.phase === "editing" || root.phase === "busy")
                                ? Translation.tr("Cancel")
                                : Translation.tr("Close")
                            enabled: !root.busy
                            onClicked: root.close()
                        }
                        DialogButton {
                            visible: root.phase === "editing" || root.phase === "busy"
                            // 没有文件改动却进了编辑态 = 有历史提交没推上去，这时按钮只管推
                            buttonText: root.mode === "capture"
                                ? Translation.tr("Create")
                                : (root.fileCount === 0
                                    ? Translation.tr("Push")
                                    : Translation.tr("Commit and push"))
                            enabled: root.phase === "editing"
                            onClicked: root.submit()
                        }
                    }
                }
            }

            // 阴影：做成 dialog 的兄弟节点，用 z 排序（卡片 z=1 盖在它上面）。
            // 这样不必像 WallpaperSelectorContent 那样外包一层 Item 留 margin，零布局改动。
            StyledRectangularShadow {
                target: dialog
                z: 0
            }

            // ── 识别不到库 → 选择器 ─────────────────────────────────────
            // SelectionDialog 内部是 anchors.fill 设计的（上游给侧栏 460px 宽用），
            // 直接塞进全屏 PanelWindow 会撑成一整块 → 这里给它一个居中、定尺寸的容器。
            // 容器外的点击漏回 PanelWindow 的 scrim，照样能点外关闭。
            // SelectionDialog 自己不带阴影（上游在侧栏里用，那儿不需要浮起来），
            // 它的卡片色/圆角也不好在外面覆盖 → 垫一个同尺寸、透明的圆角矩形当阴影替身，
            // 这样「认库失败 → 选中库」两个视图切换时不会一个浮着一个平着。
            Rectangle {
                id: pickerShadowShape
                anchors.centerIn: parent
                z: 0
                visible: root.phase === "picking"
                width: panelWindow.pickerWidth
                height: panelWindow.pickerHeight
                color: "transparent"
                radius: root.cardRadius
            }

            StyledRectangularShadow {
                target: pickerShadowShape
                z: 0
            }

            Item {
                id: pickerWrapper
                anchors.centerIn: parent
                z: 1
                visible: root.phase === "picking"
                width: panelWindow.pickerWidth
                height: panelWindow.pickerHeight

                // 接住 Esc（keys 从列表往上冒泡到这里）
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    }
                }

                SelectionDialog {
                    anchors.fill: parent
                    dialogMargin: 0
                    dialogRadius: root.cardRadius
                    titleText: Translation.tr("Which vault?")
                    items: root.candidateItems
                    defaultChoice: root.candidateItems.length > 0 ? root.candidateItems[0] : undefined
                    onCanceled: root.close()
                    onSelected: result => {
                        const idx = root.candidateItems.indexOf(result);
                        if (idx < 0) return;
                        const c = root.candidates[idx];
                        root.adoptVault(c.key, c.name, c.label);
                    }
                }
            }
        }
    }
}
