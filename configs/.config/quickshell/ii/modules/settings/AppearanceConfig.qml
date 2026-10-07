import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// 本地新增：外观自定义页。
//
// 这一页是「外观参数化」的界面层 —— 所有值本来全部硬编码在 Appearance.qml 里，
// 用户只能改代码；现在它们都在 Config.options.appearance 下，这一页只是把那些键露出来。
//
// 设计约定（跟其它设置页一致）：
//   · 每个控件写成 `value: Config...` 绑定 + `onXChanged: Config... = x` 写回。
//     上游所有设置页都是这个模式 —— 拖动时绑定会被 QML 引擎打断（滑块给自己赋值），
//     但设置页里用户就是唯一的改变者，所以够用；每次打开设置页都是新实例、绑定是新的。
//   · 缩放类参数一律在界面里用 ×100 的整数（85 ~ 120），存回 Config 时再 /100。
//     原因：StyledSlider 的 tooltip 会对 value 做 Math.round，直接存小数会显示成
//     「滑轨位置的百分比」而不是「缩放百分比」，看着莫名其妙。
//   · 新字符串没有 zh_CN 翻译（本机 translations/zh_CN.json 并不存在，整个 ii 都是英文原文），
//     所以这里也照常写 Translation.tr(...)，保持与其它页一致。

ContentPage {
    forceWidth: true

    // ── 预置风格 ────────────────────────────────────────────────────────
    // preset 不是「模式」，只是一组值的快照 —— 套完下面的滑块仍可随便调。
    // 列表来自 ~/.config/illogical-impulse/appearance-presets/ 里的 *.json，
    // 文件名（去后缀）就是这里显示的名字。自己往那个目录丢 JSON 就能加。
    ContentSection {
        icon: "auto_awesome"
        title: Translation.tr("Presets")

        ConfigSelectionArray {
            currentValue: AppearancePresets.lastAppliedName
            options: AppearancePresets.presetNames.map(n => ({
                displayName: n,
                icon: "palette",
                value: n
            }))
            onSelected: (newValue) => {
                AppearancePresets.applyPreset(newValue);
            }
        }

        // 目录为空 / JSON 写错 / 文件读不到时在这里说清楚，而不是静默什么都不发生
        StyledText {
            visible: AppearancePresets.lastError.length > 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.m3colors.m3error
            text: AppearancePresets.lastError
        }
    }

    // ── 圆角 ────────────────────────────────────────────────────────────
    ContentSection {
        icon: "rounded_corner"
        title: Translation.tr("Rounding")

        // 总开关式的一个滑块：拖一下所有装饰性圆角一起变。
        // 0 = 全方角（DS / 工业风），100 = 上游默认，200 = 很圆。
        ConfigSlider {
            text: Translation.tr("Global multiplier (%)")
            buttonIcon: "aspect_ratio"
            value: Config.options.appearance.rounding.scale * 100
            usePercentTooltip: false
            from: 0
            to: 200
            stopIndicatorValues: [100]
            onValueChanged: {
                Config.options.appearance.rounding.scale = value / 100;
            }
        }

        // ⚠ 下面这个不是装饰性圆角，别调成 0：它管的是「圆形/胶囊」语义
        //   （头像遮罩、开关轨道、滑块手柄、徽章）。0 会让头像变方块、开关变方轨。
        //   用 SpinBox 而不是滑块：默认值 9999 远超任何滑轨范围，做成滑块会永远顶在右端，
        //   显示的值跟真实值对不上，比不做还糟。
        ConfigSpinBox {
            icon: "circle"
            text: Translation.tr("Capsule radius (9999 = perfect circle)")
            value: Config.options.appearance.rounding.full
            from: 0
            to: 9999
            stepSize: 1
            onValueChanged: {
                Config.options.appearance.rounding.full = value;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "looks_one"
                text: Translation.tr("Small")
                value: Config.options.appearance.rounding.small
                from: 0
                to: 60
                onValueChanged: {
                    Config.options.appearance.rounding.small = value;
                }
            }
            ConfigSpinBox {
                icon: "looks_two"
                text: Translation.tr("Normal")
                value: Config.options.appearance.rounding.normal
                from: 0
                to: 60
                onValueChanged: {
                    Config.options.appearance.rounding.normal = value;
                }
            }
            ConfigSpinBox {
                icon: "looks_3"
                text: Translation.tr("Large")
                value: Config.options.appearance.rounding.large
                from: 0
                to: 80
                onValueChanged: {
                    Config.options.appearance.rounding.large = value;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "rounded_corner"
                text: Translation.tr("Very small")
                value: Config.options.appearance.rounding.verysmall
                from: 0
                to: 40
                onValueChanged: {
                    Config.options.appearance.rounding.verysmall = value;
                }
            }
            ConfigSpinBox {
                icon: "rounded_corner"
                text: Translation.tr("Very large")
                value: Config.options.appearance.rounding.verylarge
                from: 0
                to: 80
                onValueChanged: {
                    Config.options.appearance.rounding.verylarge = value;
                }
            }
            ConfigSpinBox {
                icon: "window"
                text: Translation.tr("Window")
                value: Config.options.appearance.rounding.windowRounding
                from: 0
                to: 60
                onValueChanged: {
                    Config.options.appearance.rounding.windowRounding = value;
                }
            }
        }
    }

    // ── 字号与密度 ──────────────────────────────────────────────────────
    ContentSection {
        icon: "format_size"
        title: Translation.tr("Font size & density")

        ConfigSlider {
            text: Translation.tr("Global scale (%)")
            buttonIcon: "format_size"
            value: Config.options.appearance.fontSize.scale * 100
            usePercentTooltip: false
            from: 80
            to: 130
            stopIndicatorValues: [100]
            onValueChanged: {
                Config.options.appearance.fontSize.scale = value / 100;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Smallest")
                value: Config.options.appearance.fontSize.smallest
                from: 6
                to: 30
                onValueChanged: {
                    Config.options.appearance.fontSize.smallest = value;
                }
            }
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Smaller")
                value: Config.options.appearance.fontSize.smaller
                from: 6
                to: 30
                onValueChanged: {
                    Config.options.appearance.fontSize.smaller = value;
                }
            }
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Smallie")
                value: Config.options.appearance.fontSize.smallie
                from: 6
                to: 30
                onValueChanged: {
                    Config.options.appearance.fontSize.smallie = value;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Small")
                value: Config.options.appearance.fontSize.small
                from: 8
                to: 32
                onValueChanged: {
                    Config.options.appearance.fontSize.small = value;
                }
            }
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Normal")
                value: Config.options.appearance.fontSize.normal
                from: 8
                to: 32
                onValueChanged: {
                    Config.options.appearance.fontSize.normal = value;
                }
            }
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Large")
                value: Config.options.appearance.fontSize.large
                from: 8
                to: 36
                onValueChanged: {
                    Config.options.appearance.fontSize.large = value;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Larger")
                value: Config.options.appearance.fontSize.larger
                from: 8
                to: 40
                onValueChanged: {
                    Config.options.appearance.fontSize.larger = value;
                }
            }
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Huge")
                value: Config.options.appearance.fontSize.huge
                from: 10
                to: 48
                onValueChanged: {
                    Config.options.appearance.fontSize.huge = value;
                }
            }
            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Hugeass")
                value: Config.options.appearance.fontSize.hugeass
                from: 10
                to: 48
                onValueChanged: {
                    Config.options.appearance.fontSize.hugeass = value;
                }
            }
        }
    }

    // ── 面板尺寸（排版）──────────────────────────────────────────────────
    ContentSection {
        icon: "aspect_ratio"
        title: Translation.tr("Panel sizes")

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "side_navigation"
                text: Translation.tr("Sidebar width")
                value: Config.options.appearance.sizes.sidebarWidth
                from: 280
                to: 900
                stepSize: 10
                onValueChanged: {
                    Config.options.appearance.sizes.sidebarWidth = value;
                }
            }
            ConfigSpinBox {
                icon: "side_navigation"
                text: Translation.tr("Sidebar extended")
                value: Config.options.appearance.sizes.sidebarWidthExtended
                from: 400
                to: 1200
                stepSize: 10
                onValueChanged: {
                    Config.options.appearance.sizes.sidebarWidthExtended = value;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "notifications"
                text: Translation.tr("Notification popup")
                value: Config.options.appearance.sizes.notificationPopupWidth
                from: 240
                to: 700
                stepSize: 10
                onValueChanged: {
                    Config.options.appearance.sizes.notificationPopupWidth = value;
                }
            }
            ConfigSpinBox {
                icon: "volume_up"
                text: Translation.tr("OSD width")
                value: Config.options.appearance.sizes.osdWidth
                from: 100
                to: 400
                stepSize: 5
                onValueChanged: {
                    Config.options.appearance.sizes.osdWidth = value;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "music_note"
                text: Translation.tr("Media controls width")
                value: Config.options.appearance.sizes.mediaControlsWidth
                from: 240
                to: 800
                stepSize: 10
                onValueChanged: {
                    Config.options.appearance.sizes.mediaControlsWidth = value;
                }
            }
            ConfigSpinBox {
                icon: "music_note"
                text: Translation.tr("Media controls height")
                value: Config.options.appearance.sizes.mediaControlsHeight
                from: 80
                to: 400
                stepSize: 10
                onValueChanged: {
                    Config.options.appearance.sizes.mediaControlsHeight = value;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "search"
                text: Translation.tr("Search width")
                value: Config.options.appearance.sizes.searchWidth
                from: 200
                to: 700
                stepSize: 10
                onValueChanged: {
                    Config.options.appearance.sizes.searchWidth = value;
                }
            }
            ConfigSpinBox {
                icon: "expand"
                text: Translation.tr("Elevation margin")
                value: Config.options.appearance.sizes.elevationMargin
                from: 0
                to: 40
                onValueChanged: {
                    Config.options.appearance.sizes.elevationMargin = value;
                }
            }
        }

        // ⚠ 这个值应当等于 Hyprland 的 gaps_out（~/.config/hypr/UserConfigs/UserDecorations.lua）。
        //   它只在 bar 开 Float（cornerStyle = 1）时起作用，用来让悬浮 bar 与窗口边缘对齐。
        ConfigSpinBox {
            icon: "space_dashboard"
            text: Translation.tr("Bar gaps out (match Hyprland gaps_out)")
            value: Config.options.appearance.sizes.barGapsOut
            from: 0
            to: 30
            onValueChanged: {
                Config.options.appearance.sizes.barGapsOut = value;
            }
        }
    }

    // ── 动画手感 ────────────────────────────────────────────────────────
    ContentSection {
        icon: "animation"
        title: Translation.tr("Animation feel")

        // ⚠ 别低于 40%：入场/出场/尺寸变化这几组带 alwaysRunToEnd（动画必须跑完），
        //   倍率太小会让它们比动画本身还慢，界面显得黏。
        ConfigSlider {
            text: Translation.tr("Duration scale (%)")
            buttonIcon: "speed"
            value: Config.options.appearance.animation.scale * 100
            usePercentTooltip: false
            from: 0
            to: 200
            stopIndicatorValues: [100]
            onValueChanged: {
                Config.options.appearance.animation.scale = value / 100;
            }
        }

        ConfigSelectionArray {
            currentValue: Config.options.appearance.animation.curveStyle
            options: [
                {
                    displayName: Translation.tr("Expressive"),
                    icon: "celebration",
                    value: "expressive"
                },
                {
                    displayName: Translation.tr("Standard"),
                    icon: "straighten",
                    value: "standard"
                },
                {
                    displayName: Translation.tr("Linear"),
                    icon: "trending_flat",
                    value: "linear"
                },
            ]
            onSelected: (newValue) => {
                Config.options.appearance.animation.curveStyle = newValue;
            }
        }
    }

    // ── 图标与材质 ──────────────────────────────────────────────────────
    ContentSection {
        icon: "palette"
        title: Translation.tr("Icons & material")

        // 只影响「没显式表态」的图标。开关的 toggled 这类语义性填充不受影响。
        ConfigSwitch {
            buttonIcon: "format_color_fill"
            text: Translation.tr("Filled icons")
            checked: Config.options.appearance.iconFillAll
            onCheckedChanged: {
                Config.options.appearance.iconFillAll = checked;
            }
        }

        // 面板边框一直画着，只是颜色淡到看不见；打开这个会让它显出来（配合半透明效果最好）。
        ConfigSwitch {
            buttonIcon: "border_outer"
            text: Translation.tr("Panel outlines")
            checked: Config.options.appearance.panelOutline
            onCheckedChanged: {
                Config.options.appearance.panelOutline = checked;
            }
        }

        ConfigSlider {
            text: Translation.tr("Letter spacing (×0.1px)")
            buttonIcon: "format_letter_spacing"
            value: Config.options.appearance.letterSpacing * 10
            usePercentTooltip: false
            from: 0
            to: 20
            stopIndicatorValues: [0]
            onValueChanged: {
                Config.options.appearance.letterSpacing = value / 10;
            }
        }
    }
}
