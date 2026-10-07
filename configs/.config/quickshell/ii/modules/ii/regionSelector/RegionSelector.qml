pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    function dismiss() {
        GlobalStates.regionSelectorOpen = false
    }

    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners

    // [2026-09-20] 只给「鼠标所在那块屏」建框选层（原来每块屏各建一个）。
    // 为什么：每块屏的框选层都要等自己那份 TempScreenshotProcess 抓图完成才 visible=true，
    // 而 eDP-1（2560x1440）比 HDMI-A-1（1920x1080）大一圈，抓帧 + 落盘明显更慢。
    // 于是出现「主屏已经能框选了，副屏还没弹出来」；一旦在主屏先完成框选，dismiss() 会先把
    // Loader 全销毁，而副屏那份晚到的 preparationDone 回调照样把 visible 置 true ——
    // 副屏就闪出一个框选层又被拆掉（即「闪退」，剪贴板里其实早就拿到结果了）。
    // 只建一块屏既根除这个竞态，也少抓一块屏的图，开得更快。
    // 选屏必须在 regionSelectorOpen 置 true 之前同步定好：Loader.active 是同步求值的，
    // 慢一拍就会先按旧屏建一次再重建（同一类竞态）。
    property var targetScreen: null

    function pickTargetScreen() {
        if (GlobalStates.regionSelectorOpen) return; // 已经开着 = 「再按一次」的路径（停止录制），不换屏
        // follow_mouse=1，所以 focused monitor 就是指针所在的那块屏
        const mon = Hyprland.focusedMonitor;
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (Hyprland.monitorFor(screens[i])?.id === mon?.id) {
                root.targetScreen = screens[i];
                return;
            }
        }
        root.targetScreen = screens.length > 0 ? screens[0] : null; // 兜底
    }

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData
            active: GlobalStates.regionSelectorOpen && (regionSelectorLoader.modelData === root.targetScreen)

            sourceComponent: RegionSelection {
                screen: regionSelectorLoader.modelData
                onDismiss: root.dismiss()
                action: root.action
                selectionMode: root.selectionMode
            }
        }
    }

    function screenshot() {
        root.pickTargetScreen()
        root.action = RegionSelection.SnipAction.Copy
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        GlobalStates.regionSelectorOpen = true
    }

    function search() {
        root.pickTargetScreen()
        root.action = RegionSelection.SnipAction.Search
        if (Config.options.search.imageSearch.useCircleSelection) {
            root.selectionMode = RegionSelection.SelectionMode.Circle
        } else {
            root.selectionMode = RegionSelection.SelectionMode.RectCorners
        }
        GlobalStates.regionSelectorOpen = true
    }

    function ocr() {
        root.pickTargetScreen()
        root.action = RegionSelection.SnipAction.CharRecognition
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        GlobalStates.regionSelectorOpen = true
    }

    function record() {
        root.pickTargetScreen()
        root.action = RegionSelection.SnipAction.Record
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        // If already open then re-trigger to stop recording
        if (GlobalStates.regionSelectorOpen) GlobalStates.regionSelectorOpen = false
        GlobalStates.regionSelectorOpen = true
    }

    function recordWithSound() {
        root.pickTargetScreen()
        root.action = RegionSelection.SnipAction.RecordWithSound
        root.selectionMode = RegionSelection.SelectionMode.RectCorners
        // If already open then re-trigger to stop recording
        if (GlobalStates.regionSelectorOpen) GlobalStates.regionSelectorOpen = false
        GlobalStates.regionSelectorOpen = true
    }

    IpcHandler {
        target: "region"

        function screenshot() {
            root.screenshot()
        }
        function search() {
            root.search()
        }
        function ocr() {
            root.ocr()
        }
        function record() {
            root.record()
        }
        function recordWithSound() {
            root.recordWithSound()
        }
    }

    GlobalShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: root.screenshot()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: root.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: root.ocr()
    }
    GlobalShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: root.record()
    }
    GlobalShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: root.recordWithSound()
    }
}
