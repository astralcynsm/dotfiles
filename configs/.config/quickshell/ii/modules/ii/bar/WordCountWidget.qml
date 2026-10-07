import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets
import qs.services

// bar 上的输入法字数。数据源见 services/WordCount.qml。
Item {
    id: root

    // 数据还没读到过就先不占位置（daemon 没跑时不留一个空摆设）
    readonly property bool shown: (Config?.options?.bar?.wordCount?.enable ?? false) && WordCount.available

    implicitWidth: shown ? row.implicitWidth + 10 : 0
    implicitHeight: Appearance.sizes.barHeight
    visible: shown

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: "edit_note"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colPrimary
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            text: WordCount.text
        }
    }

    // 悬浮窗的写法照抄 bar 上时钟 / 资源 / 电池那几个（Resources.qml:50）：
    // MouseArea + StyledPopup，hover 判定交给 StyledPopup 内部。
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        WordCountPopup {
            hoverTarget: mouseArea
        }
    }
}
