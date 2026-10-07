import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool typingStatsEnabled: Config.options.sidebar.typingStats.enable
    property bool systemMonitorEnabled: Config.options.sidebar.systemMonitor.enable
    property bool musicEnabled: Config.options.sidebar.music.enable
    property bool maintenanceEnabled: Config.options.sidebar.maintenance.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property var tabButtonList: [
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...(root.typingStatsEnabled ? [{"icon": "keyboard", "name": Translation.tr("字数")}] : []),
        ...(root.systemMonitorEnabled ? [{"icon": "monitor_heart", "name": Translation.tr("监控")}] : []),
        ...(root.musicEnabled ? [{"icon": "music_note", "name": Translation.tr("音乐")}] : []),
        ...(root.maintenanceEnabled ? [{"icon": "build", "name": Translation.tr("维护")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property int tabCount: swipeView.count

    // 页面实例缓存（本地改动，非上游）。
    //
    // contentChildren 是个绑定，它一变就会重新求值；每次求值都 createObject()
    // 会造出没人引用的重复页面 —— 旧实例还活着（JS 那边没释放），它们内部所有
    // 引用页面根 id 的绑定会在「页面根 id 已失效」的状态下求值，刷出一屏
    // `TypeError: Cannot read property 'x' of null`（实测一次启动泄漏 6 个页面、
    // 单页刷 1855×N 条日志，上游 AiChat.qml 也有同样症状）。
    // 缓存之后重复求值拿到的还是同一批对象。
    property var pageCache: ({})
    function cachedPage(key, component) {
        if (!root.pageCache[key])
            root.pageCache[key] = component.createObject();
        return root.pageCache[key];
    }

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Toolbar {
            visible: tabButtonList.length > 0
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                contentChildren: [
                    ...(root.aiChatEnabled ? [root.cachedPage("aiChat", aiChat)] : []),
                    ...(root.translatorEnabled ? [root.cachedPage("translator", translator)] : []),
                    ...(root.typingStatsEnabled ? [root.cachedPage("typingStats", typingStats)] : []),
                    ...(root.systemMonitorEnabled ? [root.cachedPage("systemMonitor", systemMonitor)] : []),
                    ...(root.musicEnabled ? [root.cachedPage("music", music)] : []),
                    ...(root.maintenanceEnabled ? [root.cachedPage("maintenance", maintenance)] : []),
                    // 占位页：没有页签时才出现（tabButtonList 为空 ⇔ 下面这个条件）。
                    // 本地改动：原来写的是 tabButtonList.length === 0，那会让这个
                    // 绑定依赖 Translation.tr（页签名要翻译），启动时语言一切换就
                    // 重新求值 → 页面实例泄漏。展开成纯 Config 条件后依赖只剩配置。
                    // ⚠ 加新页时这个条件也要跟着加一个 !root.xxxEnabled，否则
                    //   占位页会和真页面同时出现。
                    ...((!root.aiChatEnabled && !root.translatorEnabled && !root.typingStatsEnabled && !root.systemMonitorEnabled && !root.musicEnabled && !root.maintenanceEnabled && (!root.animeEnabled || root.animeCloset)) ? [root.cachedPage("placeholder", placeholder)] : []),
                    ...(root.animeEnabled ? [root.cachedPage("anime", anime)] : []),
                ]
            }
        }

        Component {
            id: aiChat
            AiChat {}
        }
        Component {
            id: translator
            Translator {}
        }
        Component {
            id: typingStats
            TypingStatsPage {}
        }
        Component {
            id: systemMonitor
            SystemMonitorPage {}
        }
        Component {
            id: music
            MusicPage {}
        }
        Component {
            id: maintenance
            MaintenancePage {}
        }
        Component {
            id: anime
            Anime {}
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}