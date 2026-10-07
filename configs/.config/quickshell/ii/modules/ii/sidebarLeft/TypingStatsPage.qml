import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 左栏「打字」页（本地新增，非上游）。
// 只读 TypingStats 里已经聚合好的数字，自己不碰数据文件。
//
// 页面根是 Item 而不是 ContentPage —— 左栏的 SwipeView 里所有页面都是
// 这个形状（见同目录 Translator.qml），滚动自己用 StyledFlickable 搭。
Item {
    id: pageRoot
    property real padding: 4
    readonly property int cardPadding: 12
    readonly property int cardSpacing: 10

    // 「输入节奏」「常用词」两张卡的 tab（0 = 今日 / 词语，1 = 全部 / 拼音）
    property int hourMode: 0
    property int wordMode: 0

    // 热力图格子 / 每小时柱子的几何由 TypingStats 算：页面只把「卡片内容区
    // 有多宽」推过去。这么绕一圈是为了让 371 个格子、24 根柱子的 delegate 完全
    // 不引用页面根的 id —— 页面被 SwipeView 重新求值时，delegate 里 `pageRoot.x`
    // 这类绑定会在页面根还没注册好 id 的那一刻求值，拿到 null 并刷一屏 TypeError。
    // 顺带 371 格共享同一份坐标计算，也省掉 371 次重复算术。
    function pushContentWidth() {
        TypingStats.cardContentWidth = pageRoot.width - 2 * pageRoot.padding - 8 - 2 * pageRoot.cardPadding;
    }

    onWidthChanged: pageRoot.pushContentWidth()
    Component.onCompleted: pageRoot.pushContentWidth()

    // 「输入节奏」卡底部那三个小数字。放在页面里算是因为标签要翻译（服务层不碰
    // 翻译）；而 delegate 里只读 modelData —— 仍然守住「delegate 不引用页面根 id」。
    function rhythmSummary() {
        if (pageRoot.hourMode === 0) {
            const today = TypingStats.detailsToday;
            const peak = today.peak_hour;
            return [{
                    "label": Translation.tr("输入段数"),
                    "value": TypingStats.groupDigits(today.sessions ?? 0)
                }, {
                    "label": Translation.tr("最长连打"),
                    "value": (today.longest_burst_min ?? 0).toFixed(1) + " " + Translation.tr("分钟")
                }, {
                    "label": Translation.tr("峰值时段"),
                    "value": (peak === null || peak === undefined) ? "--" : String(peak).padStart(2, "0") + ":00"
                }];
        }
        const hours = TypingStats.detailsAll.by_hour ?? [];
        const peakAll = hours.length > 0 ? hours.indexOf(Math.max(...hours)) : -1;
        return [{
                "label": Translation.tr("累计输入"),
                "value": TypingStats.groupDigits(TypingStats.detailsChars) + " " + Translation.tr("字")
            }, {
                "label": Translation.tr("明细条数"),
                "value": TypingStats.groupDigits(TypingStats.detailsRows)
            }, {
                "label": Translation.tr("峰值时段"),
                "value": peakAll >= 0 ? String(peakAll).padStart(2, "0") + ":00" : "--"
            }];
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

            // 数据读不到时（daemon 没跑 / 路径不对）把路径直接写出来，省得去猜
            StyledText {
                visible: !TypingStats.available
                Layout.fillWidth: true
                Layout.topMargin: 24
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: Translation.tr("读不到打字数据") + "\n" + TypingStats.historyFile
            }

            // ── 今日 + 本周 / 本月 / 总计 ──────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: overviewColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: overviewColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("今日输入")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            visible: TypingStats.updatedAt.length > 11
                            text: Translation.tr("更新于") + " " + TypingStats.updatedAt.slice(11)
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            text: TypingStats.groupDigits(TypingStats.todayCount)
                            color: Appearance.colors.colPrimary
                            font {
                                family: Appearance.font.family.numbers
                                pixelSize: 34
                                variableAxes: Appearance.font.variableAxes.numbers
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 8
                            text: Translation.tr("字")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 7
                            visible: TypingStats.currentStreak > 1
                            spacing: 4

                            StyledText { // 火苗：走 nerd font，别用 emoji
                                Layout.alignment: Qt.AlignVCenter
                                // md-fire（U+F0238，材料图标那套，跟 ii 整体风格一致）。
                                // 写码点而不是贴字形：源文件保持纯 ASCII，也不会被工具改坏。
                                // 别用 fa-fire（U+F06D）—— 那个字形底下带横杠，小号下像下划线。
                                text: String.fromCodePoint(0xF0238)
                                color: Appearance.colors.colPrimary
                                font {
                                    family: Appearance.font.family.iconNerd
                                    pixelSize: Appearance.font.pixelSize.smaller
                                }
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                text: TypingStats.currentStreak + " " + Translation.tr("天")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                    }

                    Rectangle { // 分隔线
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        implicitHeight: 1
                        color: ColorUtils.transparentize(Appearance.m3colors.m3outlineVariant, 0.6)
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Repeater {
                            model: [{
                                    "label": Translation.tr("本周"),
                                    "value": TypingStats.weekCount
                                }, {
                                    "label": Translation.tr("本月"),
                                    "value": TypingStats.monthCount
                                }, {
                                    "label": Translation.tr("总计"),
                                    "value": TypingStats.totalCount
                                }]
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: TypingStats.groupDigits(modelData.value)
                                    color: Appearance.colors.colOnLayer2
                                    font {
                                        family: Appearance.font.family.numbers
                                        pixelSize: Appearance.font.pixelSize.large
                                        variableAxes: Appearance.font.variableAxes.numbers
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                            }
                        }
                    }
                }
            }

            // ── 近 7 天 ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: weekColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: weekColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("近 7 天")
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: TypingStats.groupDigits(TypingStats.last7Count) + " " + Translation.tr("字")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: TypingStats.last7Days
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.count > 0 ? TypingStats.groupDigits(modelData.count) : ""
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                                Item { // 柱子（高度按这 7 天的最大值归一）
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: modelData.count > 0 ? Math.max(3, Math.round(parent.height * modelData.count / TypingStats.last7Max)) : 2
                                        radius: 4
                                        color: modelData.isToday ? Appearance.colors.colPrimary
                                                                 : (modelData.count > 0 ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.45)
                                                                                        : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85))
                                        Behavior on height {
                                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                        }
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.isToday ? Translation.tr("今天") : modelData.label
                                    color: modelData.isToday ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                            }
                        }
                    }
                }
            }

            // ── 输入节奏（24 小时分布，来自 daemon 解析的 CSV 明细）──────────
            Rectangle {
                visible: TypingStats.showDetails
                Layout.fillWidth: true
                implicitHeight: rhythmColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: rhythmColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("输入节奏")
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            visible: TypingStats.detailsAvailable && TypingStats.updatedAt.length > 11
                            text: Translation.tr("数据更新于") + " " + TypingStats.detailsUpdatedAt.slice(11)
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    StyledText {
                        visible: !TypingStats.detailsAvailable
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: Translation.tr("明细还没生成") + "\n" + TypingStats.detailsFile + "\n" + Translation.tr("检查") + " systemctl --user status ii-stats"
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }

                    SecondaryTabBar {
                        id: hourBar
                        visible: TypingStats.detailsAvailable
                        currentIndex: pageRoot.hourMode
                        onCurrentIndexChanged: pageRoot.hourMode = hourBar.currentIndex
                        Repeater {
                            model: [{
                                    "text": Translation.tr("今日"),
                                    "icon": "today"
                                }, {
                                    "text": Translation.tr("全部"),
                                    "icon": "calendar_month"
                                }]
                            delegate: SecondaryTabButton {
                                buttonIcon: modelData.icon
                                buttonText: modelData.text
                            }
                        }
                    }

                    // 24 根柱子手工定位（不用 RowLayout 等分，原因见服务里 hourGap 那段）
                    Item {
                        visible: TypingStats.detailsAvailable
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        implicitHeight: TypingStats.hourBarHeight + TypingStats.hourLabelHeight

                        Repeater {
                            model: TypingStats.hourDistribution(pageRoot.hourMode === 0 ? "today" : "all")
                            delegate: Item {
                                x: modelData.x
                                width: modelData.width
                                height: parent.height

                                Rectangle {
                                    anchors {
                                        bottom: parent.bottom
                                        bottomMargin: TypingStats.hourLabelHeight
                                    }
                                    width: parent.width
                                    height: modelData.barHeight
                                    radius: Math.min(2, width / 2)
                                    color: modelData.count > 0 ? Appearance.colors.colPrimary
                                                               : Appearance.colors.colLayer1Hover
                                    Behavior on height {
                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                    }
                                }
                                StyledText {
                                    anchors {
                                        bottom: parent.bottom
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    text: modelData.label
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                            }
                        }
                    }

                    RowLayout {
                        visible: TypingStats.detailsAvailable
                        Layout.fillWidth: true

                        Repeater {
                            model: pageRoot.rhythmSummary()
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.value
                                    color: Appearance.colors.colOnLayer2
                                    font {
                                        family: Appearance.font.family.numbers
                                        pixelSize: Appearance.font.pixelSize.smaller
                                        variableAxes: Appearance.font.variableAxes.numbers
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                            }
                        }
                    }
                }
            }

            // ── 常用词 ─────────────────────────────────────────────────────
            Rectangle {
                visible: TypingStats.showDetails && TypingStats.detailsAvailable
                Layout.fillWidth: true
                implicitHeight: wordsColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: wordsColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("高频排行")
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: Translation.tr("全部记录")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    SecondaryTabBar {
                        id: wordBar
                        currentIndex: pageRoot.wordMode
                        onCurrentIndexChanged: pageRoot.wordMode = wordBar.currentIndex
                        Repeater {
                            model: [{
                                    "text": Translation.tr("词语"),
                                    "icon": "sort_by_alpha"
                                }, {
                                    "text": Translation.tr("拼音"),
                                    "icon": "keyboard_voice"
                                }]
                            delegate: SecondaryTabButton {
                                buttonIcon: modelData.icon
                                buttonText: modelData.text
                            }
                        }
                    }

                    Repeater {
                        model: TypingStats.topEntries(pageRoot.wordMode === 0 ? "chinese" : "pinyin")
                        delegate: Item {
                            Layout.fillWidth: true
                            implicitHeight: 20

                            Rectangle { // 占比条：一眼看出榜首和第二名差多少
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: Math.max(3, Math.round(parent.width * modelData.ratio))
                                radius: height / 2
                                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.78)
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                spacing: 6

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.w
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnLayer2
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                }
                                StyledText {
                                    text: TypingStats.groupDigits(modelData.n)
                                    color: Appearance.colors.colSubtext
                                    font {
                                        family: Appearance.font.family.numbers
                                        pixelSize: Appearance.font.pixelSize.smallest
                                        variableAxes: Appearance.font.variableAxes.numbers
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── 一年热力图 ─────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heatmapColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: heatmapColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("最近一年")
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            // 悬停时那一格的日期/字数顶上来，不悬停就显示数据截止日
                            text: TypingStats.hoveredCell ? TypingStats.hoveredCell.key + " · " + TypingStats.groupDigits(TypingStats.hoveredCell.count) + " " + Translation.tr("字")
                                                   : TypingStats.lastActiveKey
                            color: TypingStats.hoveredCell ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    Item {
                        id: heatmapGrid
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 2
                        implicitWidth: TypingStats.heatmapColumns * TypingStats.heatmapStep - TypingStats.heatmapGap
                        implicitHeight: 7 * TypingStats.heatmapStep - TypingStats.heatmapGap

                        Repeater {
                            model: TypingStats.heatmapCells
                            delegate: Rectangle {
                                x: modelData.x
                                y: modelData.y
                                width: modelData.size
                                height: modelData.size
                                radius: modelData.radius
                                visible: !modelData.future
                                color: TypingStats.levelColor(modelData.level)
                                // 今天那一格描个边：整块图里唯一需要一眼找到的格子
                                border.width: modelData.isToday ? 1 : 0
                                border.color: Appearance.colors.colOnLayer2
                            }
                        }

                        // 一个 MouseArea 管 371 格：按坐标反推是哪一格，
                        // 就不用量产 371 个 MouseArea（更别说 371 个 Popup）
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: mouse => {
                                const col = Math.floor(mouse.x / TypingStats.heatmapStep);
                                const row = Math.floor(mouse.y / TypingStats.heatmapStep);
                                const inside = col >= 0 && col < TypingStats.heatmapColumns && row >= 0 && row < 7;
                                const cell = inside ? TypingStats.heatmapCells[col * 7 + row] : null;
                                TypingStats.hoveredCell = (cell && !cell.future) ? cell : null;
                            }
                            onExited: TypingStats.hoveredCell = null
                        }
                    }

                    RowLayout { // 图例
                        Layout.alignment: Qt.AlignRight
                        spacing: 4

                        StyledText {
                            text: Translation.tr("少")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 9
                                implicitHeight: 9
                                radius: 2
                                color: TypingStats.levelColor(index)
                            }
                        }
                        StyledText {
                            text: Translation.tr("多")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }
                }
            }

            // ── 星期分布 ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: weekdayColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: weekdayColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("星期分布")
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: Translation.tr("日均") + " · " + TypingStats.groupDigits(TypingStats.averagePerActiveDay) + " " + Translation.tr("字")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: TypingStats.weekdayAverages
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: TypingStats.groupDigits(modelData.avg)
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: Math.max(2, Math.round(parent.height * modelData.avg / TypingStats.weekdayAvgMax))
                                        radius: 4
                                        // 周末（周六周日 = 最后两根）用主色强调：本机周末打字明显多
                                        color: modelData.label === "六" || modelData.label === "日" ? Appearance.colors.colPrimary
                                                                                                    : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.5)
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                }
                            }
                        }
                    }
                }
            }

            // ── 记录 ───────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: recordsColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: recordsColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 6

                    StyledText {
                        text: Translation.tr("记录")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    Repeater {
                        model: [{
                                "label": Translation.tr("单日最高"),
                                "value": TypingStats.groupDigits(TypingStats.bestDay.count) + " " + Translation.tr("字"),
                                "hint": TypingStats.bestDay.key
                            }, {
                                "label": Translation.tr("连续打卡"),
                                "value": TypingStats.currentStreak + " " + Translation.tr("天"),
                                "hint": Translation.tr("最长") + " " + TypingStats.longestStreak + " " + Translation.tr("天")
                            }, {
                                "label": Translation.tr("有记录"),
                                "value": TypingStats.activeDays + " " + Translation.tr("天"),
                                "hint": ""
                            }, {
                                "label": Translation.tr("上个月"),
                                "value": TypingStats.groupDigits(TypingStats.lastMonthCount) + " " + Translation.tr("字"),
                                "hint": ""
                            }]
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            StyledText {
                                text: modelData.label
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            StyledText {
                                visible: modelData.hint.length > 0
                                text: modelData.hint
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallest
                            }
                            StyledText {
                                text: modelData.value
                                color: Appearance.colors.colOnLayer2
                                font {
                                    family: Appearance.font.family.numbers
                                    pixelSize: Appearance.font.pixelSize.smaller
                                    variableAxes: Appearance.font.variableAxes.numbers
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
