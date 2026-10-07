import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: pageRoot
    forceWidth: true

    // ── 左上角图标（本地新增，非上游）────────────────────────────────────────
    // bar.topLeftIcon      ：图片名（assets/icons 下的名字）/ "distro"（自动识别发行版）/ SVG 绝对路径
    // bar.topLeftIconGlyph ：非空则改用 nerd font 字形（appearance.fonts.iconNerd），并盖过 topLeftIcon
    // ⚠ 解析规则与 modules/ii/bar/LeftSidebarButton.qml 的 imageSource 必须一致，改一处记得改另一处。
    readonly property string topLeftIconName: Config.options.bar.topLeftIcon ?? "spark"
    readonly property string topLeftIconGlyph: Config.options.bar.topLeftIconGlyph ?? ""
    readonly property bool usingGlyph: pageRoot.topLeftIconGlyph.length > 0
    readonly property string topLeftImageSource: pageRoot.resolveIconSource(pageRoot.topLeftIconName)
    readonly property bool topLeftIsAbsolute: pageRoot.topLeftImageSource.startsWith("/")
    readonly property string topLeftGlyphLabel: {
        const glyph = pageRoot.topLeftIconGlyph;
        if (glyph.length === 0) return "";
        return Array.from(glyph).map(c => {
            const hex = c.codePointAt(0).toString(16).toUpperCase();
            return "U+" + ("000" + hex).slice(-4);
        }).join(" ");
    }

    function resolveIconSource(name) {
        if (!name || name.length === 0) return "spark-symbolic";
        if (name === "distro") return SystemInfo.distroIcon;
        if (name.startsWith("/")) return name;
        return `${name}-symbolic`;
    }

    function pickTopLeftIcon(kind, value) {
        if (kind === "glyph") {
            Config.options.bar.topLeftIconGlyph = value;
            glyphField.text = value;
        } else {
            Config.options.bar.topLeftIconGlyph = ""; // 不清掉的话字形会一直盖住图片
            Config.options.bar.topLeftIcon = value;
            glyphField.text = "";
            iconField.text = value;
        }
    }

    // 图片 preset（assets/icons 下的 SVG）
    readonly property var topLeftImagePresets: [
        "spark", "google-gemini", "openai", "deepseek", "mistral", "ollama", "openrouter",
        "distro", "endeavouros", "arch", "cachyos", "nixos", "fedora", "debian", "ubuntu", "gentoo", "manjaro", "linux",
        "github", "desktop", "crosshair", "flatpak", "nyarch"
    ].map(n => ({ kind: "image", value: n, name: n, source: pageRoot.resolveIconSource(n) }))

    // 字形 preset：源码里写码点而不是字面字形 —— 纯 ASCII，不会因为粘贴 PUA 字符出错。
    // 码点取自本机 JetBrainsMonoNerdFont-Regular.ttf 的 cmap（按字形名查的，不是猜的）。
    readonly property var topLeftGlyphPresets: [
        // AI / 灵感
        { name: "cod-sparkle", cp: 0xEC10 },
        { name: "fa-robot", cp: 0xEE0D },
        { name: "fa-brain", cp: 0xEE9C },
        { name: "fa-atom", cp: 0xEE99 },
        { name: "fa-wand_sparkles", cp: 0xEF15 },
        { name: "fa-rocket", cp: 0xF135 },
        // 系统 / 发行版
        { name: "linux-endeavour", cp: 0xF322 },
        { name: "linux-archlinux", cp: 0xF303 },
        { name: "linux-hyprland", cp: 0xF359 },
        { name: "linux-tux", cp: 0xF31A },
        { name: "linux-nixos", cp: 0xF313 },
        { name: "linux-cachyos", cp: 0xF385 },
        { name: "oct-cpu", cp: 0xF4BC },
        { name: "fa-memory", cp: 0xEFC5 },
        // 开发
        { name: "fa-terminal", cp: 0xF120 },
        { name: "oct-mark_github", cp: 0xF408 },
        { name: "oct-git_branch", cp: 0xF418 },
        { name: "fa-key", cp: 0xF084 },
        // 趣味
        { name: "fa-cat", cp: 0xEEED },
        { name: "fa-ghost", cp: 0xEEFE },
        { name: "fa-skull", cp: 0xEE15 },
        { name: "fa-fire", cp: 0xF06D },
        { name: "fa-crown", cp: 0xEDEB },
        { name: "fa-gem", cp: 0xF219 },
        { name: "oct-moon", cp: 0xF4EE },
        { name: "fa-headphones", cp: 0xF025 },
        { name: "fae-planet", cp: 0xE22E }
    ].map(p => ({ kind: "glyph", value: String.fromCodePoint(p.cp), name: p.name }))

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }
    
    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "apps"
        title: Translation.tr("Top-left icon")

        ContentSubsection {
            title: Translation.tr("Current")
            tooltip: Translation.tr("bar.topLeftIcon: 图标名 / \"distro\" / SVG 绝对路径\nbar.topLeftIconGlyph: 非空时改用这个字形（nerd font）")

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle { // 预览：和 bar 左上角走同一套渲染逻辑
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2

                    CustomIcon {
                        anchors.centerIn: parent
                        visible: !pageRoot.usingGlyph
                        width: 24
                        height: 24
                        source: pageRoot.topLeftImageSource
                        // 绝对路径不能被 CustomIcon 拼上 assets/icons 前缀（空串在它那里是 falsy）
                        iconFolder: pageRoot.topLeftIsAbsolute ? "" : Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))
                        colorize: true
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        anchors.centerIn: parent
                        visible: pageRoot.usingGlyph
                        text: pageRoot.topLeftIconGlyph
                        font.family: Appearance.font.family.iconNerd
                        font.pixelSize: 26
                        color: Appearance.colors.colOnLayer1
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: pageRoot.usingGlyph
                        ? Translation.tr("Custom glyph") + " · " + pageRoot.topLeftGlyphLabel
                        : pageRoot.topLeftImageSource
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideMiddle
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Image presets")
            tooltip: Translation.tr("来自 assets/icons 的 SVG。选图片会清空自定义字形。\n\"distro\" 会跟随当前发行版（本机 → endeavouros）")

            IconPresetFlow {
                presets: pageRoot.topLeftImagePresets
                currentKind: pageRoot.usingGlyph ? "" : "image"
                currentValue: pageRoot.topLeftIconName
                onPicked: (kind, value) => pageRoot.pickTopLeftIcon(kind, value)
            }
        }

        ContentSubsection {
            title: Translation.tr("Nerd font glyph presets")
            tooltip: Translation.tr("字体用 appearance.fonts.iconNerd。选中后 bar.topLeftIconGlyph 生效并盖过图片。")

            IconPresetFlow {
                presets: pageRoot.topLeftGlyphPresets
                currentKind: pageRoot.usingGlyph ? "glyph" : ""
                currentValue: pageRoot.topLeftIconGlyph
                onPicked: (kind, value) => pageRoot.pickTopLeftIcon(kind, value)
            }
        }

        ContentSubsection {
            title: Translation.tr("Custom")
            tooltip: Translation.tr("也可以直接手改 config.json 里的 bar.topLeftIcon / bar.topLeftIconGlyph")

            TextField {
                id: glyphField
                Layout.fillWidth: true
                padding: 10
                color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                renderType: Text.NativeRendering
                selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                selectionColor: Appearance.colors.colSecondaryContainer
                placeholderText: Translation.tr("粘贴任意字形（nerd font），清空则回到图片")
                placeholderTextColor: Appearance.m3colors.m3outline
                text: pageRoot.topLeftIconGlyph
                onTextEdited: Config.options.bar.topLeftIconGlyph = text
                font.family: Appearance.font.family.iconNerd
                font.pixelSize: 20
                background: Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.verysmall
                    border.width: 2
                    border.color: glyphField.activeFocus ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                    color: "transparent"
                }
                cursorDelegate: Rectangle {
                    width: 1
                    radius: 1
                    color: glyphField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                }
            }

            TextField {
                id: iconField
                Layout.fillWidth: true
                padding: 10
                color: activeFocus ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3onSurfaceVariant
                renderType: Text.NativeRendering
                selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
                selectionColor: Appearance.colors.colSecondaryContainer
                placeholderText: Translation.tr("图标名（如 spark）或 SVG 绝对路径")
                placeholderTextColor: Appearance.m3colors.m3outline
                text: pageRoot.topLeftIconName
                onTextEdited: Config.options.bar.topLeftIcon = text
                background: Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.verysmall
                    border.width: 2
                    border.color: iconField.activeFocus ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                    color: "transparent"
                }
                cursorDelegate: Rectangle {
                    width: 1
                    radius: 1
                    color: iconField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                }
            }
        }
    }

    ContentSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "cloud"
        title: Translation.tr("Weather")
        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "award_star"
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
