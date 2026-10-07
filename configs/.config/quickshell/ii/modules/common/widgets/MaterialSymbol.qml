import qs.modules.common
import QtQuick

StyledText {
    id: root
    property real iconSize: Appearance?.font.pixelSize.small ?? 16
    // 本地改：原来是 `property real fill: 0`。现在拿 -1 当哨兵 ——
    //   fill < 0  → 跟随全局开关 Appearance.iconFillAll
    //   fill >= 0 → 调用点显式指定（全仓库 32 处，主要是开关的 toggled 这类语义性填充）
    // 这样「一键全站图标变实心」只影响没表态的图标，不会破坏已有的条件式填充。
    property real fill: -1
    property real truncatedFill: (fill < 0 ? (Appearance?.iconFillAll ? 1 : 0) : fill).toFixed(1) // Reduce memory consumption spikes from constant font remapping
    renderType: Text.NativeRendering
    font {
        hintingPreference: Font.PreferNoHinting
        family: Appearance?.font.family.iconMaterial ?? "Material Symbols Rounded"
        pixelSize: iconSize
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * truncatedFill
        // 图标不吃全局字距（父组件 StyledText 会加），否则固定尺寸的图标会被撑宽/截断。
        letterSpacing: 0
        variableAxes: {
            "FILL": truncatedFill,
            // "wght": font.weight,
            // "GRAD": 0,
            "opsz": iconSize,
        }
    }

    // 本地改：原来监听 fill。改成 truncatedFill 是为了让**全局开关**的切换也有动画 ——
    // 哨兵模式下 iconFillAll 变化时 fill 本身不动（恒为 -1），只有 truncatedFill 会变。
    Behavior on truncatedFill { // Leaky leaky, no good
        NumberAnimation {
            duration: Appearance?.animation.elementMoveFast.duration ?? 200
            easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
            easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }
}
