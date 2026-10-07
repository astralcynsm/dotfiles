import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

// 左栏「监控」页（本地新增，非上游）。
//
// 数据全部来自 SystemMetrics（也就是 ii-stats-daemon 每 10 秒重写的小 JSON），
// 页面自己不跑任何命令、不读 /proc —— 上游 overlay 里那个 Resources 面板用的是
// ResourceUsage（3 秒一采、60 个样本 = 3 分钟窗口），这里要看的是「一整天」，
// 所以走 daemon。
Item {
    id: pageRoot
    property real padding: 4
    readonly property int cardPadding: 12
    readonly property int cardSpacing: 10
    property int curveIndex: 0 // 「今日曲线」选中的指标
    readonly property string curveKey: SystemMetrics.metricAt(pageRoot.curveIndex).key

    // 卡片里那种「标题 + 右边一个数字」的小行
    component StatRow: RowLayout {
        id: statRow
        property string label
        property string value
        property color valueColor: Appearance.colors.colOnLayer2
        Layout.fillWidth: true
        spacing: 6
        StyledText {
            text: statRow.label
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
        Item {
            Layout.fillWidth: true
        }
        StyledText {
            text: statRow.value
            color: statRow.valueColor
            font {
                family: Appearance.font.family.numbers
                pixelSize: Appearance.font.pixelSize.smaller
                variableAxes: Appearance.font.variableAxes.numbers
            }
        }
    }

    // 细进度条：轨道 + 填充，都是圆的
    component MiniBar: Rectangle {
        id: miniBar
        property real ratio: 0
        property color fillColor: Appearance.colors.colPrimary
        Layout.fillWidth: true
        implicitHeight: 6
        radius: height / 2
        color: Appearance.colors.colLayer1Hover
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: Math.max(0, Math.min(1, miniBar.ratio)) * parent.width
            radius: height / 2
            color: miniBar.fillColor
            Behavior on width {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    component Card: Rectangle {
        id: card
        default property alias content: cardColumn.data
        Layout.fillWidth: true
        implicitHeight: cardColumn.implicitHeight + 2 * pageRoot.cardPadding
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2
        ColumnLayout {
            id: cardColumn
            anchors.fill: parent
            anchors.margins: pageRoot.cardPadding
            spacing: 6
        }
    }

    StyledFlickable {
        id: flick
        anchors.fill: parent
        anchors.margins: pageRoot.padding
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 16
        clip: true

        ColumnLayout {
            id: contentColumn
            width: flick.width - 8
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: pageRoot.padding
            }
            spacing: pageRoot.cardSpacing

            // 采集器没在跑 / 数据太旧：直接说出来，别让用户对着旧数字猜
            StyledText {
                visible: !SystemMetrics.fresh
                Layout.fillWidth: true
                Layout.topMargin: 8
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: SystemMetrics.available
                      ? Translation.tr("数据太久没更新") + "\n" + Translation.tr("检查") + " systemctl --user status ii-stats"
                      : Translation.tr("读不到系统指标") + "\n" + SystemMetrics.summaryFile
            }

            // ── 现在 ───────────────────────────────────────────────────────
            Card {
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter
                        ClippedFilledCircularProgress {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: 62
                            lineWidth: 6
                            value: (SystemMetrics.cpu ?? 0) / 100
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("CPU")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter
                        ClippedFilledCircularProgress {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: 62
                            lineWidth: 6
                            value: (SystemMetrics.mem.percent ?? 0) / 100
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: Translation.tr("内存")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        StatRow {
                            label: Translation.tr("内存用量")
                            value: SystemMetrics.gibText(SystemMetrics.mem.used_gb) + " / " + SystemMetrics.gibText(SystemMetrics.mem.total_gb)
                        }
                        StatRow {
                            label: Translation.tr("交换")
                            value: SystemMetrics.percentText(SystemMetrics.mem.swap_percent)
                            valueColor: (SystemMetrics.mem.swap_percent ?? 0) > 30 ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                        }
                        StatRow {
                            label: Translation.tr("负载")
                            value: (SystemMetrics.loadInfo.load1 ?? 0).toFixed(2) + " / " + (SystemMetrics.loadInfo.load5 ?? 0).toFixed(2)
                        }
                        StatRow {
                            label: Translation.tr("运行时长")
                            value: SystemMetrics.uptimeText(SystemMetrics.loadInfo.uptime_hours)
                        }
                    }
                }
            }

            // ── GPU ────────────────────────────────────────────────────────
            Card {
                StyledText {
                    text: "GPU"
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    StyledText {
                        text: Translation.tr("使用率")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: SystemMetrics.percentText(SystemMetrics.gpu.util) + " · " + SystemMetrics.tempText(SystemMetrics.gpu.temp)
                        color: Appearance.colors.colOnLayer2
                        font {
                            family: Appearance.font.family.numbers
                            pixelSize: Appearance.font.pixelSize.smaller
                            variableAxes: Appearance.font.variableAxes.numbers
                        }
                    }
                }
                MiniBar {
                    ratio: (SystemMetrics.gpu.util ?? 0) / 100
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 6
                    StyledText {
                        text: Translation.tr("显存")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: SystemMetrics.mbText(SystemMetrics.gpu.mem_used_mb) + " / " + SystemMetrics.mbText(SystemMetrics.gpu.mem_total_mb)
                        color: Appearance.colors.colOnLayer2
                        font {
                            family: Appearance.font.family.numbers
                            pixelSize: Appearance.font.pixelSize.smaller
                            variableAxes: Appearance.font.variableAxes.numbers
                        }
                    }
                }
                MiniBar {
                    ratio: (SystemMetrics.gpu.mem_total_mb ?? 0) > 0 ? (SystemMetrics.gpu.mem_used_mb ?? 0) / SystemMetrics.gpu.mem_total_mb : 0
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    StatRow {
                        label: Translation.tr("功耗")
                        value: SystemMetrics.wattsText(SystemMetrics.gpu.power_w)
                    }
                    StatRow {
                        label: Translation.tr("频率")
                        value: SystemMetrics.clockText(SystemMetrics.gpu.clock_mhz)
                    }
                }

                // 吃 GPU 的进程（daemon 每 30 秒刷一次）
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    implicitHeight: 1
                    color: ColorUtils.transparentize(Appearance.m3colors.m3outlineVariant, 0.6)
                    visible: SystemMetrics.gpuProcs.length > 0
                }
                Repeater {
                    model: SystemMetrics.gpuProcs
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideMiddle
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                        StyledText {
                            text: SystemMetrics.mbText(modelData.mem_mb)
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }
                }
            }

            // ── 温度与风扇 ─────────────────────────────────────────────────
            Card {
                StyledText {
                    text: Translation.tr("温度与风扇")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                StatRow {
                    label: Translation.tr("CPU")
                    value: SystemMetrics.tempText(SystemMetrics.temps.cpu) + (SystemMetrics.temps.cpu_core_max !== undefined
                                                                       ? " (" + Translation.tr("最高") + " " + SystemMetrics.tempText(SystemMetrics.temps.cpu_core_max) + ")" : "")
                }
                StatRow {
                    label: "NVMe"
                    value: SystemMetrics.tempText(SystemMetrics.temps.nvme)
                }
                StatRow {
                    label: Translation.tr("无线网卡")
                    value: SystemMetrics.tempText(SystemMetrics.temps.wifi)
                }
                StatRow {
                    label: Translation.tr("内存条")
                    value: SystemMetrics.tempText(SystemMetrics.temps.ram)
                }
                StatRow {
                    label: Translation.tr("风扇")
                    value: SystemMetrics.fans.length > 0 ? SystemMetrics.fans.map(f => f + " RPM").join(" / ") : "--"
                }
            }

            // ── 电池 ───────────────────────────────────────────────────────
            Card {
                StyledText {
                    text: Translation.tr("电池")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    StyledText {
                        text: SystemMetrics.percentText(SystemMetrics.bat.percent)
                        color: Appearance.colors.colOnLayer2
                        font {
                            family: Appearance.font.family.numbers
                            pixelSize: Appearance.font.pixelSize.large
                            variableAxes: Appearance.font.variableAxes.numbers
                        }
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 3
                        text: SystemMetrics.bat.ac ? Translation.tr("已插电") : Translation.tr("放电中")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 4
                        visible: SystemMetrics.bat.minutes_left !== undefined
                        text: Math.floor((SystemMetrics.bat.minutes_left ?? 0) / 60) + "h " + ((SystemMetrics.bat.minutes_left ?? 0) % 60) + "m"
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
                MiniBar {
                    ratio: (SystemMetrics.bat.percent ?? 0) / 100
                }
                StatRow {
                    Layout.topMargin: 2
                    label: Translation.tr("功耗")
                    value: SystemMetrics.wattsText(SystemMetrics.bat.power_w)
                }
                StatRow {
                    label: Translation.tr("健康度")
                    value: SystemMetrics.percentText(SystemMetrics.bat.health_percent)
                }
                StatRow {
                    label: Translation.tr("满电容量")
                    value: SystemMetrics.whText(SystemMetrics.bat.wh_full)
                }
            }

            // ── 今日曲线 ───────────────────────────────────────────────────
            Card {
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("今日曲线")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: Translation.tr("平均") + " " + (SystemMetrics.metricData(pageRoot.curveKey).avg ?? "--")
                              + "  " + Translation.tr("峰值") + " " + (SystemMetrics.metricData(pageRoot.curveKey).max ?? "--")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }

                SecondaryTabBar {
                    id: metricBar
                    currentIndex: pageRoot.curveIndex
                    onCurrentIndexChanged: pageRoot.curveIndex = metricBar.currentIndex
                    Repeater {
                        model: SystemMetrics.metricList
                        delegate: SecondaryTabButton {
                            buttonIcon: modelData.icon
                            buttonText: "" // 只给图标：侧栏宽度不够五段文字
                        }
                    }
                }

                Rectangle {
                    id: graphBackground
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    implicitHeight: 96
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colSecondaryContainer
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: graphBackground.width
                            height: graphBackground.height
                            radius: graphBackground.radius
                        }
                    }
                    Graph {
                        anchors {
                            fill: parent
                            margins: 4
                        }
                        values: SystemMetrics.curveFor(pageRoot.curveKey)
                        points: SystemMetrics.curvePoints
                        color: Appearance.colors.colOnSecondaryContainer
                        fillOpacity: 0.35
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "00:00" + "  ·  " + Translation.tr("现在") + "  ·  " + SystemMetrics.metricAt(pageRoot.curveIndex).name
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallest
                }
            }

            // ── 近 7 天 CPU ────────────────────────────────────────────────
            Card {
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("近 7 天 CPU")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: Translation.tr("柱高 = 当日峰值")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    visible: SystemMetrics.last7History.length === 0
                    text: Translation.tr("采集器刚装好，还没有昨天的数据")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }

                RowLayout {
                    visible: SystemMetrics.last7History.length > 0
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: SystemMetrics.last7History
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.cpu_max !== null && modelData.cpu_max !== undefined ? Math.round(modelData.cpu_max) : ""
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallest
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                Rectangle { // 峰值柱
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: modelData.cpu_max ? Math.max(2, Math.round(parent.height * modelData.cpu_max / SystemMetrics.historyCpuMax)) : 2
                                    radius: 3
                                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.55)
                                }
                                Rectangle { // 平均柱（叠在峰值柱中间，一眼看出波动）
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    height: modelData.cpu_avg ? Math.max(2, Math.round(parent.height * modelData.cpu_avg / SystemMetrics.historyCpuMax)) : 2
                                    radius: 3
                                    color: Appearance.colors.colPrimary
                                }
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: (modelData.date ?? "").slice(5)
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallest
                            }
                        }
                    }
                }
            }

            // ── 磁盘 ───────────────────────────────────────────────────────
            Card {
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("磁盘")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: SystemMetrics.gibText(SystemMetrics.disk.used_gb) + " / " + SystemMetrics.gibText(SystemMetrics.disk.total_gb)
                              + " · " + SystemMetrics.percentText(SystemMetrics.disk.percent)
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
                MiniBar {
                    ratio: (SystemMetrics.disk.percent ?? 0) / 100
                }
                StatRow {
                    Layout.topMargin: 2
                    label: Translation.tr("剩余")
                    value: SystemMetrics.gibText(SystemMetrics.disk.free_gb)
                }
                StatRow {
                    label: Translation.tr("数据更新于")
                    value: SystemMetrics.updatedAt.length > 11 ? SystemMetrics.updatedAt.slice(11, 19) : "--"
                }
            }
        }
    }
}
