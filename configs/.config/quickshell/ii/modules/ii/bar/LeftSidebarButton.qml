import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    property bool showPing: false

    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    visible: aiChatEnabled || translatorEnabled || animeEnabled

    property real buttonPadding: 5
    implicitWidth: distroIcon.width + buttonPadding * 2
    implicitHeight: distroIcon.height + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarLeftOpen

    onPressed: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    Connections {
        target: Ai
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            root.showPing = true;
        }
    }

    Connections {
        target: Booru
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            root.showPing = true;
        }
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            root.showPing = false;
        }
    }

    // 图标本体：SVG（CustomIcon）或自定义 nerd font 字形，二选一。
    // bar.topLeftIconGlyph 非空时字形优先，忽略 topLeftIcon。
    // ⚠ 解析规则与设置页 modules/settings/BarConfig.qml 的「Top-left icon」一节必须一致，改一处记得改另一处。
    Item {
        id: distroIcon
        anchors.centerIn: parent
        width: 19.5
        height: 19.5

        readonly property string glyph: Config.options.bar.topLeftIconGlyph ?? ""
        readonly property string iconName: Config.options.bar.topLeftIcon ?? "spark"
        readonly property string imageSource: {
            if (distroIcon.iconName === "distro") return SystemInfo.distroIcon;
            if (distroIcon.iconName.startsWith("/")) return distroIcon.iconName; // 自备 SVG 的绝对路径
            return `${distroIcon.iconName}-symbolic`;
        }
        readonly property bool isAbsolutePath: distroIcon.imageSource.startsWith("/")

        CustomIcon {
            anchors.fill: parent
            visible: distroIcon.glyph.length === 0
            source: distroIcon.imageSource
            // CustomIcon 会把 source 无条件拼到 iconFolder 后面 → 绝对路径时得把 iconFolder 清空，
            // 否则路径变成 <assets/icons>/<绝对路径>。空字符串在 CustomIcon 里是 falsy，会原样使用 source。
            iconFolder: distroIcon.isAbsolutePath ? "" : Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))
            colorize: true
            color: Appearance.colors.colOnLayer0
        }

        StyledText {
            anchors.centerIn: parent
            visible: distroIcon.glyph.length > 0
            text: distroIcon.glyph
            font.family: Appearance.font.family.iconNerd
            font.pixelSize: Math.round(distroIcon.height * 1.15)
            color: Appearance.colors.colOnLayer0
        }

        Rectangle {
            opacity: root.showPing ? 1 : 0
            visible: opacity > 0
            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: -2
                rightMargin: -2
            }
            implicitWidth: 8
            implicitHeight: 8
            radius: Appearance.rounding.full
            color: Appearance.colors.colTertiary

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
