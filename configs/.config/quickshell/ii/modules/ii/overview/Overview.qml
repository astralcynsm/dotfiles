import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false

    PanelWindow {
        id: panelWindow
        property string searchingText: ""
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
        // [2026-09-20] 窗口可见性只由 panelMapped 驱动，不再直接绑 overviewOpen。
        // 为什么：overviewOpen 一变成 false，这条绑定会「当场」求值成 false，
        // 而 onOverviewOpenChanged 处理器要晚几毫秒才跑（日志实测 4ms），
        // 中间这几毫秒窗口是真的解了映射；等处理器里 exitAnimRunning=true 再映射回来，
        // 屏幕上就成了「面板一刀切消失 → 搜索框单独闪回来 → 再淡出」。
        // （重映射要 40~75ms，那会儿 OverviewWidget 已经销毁、淡出动画还没跑第一帧。）
        // 现在退场不碰 panelMapped，窗口从头到尾一次映射到底。
        // 必须写限定名 panelWindow.panelMapped：visible 是 QQuickItem 基类属性，
        // 它的绑定在对象构造极早期就被求值，那时本对象自定义的属性表还没建好，
        // 非限定引用会触发 "panelMapped is not defined"。
        property bool panelMapped: false
        visible: panelWindow.panelMapped

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Top
        // [2026-09-20] OnDemand → Exclusive：面板开着时键盘归它独占。
        // 实测（250ms 打点 + 注入按键）：OnDemand 下面板确实能拿到键盘（注入 Escape 会被面板吃掉），
        // 但那是「谁请求谁得」—— 别的窗口一被聚焦，键盘就跟着走。Exclusive 是协议级独占：
        // 图层映射的那一瞬间就拿下键盘，别的表面拿不到，所以刚进面板的第一个字符也不会漏给下面的窗口。
        // ii 自己在 Overlay.qml / SessionScreen.qml 里就是这么用的。
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.overviewOpen ? columnLayout : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    searchWidget.disableExpandAnimation();
                    overviewScope.dontAutoCancelSearch = false;
                    GlobalFocusGrab.dismiss();
                    panelWindow.exitAnimRunning = true;
                    exitAnimTimer.restart();
                } else {
                    panelWindow.panelMapped = true; // 进场：先把窗口映射出来
                    panelWindow.exitAnimRunning = false;
                    exitAnimTimer.stop();
                    if (!overviewScope.dontAutoCancelSearch) {
                        searchWidget.cancelSearch();
                    }
                    // [2026-09-20] 这里原来有一句 GlobalFocusGrab.addDismissable(panelWindow)，删掉。
                    // 它让面板靠 HyprlandFocusGrab 的 onCleared → dismiss() 来关闭，而 onCleared
                    // 的触发条件只是「焦点离开了这些窗口」：任何别的窗口一拿到焦点，面板就被自己关掉。
                    // 实测：面板开着时 hyprctl dispatch "hl.dsp.window.cycle_next()" 切一下窗口，
                    // 面板立刻 overviewOpen -> false。follow_mouse=1 下指针移到别的窗口上换焦点，
                    // 走的是同一条路 —— 用户感受就是「面板被 foot 抢过去」。
                    // 而逐 250ms 打点证明面板从没丢过键盘焦点（每次都是 true 一直到被关掉），
                    // 所以问题不在键盘、在这条多余的自动关闭。
                    // 现在面板只被明确的动作关掉：Esc、你自己的开关键（GlobalShortcut 实测在面板
                    // 开着时照样生效，Alt+Space 一按就关）、选中条目（OverviewWidget 自己会关）、IPC。
                    // 其它面板（侧边栏/媒体控制/壁纸选择器）没动，还是原来的点击即关。
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        function setSearchingText(text) {
            searchWidget.setSearchingText(text);
            searchWidget.focusFirstItem();
        }

        // [2026-09-20] 进出场动画。原先 visible 是布尔硬切，面板「蹦」出来毫无过渡。
        // 直接作用在 columnLayout 上（不加包裹层，改动面最小）：淡入 + 从 96% 轻微放大，
        // 锚点在顶部中心（transformOrigin: Item.Top），所以是从搜索栏那儿往下展开。
        // 时长压到 170ms —— ii 默认的 elementMoveEnter 是 400ms，对「面板出现」太拖；
        // 曲线仍沿用 ii 自己的 emphasizedDecel，跟 bar / 侧边栏手感统一。
        // 退场期间用来「续命」的两个标记：
        //   exitAnimRunning —— 想表达「正在退场」，不再参与 visible（见上面的 panelMapped）
        //   panelMapped     —— 窗口/内容的实际映射状态，只在进场和退场动画结束时翻转
        // Timer 200ms 要略长于动画 170ms。
        property bool exitAnimRunning: false

        Timer {
            id: exitAnimTimer
            interval: 200
            onTriggered: {
                panelWindow.exitAnimRunning = false;
                panelWindow.panelMapped = false; // 退场动画播完，这才真正解映射
            }
        }

        Column {
            id: columnLayout
            // 跟窗口共用同一份状态：内容也别在 overviewOpen 翻转的那一瞬间闪一下
            visible: panelWindow.panelMapped
            opacity: GlobalStates.overviewOpen ? 1 : 0
            scale: GlobalStates.overviewOpen ? 1 : 0.96
            transformOrigin: Item.Top

            // Behavior.animation 是「一次性」属性：首次赋值后就不能再换对象。
            // 所以别写 createObject(...) 那种每次返回新对象的绑定 —— 会刷
            // "Cannot change the animation assigned to a Behavior" 警告，
            // 而且实际生效的永远是初始化时那一个。用内联写法，
            // 这也正是 ii 自己在 SearchBar.qml 里的写法。
            Behavior on opacity {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            spacing: -8

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.overviewOpen = false;
                }
            }

            SearchWidget {
                id: searchWidget
                anchors.horizontalCenter: parent.horizontalCenter
                Synchronizer on searchingText {
                    property alias source: panelWindow.searchingText
                }
            }

            Loader {
                id: overviewLoader
                anchors.horizontalCenter: parent.horizontalCenter
                active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true)
                sourceComponent: OverviewWidget {
                    screen: panelWindow.screen
                    visible: (panelWindow.searchingText == "")
                }
            }
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"

        onPressed: {
            GlobalStates.overviewOpen = false;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }
}
