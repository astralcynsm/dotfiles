import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 左栏「音乐」页（本地新增，非上游）。
//
// 数据分两路，别混：
//   · **在播** → MprisController（本地 MPRIS，实时、带进度）
//   · **历史** → LastFm 服务（last.fm 的 scrobble 记录）
// 页面只读，自己不发请求、不碰任何数据文件。
//
// 注意 last.fm 接口不给单曲时长，所以这里没有「今天听了几小时」。
Item {
    id: pageRoot
    property real padding: 4
    readonly property int cardPadding: 12
    readonly property int cardSpacing: 10
    readonly property int timelineLimit: 60 // 今日列表最多铺这么多行（外层已经是滚动容器，不能嵌套滚动）

    // ⚠ 这个页面在 ii 启动时就会被 createObject 出来（SidebarLeftContent 的
    // contentChildren 不是懒加载），但那时它多半**不可见** —— 别在创建时就发请求。
    // 初始就可见的情况（SwipeView 停在那一页）才在 onCompleted 里补一次。
    // 服层有 90 秒节流、未配置时直接 return，所以这两处都可以无脑调。
    Component.onCompleted: {
        if (visible)
            LastFm.refresh();
    }
    onVisibleChanged: {
        if (visible)
            LastFm.refresh();
    }

    readonly property var player: MprisController.activePlayer
    readonly property var track: MprisController.activeTrack
    // 用「有没有标题」判断，不用「有没有 player」：D-Bus 上常驻着 playerctld
    // 这种空壳播放器，player 非 null 但没有任何元数据，会让在播卡白占一大块。
    readonly property bool hasPlayer: (pageRoot.track?.title ?? "").length > 0

    // 进度靠定时器推：MprisPlayer.position 不是可通知属性（ii 的 PlayerControl 同样这么干）
    Timer {
        running: pageRoot.visible && (pageRoot.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: pageRoot.player?.positionChanged()
    }

    function progress() {
        const p = pageRoot.player;
        if (!p || !p.length || p.length <= 0)
            return 0;
        return Math.max(0, Math.min(1, p.position / p.length));
    }

    function fmtTime(sec) {
        if (!sec || sec < 0 || isNaN(sec))
            return "0:00";
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return m + ":" + String(s).padStart(2, "0");
    }

    // 在播卡的三个按钮（不用 PlayerControl 里那个内联 component：那个是给
    // 媒体弹窗用的，字号/间距都按那边的大尺寸调过）
    component ControlButton: RippleButton {
        id: ctrlBtn
        property string iconName
        property bool primary: false
        implicitWidth: primary ? 40 : 32
        implicitHeight: primary ? 40 : 32
        buttonRadius: primary && !(pageRoot.player?.isPlaying ?? false) ? height / 2 : Appearance.rounding.small
        colBackground: primary ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
        colBackgroundHover: primary ? Appearance.colors.colPrimaryHover : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.78)
        colRipple: primary ? Appearance.colors.colPrimaryActive : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
        contentItem: MaterialSymbol {
            horizontalAlignment: Text.AlignHCenter
            iconSize: ctrlBtn.primary ? Appearance.font.pixelSize.large : Appearance.font.pixelSize.larger
            fill: 1
            color: ctrlBtn.primary ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
            text: ctrlBtn.iconName
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

            // ── 在播（MPRIS 有播放器时才出现）──────────────────────────
            Rectangle {
                visible: pageRoot.hasPlayer
                Layout.fillWidth: true
                implicitHeight: nowPlayingRow.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                RowLayout {
                    id: nowPlayingRow
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 10

                    Rectangle { // 封面
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 72
                        implicitHeight: 72
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1
                        clip: true

                        StyledImage {
                            anchors.fill: parent
                            source: pageRoot.track?.artUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MaterialSymbol { // 没封面时的占位
                            anchors.centerIn: parent
                            visible: (pageRoot.track?.artUrl ?? "").length === 0
                            text: "music_note"
                            iconSize: 28
                            color: Appearance.colors.colSubtext
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: pageRoot.track?.title ?? ""
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: pageRoot.track?.artist ?? ""
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            visible: (pageRoot.track?.album ?? "").length > 0
                            text: pageRoot.track?.album ?? ""
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        StyledProgressBar { // 进度
                            Layout.fillWidth: true
                            wavy: pageRoot.player?.isPlaying ?? false
                            highlightColor: Appearance.colors.colPrimary
                            trackColor: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
                            value: pageRoot.progress()
                        }

                        RowLayout { // 时间 + 控制
                            Layout.fillWidth: true
                            spacing: 6

                            StyledText {
                                text: pageRoot.fmtTime(pageRoot.player?.position) + " / " + pageRoot.fmtTime(pageRoot.player?.length)
                                color: Appearance.colors.colSubtext
                                font {
                                    family: Appearance.font.family.numbers
                                    pixelSize: Appearance.font.pixelSize.smallest
                                    variableAxes: Appearance.font.variableAxes.numbers
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ControlButton {
                                visible: pageRoot.player?.canGoPrevious ?? false
                                iconName: "skip_previous"
                                downAction: () => pageRoot.player?.previous()
                            }
                            ControlButton {
                                primary: true
                                iconName: (pageRoot.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                                downAction: () => pageRoot.player?.togglePlaying()
                            }
                            ControlButton {
                                visible: pageRoot.player?.canGoNext ?? false
                                iconName: "skip_next"
                                downAction: () => pageRoot.player?.next()
                            }
                        }
                    }
                }
            }

            // ── 今日概览 ───────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: todayColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: todayColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("今日收听")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            visible: LastFm.updatedAt.length > 0
                            text: Translation.tr("更新于") + " " + LastFm.updatedAt
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    RowLayout { // 曲数
                        Layout.fillWidth: true
                        spacing: 6
                        StyledText {
                            text: LastFm.loading && LastFm.todayCount === 0 ? "—" : String(LastFm.todayCount)
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
                            text: Translation.tr("首")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 8
                            visible: LastFm.truncated
                            text: Translation.tr("仅统计最近 1000 条")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    // 未配置 / 出错 / 今天还没听 —— 三种空态的提示
                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        visible: !LastFm.enabled
                        wrapMode: Text.Wrap
                        text: LastFm.configured
                                ? Translation.tr("last.fm 已在设置里关闭")
                                : Translation.tr("还没配置 last.fm。到 设置 → 服务 里填用户名和 API key（key 在 last.fm 账号设置里申请）。")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        visible: LastFm.enabled && LastFm.errorMessage.length > 0
                        wrapMode: Text.Wrap
                        text: LastFm.errorMessage
                        color: Appearance.colors.colError
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        visible: LastFm.enabled && LastFm.errorMessage.length === 0 && !LastFm.loading && LastFm.todayCount === 0
                        wrapMode: Text.Wrap
                        text: Translation.tr("今天还没有收听记录")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }

                    Rectangle { // 分隔线
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        visible: LastFm.topArtists.length > 0
                        implicitHeight: 1
                        color: ColorUtils.transparentize(Appearance.m3colors.m3outlineVariant, 0.6)
                    }

                    // Top 艺人 / Top 专辑
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        visible: LastFm.topArtists.length > 0
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 3
                            StyledText {
                                text: Translation.tr("常听艺人")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallest
                            }
                            Repeater {
                                model: LastFm.topArtists.slice(0, 3)
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: modelData.name
                                        color: Appearance.colors.colOnLayer2
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                    }
                                    StyledText {
                                        text: String(modelData.count)
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 3
                            StyledText {
                                text: Translation.tr("常听专辑")
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smallest
                            }
                            Repeater {
                                model: LastFm.topAlbums.slice(0, 3)
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    StyledText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: modelData.name.length > 0 ? modelData.name : Translation.tr("未知专辑")
                                        color: Appearance.colors.colOnLayer2
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                    }
                                    StyledText {
                                        text: String(modelData.count)
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── 封面墙（今日听过的专辑）─────────────────────────────────
            Rectangle {
                visible: LastFm.albumWall.length > 0
                Layout.fillWidth: true
                implicitHeight: wallColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: wallColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("今日专辑")
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: LastFm.albumWall.length + " " + Translation.tr("张")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: LastFm.albumWall.slice(0, 24)
                            delegate: Rectangle {
                                width: 52
                                height: 52
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colLayer1
                                clip: true

                                StyledImage {
                                    anchors.fill: parent
                                    source: modelData.cover
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                MouseArea { // 悬停时顶上来一行提示，不悬停不占地方
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                                StyledToolTip {
                                    visible: hoverArea.containsMouse
                                    text: modelData.artist + " · " + modelData.album
                                }
                            }
                        }
                    }
                }
            }

            // ── 重复播放 ───────────────────────────────────────────────
            Rectangle {
                visible: LastFm.repeats.length > 0
                Layout.fillWidth: true
                implicitHeight: repeatsColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: repeatsColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 5

                    StyledText {
                        text: Translation.tr("今天循环过的")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    Repeater {
                        model: LastFm.repeats
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: modelData.artist + " — " + modelData.title
                                color: Appearance.colors.colOnLayer2
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                            StyledText {
                                text: "×" + modelData.count
                                color: Appearance.colors.colPrimary
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

            // ── 今日列表（时间倒序）────────────────────────────────────
            Rectangle {
                visible: LastFm.recentTracks.length > 0
                Layout.fillWidth: true
                implicitHeight: timelineColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: timelineColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("今日记录")
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            visible: LastFm.recentTracks.length > pageRoot.timelineLimit
                            text: Translation.tr("只显示最近") + " " + pageRoot.timelineLimit + " " + Translation.tr("条")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    Repeater {
                        model: LastFm.recentTracks.slice(0, pageRoot.timelineLimit)
                        delegate: Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(rowText.implicitHeight, 20)

                            RowLayout {
                                id: rowText
                                anchors {
                                    fill: parent
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                spacing: 6

                                StyledText { // 正在播的那条没有时间（last.fm 不给 nowplaying 条目的 date）
                                    Layout.preferredWidth: 34
                                    text: modelData.isNow ? "▶" : modelData.time
                                    color: modelData.isNow ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    font {
                                        family: modelData.isNow ? Appearance.font.family.iconNerd : Appearance.font.family.numbers
                                        pixelSize: Appearance.font.pixelSize.smallest
                                        variableAxes: Appearance.font.variableAxes.numbers
                                    }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.artist + " — " + modelData.title
                                    color: Appearance.colors.colOnLayer2
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                }
                            }
                        }
                    }
                }
            }

            // ── 近 7 天 ────────────────────────────────────────────────
            Rectangle {
                visible: LastFm.weekArtists.length > 0
                Layout.fillWidth: true
                implicitHeight: weekColumn.implicitHeight + 2 * pageRoot.cardPadding
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: weekColumn
                    anchors.fill: parent
                    anchors.margins: pageRoot.cardPadding
                    spacing: 6

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
                            visible: LastFm.weekTotal > 0
                            text: LastFm.weekTotal + " " + Translation.tr("首")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }

                    Repeater {
                        model: LastFm.weekArtists
                        delegate: Item {
                            Layout.fillWidth: true
                            implicitHeight: 20

                            Rectangle { // 占比条（照 TypingStatsPage 的高频排行）
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: Math.max(3, Math.round(parent.width * modelData.count / (LastFm.weekArtists[0]?.count ?? 1)))
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
                                    elide: Text.ElideRight
                                    text: modelData.name
                                    color: Appearance.colors.colOnLayer2
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                }
                                StyledText {
                                    text: String(modelData.count)
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
        }
    }
}
