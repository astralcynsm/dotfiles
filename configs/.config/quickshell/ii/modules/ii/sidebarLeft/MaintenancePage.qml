import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// 左栏「系统维护」页（本地新增，非上游）。
//
// 数据全部来自 Maintenance 单例（它自己跑那几条只读查询），页面不跑任何命令。
//
// ⚠ 这一页**不执行任何会改动系统的动作** —— 只显示状态、把命令复制到剪贴板，
//   更新 / 清理都由用户自己去终端敲（要提权、且不可逆，不该由 UI 代劳）。
Item {
    id: pageRoot
    property real padding: 4
    readonly property int cardPadding: 12
    readonly property int cardSpacing: 10

    function num(v) {
        return v < 0 ? "—" : String(v);
    }

    function daysAgo(d) {
        if (d < 0) return "";
        if (d === 0) return Translation.tr("（今天）");
        if (d === 1) return Translation.tr("（昨天）");
        return Translation.tr("（%1 天前）").arg(d);
    }

    // ⚠ 这个页面在 ii 启动时就会被 createObject 出来（SidebarLeftContent 的
    // contentChildren 不是懒加载），但那时它多半**不可见** —— 所以别在
    // Component.onCompleted 里就去跑那几条命令（paru 那条要 4 秒，还联网）。
    // 初始就可见的情况（SwipView 停在那一页）才在 onCompleted 里补一次。
    Component.onCompleted: {
        if (visible)
            Maintenance.refresh();
    }
    onVisibleChanged: {
        if (visible)
            Maintenance.refresh();
    }

    // 卡片里那种「标题 + 右边一个值」的小行
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

    // 一栏大数字（「官方仓库 / 319 个」）
    component BigStat: ColumnLayout {
        id: bigStat
        property string label
        property int value
        property color accent: Appearance.colors.colPrimary
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            text: bigStat.label
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
        RowLayout {
            spacing: 3
            StyledText {
                text: pageRoot.num(bigStat.value)
                color: bigStat.accent
                font {
                    family: Appearance.font.family.numbers
                    pixelSize: 24
                    variableAxes: Appearance.font.variableAxes.numbers
                }
            }
            StyledText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 4
                text: Translation.tr("个")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest
            }
        }
    }

    // 「命令 + 复制按钮」。命令**只写剪贴板，不执行**。
    component CommandRow: RowLayout {
        id: cmdRow
        property string command
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cmdText.implicitHeight + 12
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer1

            StyledText {
                id: cmdText
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 6
                }
                text: cmdRow.command
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                font {
                    family: "monospace"
                    pixelSize: Appearance.font.pixelSize.smaller
                }
            }
        }

        RippleButton {
            implicitWidth: 30
            implicitHeight: 30
            buttonRadius: Appearance.rounding.small
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.78)
            colRipple: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
            downAction: () => {
                Quickshell.clipboardText = cmdRow.command;
            }
            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colPrimary
                text: "content_copy"
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

            // ── 更新 ───────────────────────────────────────────────────
            Card {
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("系统更新")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                    StyledText {
                        text: Maintenance.loading
                                ? Translation.tr("检查中…")
                                : (Maintenance.lastChecked.length > 0
                                   ? Translation.tr("最后检查 %1").arg(Maintenance.lastChecked) : "")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                    RippleButton {
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.small
                        colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                        colRipple: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
                        downAction: () => Maintenance.refresh(true)
                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colPrimary
                            text: "refresh"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 10

                    BigStat {
                        label: Translation.tr("官方仓库")
                        value: Maintenance.repoUpdates
                        accent: Maintenance.repoUpdates > 0 ? Appearance.colors.colPrimary
                                                            : Appearance.colors.colSubtext
                    }
                    BigStat {
                        label: Translation.tr("AUR")
                        value: Maintenance.aurUpdates
                        accent: Maintenance.aurUpdates > 0 ? Appearance.colors.colPrimary
                                                           : Appearance.colors.colSubtext
                    }
                }

                StatRow {
                    label: Translation.tr("上次系统升级")
                    value: Maintenance.lastUpgrade.length > 0
                           ? Maintenance.lastUpgrade + pageRoot.daysAgo(Maintenance.lastUpgradeDays)
                           : "—"
                }
            }

            // ── 包缓存 ─────────────────────────────────────────────────
            Card {
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("包缓存")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 6
                    StyledText {
                        text: Maintenance.cacheSize.length > 0 ? Maintenance.cacheSize : "—"
                        color: Appearance.colors.colPrimary
                        font {
                            family: Appearance.font.family.numbers
                            pixelSize: 24
                            variableAxes: Appearance.font.variableAxes.numbers
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 4
                        text: Translation.tr("/var/cache/pacman/pkg")
                        elide: Text.ElideRight
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }
                CommandRow {
                    command: "sudo paccache -rk1"
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("只保留最近 1 个版本；37G 这种体积多半是旧版本堆积")
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallest
                }
            }

            // ── 孤儿包 ─────────────────────────────────────────────────
            Card {
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("孤儿包")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                    StyledText {
                        text: Maintenance.orphanCount === 1
                              ? Translation.tr("1 个")
                              : pageRoot.num(Maintenance.orphanCount) + Translation.tr(" 个")
                        color: Maintenance.orphanCount > 0 ? Appearance.colors.colPrimary
                                                           : Appearance.colors.colSubtext
                        font {
                            family: Appearance.font.family.numbers
                            pixelSize: Appearance.font.pixelSize.smaller
                            variableAxes: Appearance.font.variableAxes.numbers
                        }
                    }
                }

                // 只列前几个 —— 全列出来会把卡片撑得很长
                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    visible: Maintenance.orphanNames.length > 0
                    spacing: 4

                    Repeater {
                        model: Maintenance.orphanNames
                        delegate: Rectangle {
                            implicitWidth: orphanName.implicitWidth + 12
                            implicitHeight: orphanName.implicitHeight + 5
                            radius: height / 2
                            color: Appearance.colors.colLayer1

                            StyledText {
                                id: orphanName
                                anchors.centerIn: parent
                                text: modelData
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.smallest
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: Maintenance.orphanCount > 0
                    text: Maintenance.orphanCount > Maintenance.orphanPreview
                          ? Translation.tr("等 %1 个（不再被任何包依赖）").arg(Maintenance.orphanCount)
                          : Translation.tr("不再被任何包依赖")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallest
                }

                CommandRow {
                    command: "sudo pacman -Rns $(pacman -Qtdq)"
                    visible: Maintenance.orphanCount > 0
                }
            }

            // ── 系统 ───────────────────────────────────────────────────
            Card {
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("系统")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
                StatRow {
                    label: Translation.tr("内核")
                    value: Maintenance.kernel.length > 0 ? Maintenance.kernel : "—"
                }
                StatRow {
                    label: Translation.tr("已安装的包")
                    value: pageRoot.num(Maintenance.installedCount)
                }
                StatRow {
                    visible: Maintenance.flatpakApps > 0
                    label: Translation.tr("Flatpak 应用")
                    value: pageRoot.num(Maintenance.flatpakApps)
                }
            }
        }
    }
}
