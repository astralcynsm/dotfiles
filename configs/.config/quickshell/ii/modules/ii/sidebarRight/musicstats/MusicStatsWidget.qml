import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 右栏「音乐」tab（本地新增，非上游）。
//
// 这个容器只有 ~350px 高（BottomWidgetGroup 写死的 implicitHeight），
// 所以只放概览：在播 + 今日曲数 + Top3 艺人 + Top3 专辑封面。
// 长列表（今日记录 / 封面墙 / 周榜）都在左栏的 MusicPage 里，别往这儿塞。
Item {
    id: root
    readonly property int pad: 10
    readonly property var player: MprisController.activePlayer
    readonly property var track: MprisController.activeTrack

    // 切到这个 tab 时 Loader 才把本组件建出来，所以这里刷一次就够；
    // LastFm 内部有 90 秒节流，重复调用不会真发请求。
    Component.onCompleted: LastFm.refresh()

    Timer { // 进度/在播状态靠定时器推（position 不是可通知属性）
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 6

        // ── 在播 ───────────────────────────────────────────────────────
        // 用「有没有标题」判断要不要显示，不用「有没有 player」：
        // D-Bus 上常驻着空壳播放器（playerctld、浏览器集成之类），
        // 那种 player 非 null 但没任何元数据，会让这一行白占 40px 的空白。
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: (root.track?.title ?? "").length > 0

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2
                clip: true

                StyledImage {
                    anchors.fill: parent
                    source: root.track?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: (root.track?.artUrl ?? "").length === 0
                    text: "music_note"
                    iconSize: 20
                    color: Appearance.colors.colSubtext
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.track?.title ?? ""
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.track?.artist ?? ""
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }

            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.rounding.small
                colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.78)
                colRipple: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
                downAction: () => root.player?.togglePlaying()
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.large
                    fill: 1
                    color: Appearance.colors.colPrimary
                    text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                }
            }
        }

        // ── 今日曲数 ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            StyledText {
                text: Translation.tr("今日")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            StyledText {
                text: LastFm.loading && LastFm.todayCount === 0 ? "—" : String(LastFm.todayCount)
                color: Appearance.colors.colPrimary
                font {
                    family: Appearance.font.family.numbers
                    pixelSize: 26
                    variableAxes: Appearance.font.variableAxes.numbers
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 5
                text: Translation.tr("首")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                visible: LastFm.updatedAt.length > 0
                text: LastFm.updatedAt
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest
            }
        }

        // 空态 / 错误（只占一行，别撑爆这个 350px 的容器）
        StyledText {
            Layout.fillWidth: true
            visible: !LastFm.enabled || LastFm.errorMessage.length > 0
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: !LastFm.enabled
                    ? (LastFm.configured ? Translation.tr("last.fm 已关闭") : Translation.tr("未配置 last.fm（设置 → 服务）"))
                    : LastFm.errorMessage
            color: LastFm.errorMessage.length > 0 ? Appearance.colors.colError : Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smallest
        }

        // ── Top3 专辑封面 ──────────────────────────────────────────────
        // 用 Row + 固定尺寸，不用 RowLayout 的 fillWidth/fillHeight：
        // 在 RowLayout 里写 `Layout.preferredHeight: width` 会得到一个被拉伸的
        // 大封面（width 在布局求解时不可靠），实测第一张能撑到 130px 高。
        Row {
            Layout.fillWidth: true
            visible: LastFm.topAlbums.length > 0
            spacing: 8

            Repeater {
                model: LastFm.topAlbums.slice(0, 3)
                delegate: Column {
                    id: coverCol
                    width: 64
                    spacing: 3

                    Rectangle {
                        width: 64
                        height: 64
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        clip: true

                        StyledImage {
                            anchors.fill: parent
                            source: modelData.cover
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: modelData.cover.length === 0
                            text: "album"
                            iconSize: 20
                            color: Appearance.colors.colSubtext
                        }
                    }
                    StyledText {
                        width: coverCol.width
                        elide: Text.ElideRight
                        text: modelData.name.length > 0 ? modelData.name : Translation.tr("未知专辑")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }
            }
        }

        // ── Top3 艺人 ──────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: LastFm.topArtists.length > 0
            spacing: 2

            Repeater {
                model: LastFm.topArtists.slice(0, 3)
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: modelData.name
                        color: Appearance.colors.colOnLayer1
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
