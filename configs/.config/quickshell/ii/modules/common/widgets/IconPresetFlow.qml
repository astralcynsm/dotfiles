import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * 图标预设选择器（本地新增文件，非上游）。
 *
 * 一排圆角方块，每块显示一个 SVG 图标或一个字形（nerd font），点一下把 (kind, value) 发出去。
 * 用在设置界面里让用户挑图标 —— 见 modules/settings/BarConfig.qml 的「Top-left icon」一节。
 *
 * presets: [
 *   { "kind": "image", "value": "spark", "source": "spark-symbolic" },  // source 由调用方拼好
 *   { "kind": "glyph", "value": "󰀲" }
 * ]
 *   - kind="image"：source 是 IconImage 能吃的路径（assets/icons 下的相对名，或绝对路径）
 *   - kind="glyph"：value 就是字形本身，用 appearance.fonts.iconNerd 渲染
 *
 * currentKind / currentValue 与哪一项匹配就高亮哪一项；都不匹配（比如用户手填了别的值）就没有高亮。
 */
Flow {
    id: root
    Layout.fillWidth: true
    spacing: 4

    property var presets: []
    property string currentKind: ""
    property string currentValue: ""
    property real buttonSize: 34
    property real iconSize: 20

    signal picked(string kind, string value)

    Repeater {
        model: root.presets

        delegate: RippleButton {
            id: presetButton
            required property var modelData
            required property int index

            readonly property bool selected: (root.currentKind === modelData.kind)
                                             && (root.currentValue === (modelData.value ?? ""))
            readonly property color iconColor: presetButton.selected
                ? Appearance.colors.colOnSecondaryContainer
                : Appearance.colors.colOnLayer1

            implicitWidth: root.buttonSize
            implicitHeight: root.buttonSize
            buttonRadius: Appearance.rounding.small
            toggled: presetButton.selected
            colBackground: Appearance.colors.colLayer2
            colBackgroundHover: Appearance.colors.colLayer2Hover
            colBackgroundToggled: Appearance.colors.colSecondaryContainer
            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colLayer2Active
            colRippleToggled: Appearance.colors.colSecondaryContainerActive

            onClicked: root.picked(modelData.kind, modelData.value ?? "")

            StyledToolTip {
                // 字形本身的 tooltip 会用主题正文字体渲染（PUA 可能显示成豆腐），所以优先用 name
                text: presetButton.modelData.name ?? presetButton.modelData.value ?? ""
            }

            CustomIcon {
                anchors.centerIn: parent
                visible: presetButton.modelData.kind === "image"
                width: root.iconSize
                height: root.iconSize
                source: presetButton.modelData.source ?? ""
                colorize: true
                color: presetButton.iconColor
            }

            StyledText {
                anchors.centerIn: parent
                visible: presetButton.modelData.kind === "glyph"
                text: presetButton.modelData.value ?? ""
                font.family: Appearance.font.family.iconNerd
                font.pixelSize: root.iconSize
                color: presetButton.iconColor
            }
        }
    }
}
