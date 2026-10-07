import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.translator
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Translator widget with the `trans` commandline tool.
 */
Item {
    id: root

    // Sizes
    property real padding: 4

    // Widgets
    property var inputField: inputCanvas.inputTextArea

    // Widget variables
    property bool translationFor: false // Indicates if the translation is for an autocorrected text
    property string translatedText: ""
    property list<string> languages: [] // 上游模式（customLanguages 为空）下装 trans 的全量列表

    // ── 语言列表（本地改动，非上游）─────────────────────────────────────────
    // 上游直接拿 `trans -list-languages` 的 159 项，那是**原生语言名**
    // （العربية / አማርኛ / བོད་ཡིག …），两个毛病：
    //   1) 滚到非拉丁区时侧栏冻十几秒 —— 每个新 script 都要走一次字体回退，
    //      本机 5000+ 字体，这一下很贵；
    //   2) 按字母序排，中文在最后，前面一大片用不到的语言。
    // 所以改成读 Config 里的常用列表（每项 "代码|显示名"）。配置为空 → 保持上游行为。
    // 注意：发翻译时用**代码**（en-US / yue …），界面上显示的是**名字**，
    // 两者靠下面这两个函数互转 —— 上游是把原生名直接当 target 传给 trans 的，
    // 自定义模式下不能再这么干。
    readonly property var customEntries: {
        const raw = Config.options.language.translator.customLanguages ?? [];
        return raw.map(s => {
            const parts = String(s).split("|");
            const code = parts[0].trim();
            const label = (parts.length > 1 && parts[1].trim().length > 0) ? parts[1].trim() : code;
            return {
                "code": code,
                "label": label
            };
        }).filter(e => e.code.length > 0);
    }
    readonly property bool useCustomLanguages: root.customEntries.length > 0
    readonly property string autoLabel: Translation.tr("Auto")

    function labelForCode(code) {
        if (code === "auto")
            return root.useCustomLanguages ? root.autoLabel : code;
        if (!root.useCustomLanguages)
            return code;
        const hit = root.customEntries.find(e => e.code === code);
        return hit ? hit.label : code; // 认不出的旧值（配置里还留着 "English" 这种）原样显示
    }

    function codeForLabel(label) {
        if (label === root.autoLabel)
            return "auto";
        if (!root.useCustomLanguages)
            return label;
        const hit = root.customEntries.find(e => e.label === label);
        return hit ? hit.code : label;
    }

    readonly property var selectorItems: root.useCustomLanguages ? [root.autoLabel, ...root.customEntries.map(e => e.label)] : root.languages

    // 上游定义了 language.translator.engine 却从没传给 trans（死键）。这里接上，
    // 便于 google 端点不通时切 bing / yandex（`trans -list-engines` 看可选值）。
    readonly property string engineArg: {
        const e = (Config.options.language.translator.engine ?? "").trim();
        return (e.length > 0 && e !== "auto") ? ` -engine '${StringUtils.shellSingleQuoteEscape(e)}'` : "";
    }

    // Options
    property string targetLanguage: Config.options.language.translator.targetLanguage
    property string sourceLanguage: Config.options.language.translator.sourceLanguage
    property string hostLanguage: targetLanguage

    // States
    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false // true for target language, false for source language

    function showLanguageSelectorDialog(isTargetLang: bool) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true
    }

    onFocusChanged: (focus) => {
        if (focus) {
            root.inputField.forceActiveFocus()
        }
    }

    Timer {
        id: translateTimer
        interval: Config.options.sidebar.translator.delay
        repeat: false
        onTriggered: () => {
            if (root.inputField.text.trim().length > 0) {
                // console.log("Translating with command:", translateProc.command);
                translateProc.running = false;
                translateProc.buffer = ""; // Clear the buffer
                translateProc.running = true; // Restart the process
            } else {
                root.translatedText = "";
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -brief -no-bidi`
            + root.engineArg
            + ` -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'`
            + ` '${StringUtils.shellSingleQuoteEscape(root.inputField.text.trim())}'`]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            // With -brief mode, we get output with no metadata
            root.translatedText = translateProc.buffer.trim();
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        // 自定义列表时根本不用问 trans 要全量列表（省一次进程启动，也免得它白跑）
        running: !root.useCustomLanguages
        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            // Ensure "auto" is always the first language
            let langs = getLanguagesProc.bufferList
                .filter(lang => lang.trim().length > 0 && lang !== "auto")
                .sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = []; // Clear the buffer
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.padding
        }

        StyledFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent

                LanguageSelectorButton { // Target language button
                    id: targetLanguageButton
                    displayText: root.labelForCode(root.targetLanguage)
                    onClicked: {
                        root.showLanguageSelectorDialog(true);
                    }
                }

                TextCanvas { // Content translation
                    id: outputCanvas
                    isInput: false
                    placeholderText: Translation.tr("Translation goes here...")
                    property bool hasTranslation: (root.translatedText.trim().length > 0)
                    text: hasTranslation ? root.translatedText : ""
                    GroupButton {
                        id: copyButton
                        baseWidth: height
                        buttonRadius: Appearance.rounding.small
                        enabled: outputCanvas.displayedText.trim().length > 0
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.larger
                            text: "content_copy"
                            color: copyButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                        }
                        onClicked: {
                            Quickshell.clipboardText = outputCanvas.displayedText
                        }
                    }
                    GroupButton {
                        id: searchButton
                        baseWidth: height
                        buttonRadius: Appearance.rounding.small
                        enabled: outputCanvas.displayedText.trim().length > 0
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.larger
                            text: "travel_explore"
                            color: searchButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                        }
                        onClicked: {
                            let url = Config.options.search.engineBaseUrl + outputCanvas.displayedText;
                            for (let site of Config.options.search.excludedSites) {
                                url += ` -site:${site}`;
                            }
                            Qt.openUrlExternally(url);
                        }
                    }
                }

            }    
        }

        LanguageSelectorButton { // Source language button
            id: sourceLanguageButton
            displayText: root.labelForCode(root.sourceLanguage)
            onClicked: {
                root.showLanguageSelectorDialog(false);
            }
        }

        TextCanvas { // Content input
            id: inputCanvas
            isInput: true
            placeholderText: Translation.tr("Enter text to translate...")
            onInputTextChanged: {
                translateTimer.restart();
            }
            GroupButton {
                id: pasteButton
                baseWidth: height
                buttonRadius: Appearance.rounding.small
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    text: "content_paste"
                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }
                onClicked: {
                    root.inputField.text = Quickshell.clipboardText
                }
            }
            GroupButton {
                id: deleteButton
                baseWidth: height
                buttonRadius: Appearance.rounding.small
                enabled: inputCanvas.inputTextArea.text.length > 0
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    text: "close"
                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }
                onClicked: {
                    root.inputField.text = ""
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            id: languageSelectorDialog
            titleText: Translation.tr("Select Language")
            items: root.selectorItems
            defaultChoice: root.labelForCode(root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage)
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: (result) => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0) return; // No selection made

                const code = root.codeForLabel(result); // 列表里是名字，存进配置的必须是代码
                if (root.languageSelectorTarget) {
                    root.targetLanguage = code;
                    Config.options.language.translator.targetLanguage = code; // Save to config
                } else {
                    root.sourceLanguage = code;
                    Config.options.language.translator.sourceLanguage = code; // Save to config
                }

                translateTimer.restart(); // Restart translation after language change
            }
        }
    }
}
