import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// bar 上字数统计的悬浮窗。仿 ResourcesPopup / ClockWidgetPopup / BatteryPopup。
//
// StyledPopup 是个 LazyLoader，装的是 PanelWindow（layer-shell 表面），
// hover 完全由 StyledPopup 自己的 `active: hoverTarget && hoverTarget.containsMouse` 管，
// 外面只要把 MouseArea 递进来就行。
//
// 别用 PopupToolTip（= Quickshell 的 PopupWindow + PopupAnchor）——它在
// Quickshell 0.2.1 有个必崩的雷，见 WordCountWidget.qml 里的说明。
StyledPopup {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        StyledPopupHeaderRow {
            icon: "edit_note"
            label: Translation.tr("Word count")
        }

        // tooltip 是 WordCount 里从 Pango 转过来的 Qt 富文本
        // （含柱状图和前 7 天的明细），这里直接整块渲染。
        StyledText {
            Layout.alignment: Qt.AlignLeft
            textFormat: Text.RichText
            text: WordCount.tooltip.length > 0 ? WordCount.tooltip : WordCount.text
        }
    }
}
