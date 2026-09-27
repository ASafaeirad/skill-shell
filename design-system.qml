//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "modules/widgets/designSystem"

ApplicationWindow {
    id: root

    property int currentTab: 0
    property var tabs: [
        "RippleButton", "StyledSwitch", "MaterialTextField", "StyledProgressBar",
        "StatusBadge", "StyledSlider", "StyledText", "MaterialSymbol",
        "StyledRadioButton", "StyledSpinBox", "StyledComboBox", "StyledTextArea",
        "CircularProgress", "StyledIndeterminateProgressBar", "NoticeBox"
    ]
    readonly property string currentComponent: tabs[currentTab]
    property string sampleText: "Sample label"
    property string sampleIcon: "star"
    property bool sampleEnabled: true
    property bool sampleChecked: true
    property bool sampleOutlined: false
    property real sampleValue: 0.6
    property string sampleTone: "primary"
    property int sampleSize: Appearance.font.pixelSize.larger
    property int sampleOption: 0
    property bool sampleReadOnly: false
    property bool sampleWavy: false

    onCurrentTabChanged: Qt.callLater(() => root.ensureSelectedTabVisible())

    function ensureSelectedTabVisible() {
        const tab = tabsRepeater.itemAt(currentTab);
        const view = tabScroll.contentItem;
        if (!tab || !view)
            return;
        if (tab.x < view.contentX)
            view.contentX = tab.x;
        else if (tab.x + tab.width > view.contentX + tabScroll.availableWidth)
            view.contentX = tab.x + tab.width - tabScroll.availableWidth;
    }

    function componentForTab(name) {
        switch (name) {
        case "RippleButton": return buttonsPage;
        case "StyledSwitch": return switchesPage;
        case "MaterialTextField": return fieldsPage;
        case "StyledProgressBar": return progressPage;
        case "StatusBadge": return badgesPage;
        case "StyledSlider": return sliderPage;
        case "StyledText": return textPage;
        case "MaterialSymbol": return symbolPage;
        case "StyledRadioButton": return radioPage;
        case "StyledSpinBox": return spinPage;
        case "StyledComboBox": return comboPage;
        case "StyledTextArea": return textAreaPage;
        case "CircularProgress": return circularPage;
        case "StyledIndeterminateProgressBar": return indeterminatePage;
        case "NoticeBox": return noticePage;
        }
        return buttonsPage;
    }

    visible: true
    title: "Skill Shell design system"
    width: Appearance.spacing.xxl * 36
    height: Appearance.spacing.xxl * 25
    minimumWidth: Appearance.spacing.xxl * 26
    minimumHeight: Appearance.spacing.xxl * 14
    color: Appearance.m3colors.m3background
    onClosing: Qt.quit()

    Component.onCompleted: MaterialThemeLoader.reapplyTheme()

    IpcHandler {
        target: "designSystem"

        function openTab(name: string): string {
            const index = root.tabs.findIndex(tab => tab.toLowerCase() === name.toLowerCase());
            if (index < 0)
                return "Unknown tab. Available: " + root.tabs.join(", ");
            root.currentTab = index;
            root.show();
            root.raise();
            root.requestActivate();
            return root.tabs[index];
        }

        function currentTab(): string {
            return root.tabs[root.currentTab];
        }
    }

    component SectionLabel: StyledText {
        color: Appearance.m3colors.m3onSurfaceVariant
        font.pixelSize: Appearance.font.pixelSize.smallie
    }

    component PageHeading: ColumnLayout {
        property string heading: ""
        property string detail: ""
        spacing: Appearance.spacing.xs

        StyledText {
            text: parent.heading
            color: Appearance.m3colors.m3onSurface
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.pixelSize.title
        }
        StyledText {
            text: parent.detail
            color: Appearance.m3colors.m3onSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.xl
        spacing: Appearance.spacing.lg

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.m

            MaterialSymbol {
                text: "palette"
                iconSize: Appearance.font.pixelSize.title
                color: Appearance.m3colors.m3primary
            }
            StyledText {
                text: "Design system"
                font.family: Appearance.font.family.title
                font.pixelSize: Appearance.font.pixelSize.title
                color: Appearance.m3colors.m3onBackground
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: root.tabs.length + " live QML components"
                color: Appearance.m3colors.m3onSurfaceVariant
            }
        }

        ScrollView {
            id: tabScroll
            Layout.fillWidth: true
            implicitHeight: tabRow.implicitHeight + Appearance.spacing.s
            contentWidth: tabRow.implicitWidth
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            RowLayout {
                id: tabRow
                spacing: Appearance.spacing.xs
                Repeater {
                    id: tabsRepeater
                    model: root.tabs
                    RippleButton {
                        id: tabButton
                        required property int index
                        required property string modelData
                        buttonText: modelData
                        toggled: root.currentTab === index
                        buttonRadius: Appearance.rounding.full
                        contentItem: StyledText {
                            text: tabButton.buttonText
                            color: tabButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                        }
                        onClicked: root.currentTab = index
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.lg

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainerLow
                radius: Appearance.rounding.large

                ScrollView {
                    id: pageScroll
                    anchors.fill: parent
                    anchors.margins: Appearance.spacing.xl
                    clip: true
                    contentWidth: availableWidth

                    Loader {
                        width: pageScroll.availableWidth
                        sourceComponent: root.componentForTab(root.currentComponent)
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: Appearance.spacing.xxl * 9
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.large

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacing.xl
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: Appearance.spacing.m

                        StyledText {
                            text: "Properties"
                            font.family: Appearance.font.family.title
                            font.pixelSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onSurface
                        }
                        SectionLabel {
                            text: "Changes apply to the live examples."
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        SectionLabel {
                            visible: !["StyledSlider", "CircularProgress", "StyledProgressBar",
                                "StyledIndeterminateProgressBar", "StyledSpinBox", "MaterialSymbol"].includes(root.currentComponent)
                            text: "Label"
                        }
                        MaterialTextField {
                            visible: !["StyledSlider", "CircularProgress", "StyledProgressBar",
                                "StyledIndeterminateProgressBar", "StyledSpinBox", "MaterialSymbol"].includes(root.currentComponent)
                            Layout.fillWidth: true
                            text: root.sampleText
                            onTextEdited: root.sampleText = text
                        }

                        SectionLabel {
                            visible: ["RippleButton", "StatusBadge", "MaterialSymbol", "NoticeBox"].includes(root.currentComponent)
                            text: "Icon name"
                        }
                        MaterialTextField {
                            visible: ["RippleButton", "StatusBadge", "MaterialSymbol", "NoticeBox"].includes(root.currentComponent)
                            Layout.fillWidth: true
                            text: root.sampleIcon
                            onTextEdited: root.sampleIcon = text
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { text: "Enabled"; Layout.fillWidth: true }
                            StyledSwitch {
                                checked: root.sampleEnabled
                                onToggled: root.sampleEnabled = checked
                            }
                        }
                        RowLayout {
                            visible: root.currentComponent === "StyledSwitch" || root.currentComponent === "StyledRadioButton"
                            Layout.fillWidth: true
                            StyledText { text: "Checked"; Layout.fillWidth: true }
                            StyledSwitch {
                                checked: root.sampleChecked
                                onToggled: root.sampleChecked = checked
                            }
                        }
                        RowLayout {
                            visible: root.currentComponent === "RippleButton" || root.currentComponent === "StatusBadge"
                            Layout.fillWidth: true
                            StyledText { text: "Outlined"; Layout.fillWidth: true }
                            StyledSwitch {
                                checked: root.sampleOutlined
                                onToggled: root.sampleOutlined = checked
                            }
                        }

                        SectionLabel {
                            visible: ["StyledProgressBar", "StyledSlider", "StyledSpinBox", "CircularProgress"].includes(root.currentComponent)
                            text: "Value · " + Math.round(root.sampleValue * 100) + "%"
                        }
                        StyledSlider {
                            visible: ["StyledProgressBar", "StyledSlider", "StyledSpinBox", "CircularProgress"].includes(root.currentComponent)
                            Layout.fillWidth: true
                            value: root.sampleValue
                            onMoved: root.sampleValue = value
                        }

                        SectionLabel {
                            visible: root.currentComponent === "StatusBadge"
                            text: "Tone"
                        }
                        ComboBox {
                            visible: root.currentComponent === "StatusBadge"
                            Layout.fillWidth: true
                            model: ["neutral", "primary", "success", "error"]
                            currentIndex: model.indexOf(root.sampleTone)
                            onActivated: root.sampleTone = currentText
                        }

                        SectionLabel {
                            visible: root.currentComponent === "StyledText" || root.currentComponent === "MaterialSymbol"
                            text: "Size · " + root.sampleSize
                        }
                        StyledSlider {
                            visible: root.currentComponent === "StyledText" || root.currentComponent === "MaterialSymbol"
                            Layout.fillWidth: true
                            from: Appearance.font.pixelSize.smallest
                            to: Appearance.font.pixelSize.title * 2
                            value: root.sampleSize
                            onMoved: root.sampleSize = Math.round(value)
                        }

                        RowLayout {
                            visible: root.currentComponent === "MaterialTextField" || root.currentComponent === "StyledTextArea"
                            Layout.fillWidth: true
                            StyledText { text: "Read only"; Layout.fillWidth: true }
                            StyledSwitch {
                                checked: root.sampleReadOnly
                                onToggled: root.sampleReadOnly = checked
                            }
                        }
                        RowLayout {
                            visible: root.currentComponent === "StyledProgressBar" || root.currentComponent === "StyledSlider"
                            Layout.fillWidth: true
                            StyledText { text: "Wavy"; Layout.fillWidth: true }
                            StyledSwitch {
                                checked: root.sampleWavy
                                onToggled: root.sampleWavy = checked
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    Component {
        id: buttonsPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "RippleButton"
                detail: "RippleButton variants use the shell's wallpaper derived palette. Hover and press to inspect their states."
            }
            PreviewCard {
                title: "Default and filled"
                description: "The label, icon, and enabled state follow the properties panel."
                RippleButton {
                    buttonText: root.sampleText
                    enabled: root.sampleEnabled
                    buttonRadius: Appearance.rounding.small
                }
                RippleButton {
                    id: filledButton
                    buttonText: root.sampleText
                    enabled: root.sampleEnabled
                    toggled: true
                    buttonRadius: Appearance.rounding.full
                    contentItem: StyledText {
                        text: filledButton.buttonText
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
            PreviewCard {
                title: "Icon and outline"
                RippleButton {
                    enabled: root.sampleEnabled
                    buttonRadius: Appearance.rounding.full
                    colBorder: Appearance.m3colors.m3outline
                    borderWidth: root.sampleOutlined ? 1 : 0
                    contentItem: MaterialSymbol {
                        text: root.sampleIcon
                        iconSize: Appearance.font.pixelSize.larger
                    }
                }
                RippleButton {
                    buttonText: root.sampleText
                    enabled: false
                    buttonRadius: Appearance.rounding.full
                }
            }
        }
    }

    Component {
        id: switchesPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledSwitch"
                detail: "StyledSwitch shows off, on, and disabled variants. Toggle the live switch directly."
            }
            PreviewCard {
                title: "Interactive"
                Row {
                    spacing: Appearance.spacing.m
                    StyledText { text: root.sampleText }
                    StyledSwitch {
                        enabled: root.sampleEnabled
                        checked: root.sampleChecked
                        onToggled: root.sampleChecked = checked
                    }
                }
            }
            PreviewCard {
                title: "Fixed states"
                StyledSwitch { checked: false }
                StyledSwitch { checked: true }
                StyledSwitch { checked: true; enabled: false }
            }
        }
    }

    Component {
        id: fieldsPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "MaterialTextField"
                detail: "MaterialTextField variants use the active theme and remain editable."
            }
            PreviewCard {
                title: "Empty and filled"
                MaterialTextField {
                    width: Appearance.spacing.xxl * 7
                    placeholderText: root.sampleText
                    enabled: root.sampleEnabled
                    readOnly: root.sampleReadOnly
                }
                MaterialTextField {
                    width: Appearance.spacing.xxl * 7
                    text: root.sampleText
                    enabled: root.sampleEnabled
                    readOnly: root.sampleReadOnly
                }
            }
            PreviewCard {
                title: "Read only and disabled"
                MaterialTextField {
                    width: Appearance.spacing.xxl * 7
                    text: root.sampleText
                    readOnly: true
                }
                MaterialTextField {
                    width: Appearance.spacing.xxl * 7
                    text: root.sampleText
                    enabled: false
                }
            }
        }
    }

    Component {
        id: progressPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledProgressBar"
                detail: "Determinate, wavy, and disabled progress variants. Adjust the live value in the properties panel."
            }
            PreviewCard {
                title: "Progress bars"
                StyledProgressBar {
                    value: root.sampleValue
                    enabled: root.sampleEnabled
                    wavy: root.sampleWavy
                }
                StyledProgressBar {
                    value: root.sampleValue
                    wavy: true
                    enabled: root.sampleEnabled
                }
            }
            PreviewCard {
                title: "Disabled"
                StyledProgressBar { value: root.sampleValue; enabled: false }
            }
        }
    }

    Component {
        id: badgesPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StatusBadge"
                detail: "StatusBadge is a reusable shell widget. Its tones follow the current wallpaper palette."
            }
            PreviewCard {
                title: "Live badge"
                StatusBadge {
                    text: root.sampleText
                    icon: root.sampleIcon
                    tone: root.sampleTone
                    outlined: root.sampleOutlined
                    opacity: root.sampleEnabled ? 1 : 0.4
                }
            }
            PreviewCard {
                title: "Tones and shapes"
                StatusBadge { text: "Neutral"; tone: "neutral" }
                StatusBadge { text: "Primary"; tone: "primary"; icon: "star" }
                StatusBadge { text: "Success"; tone: "success"; icon: "check" }
                StatusBadge { text: "Error"; tone: "error"; icon: "error" }
                StatusBadge { text: "Outlined"; tone: "primary"; outlined: true }
            }
        }
    }

    Component {
        id: sliderPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledSlider"
                detail: "The shell's slider supports compact, wide, and wavy tracks. Drag the live example to change its value."
            }
            PreviewCard {
                title: "Live slider"
                StyledSlider {
                    width: Appearance.spacing.xxl * 8
                    value: root.sampleValue
                    enabled: root.sampleEnabled
                    configuration: root.sampleWavy ? StyledSlider.Configuration.Wavy : StyledSlider.Configuration.S
                    onMoved: root.sampleValue = value
                }
            }
            PreviewCard {
                title: "Track variants"
                StyledSlider {
                    width: Appearance.spacing.xxl * 8
                    value: root.sampleValue
                    configuration: StyledSlider.Configuration.M
                    onMoved: root.sampleValue = value
                }
                StyledSlider {
                    width: Appearance.spacing.xxl * 8
                    value: root.sampleValue
                    configuration: StyledSlider.Configuration.L
                    enabled: false
                }
            }
        }
    }

    Component {
        id: textPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledText"
                detail: "Text styles inherit the wallpaper palette and the shell's type scale."
            }
            PreviewCard {
                title: "Live text"
                StyledText {
                    text: root.sampleText
                    font.pixelSize: root.sampleSize
                    enabled: root.sampleEnabled
                }
            }
            PreviewCard {
                title: "Type scale"
                StyledText { text: "Small"; font.pixelSize: Appearance.font.pixelSize.small }
                StyledText { text: "Large"; font.pixelSize: Appearance.font.pixelSize.large }
                StyledText {
                    text: "Title"
                    font.family: Appearance.font.family.title
                    font.pixelSize: Appearance.font.pixelSize.title
                }
            }
        }
    }

    Component {
        id: symbolPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "MaterialSymbol"
                detail: "Material Symbols follow the shell's icon font and can vary in size and fill."
            }
            PreviewCard {
                title: "Live icon"
                MaterialSymbol {
                    text: root.sampleIcon
                    iconSize: root.sampleSize
                    opacity: root.sampleEnabled ? 1 : 0.4
                }
            }
            PreviewCard {
                title: "Fill and size"
                MaterialSymbol { text: "star"; fill: 0; iconSize: Appearance.font.pixelSize.larger }
                MaterialSymbol { text: "star"; fill: 1; iconSize: Appearance.font.pixelSize.larger }
                MaterialSymbol { text: "settings"; iconSize: Appearance.font.pixelSize.title }
            }
        }
    }

    Component {
        id: radioPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledRadioButton"
                detail: "Checked, unchecked, and disabled states use the current accent color."
            }
            PreviewCard {
                title: "Live choice"
                StyledRadioButton {
                    description: root.sampleText
                    checked: root.sampleChecked
                    enabled: root.sampleEnabled
                    onToggled: root.sampleChecked = checked
                }
            }
            PreviewCard {
                title: "Fixed states"
                StyledRadioButton { description: "Unchecked"; checked: false }
                StyledRadioButton { description: "Checked"; checked: true }
                StyledRadioButton { description: "Disabled"; checked: true; enabled: false }
            }
        }
    }

    Component {
        id: spinPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledSpinBox"
                detail: "The editable numeric control uses the shell's layer colors."
            }
            PreviewCard {
                title: "Live value"
                StyledSpinBox {
                    from: 0
                    to: 100
                    value: Math.round(root.sampleValue * 100)
                    enabled: root.sampleEnabled
                    onValueModified: root.sampleValue = value / 100
                }
            }
            PreviewCard {
                title: "Fixed states"
                StyledSpinBox { from: 0; to: 100; value: 0 }
                StyledSpinBox { from: 0; to: 100; value: 100 }
                StyledSpinBox { from: 0; to: 100; value: 50; enabled: false }
            }
        }
    }

    Component {
        id: comboPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledComboBox"
                detail: "Open the live control to inspect its menu and selected state."
            }
            PreviewCard {
                title: "Live selection"
                StyledComboBox {
                    width: Appearance.spacing.xxl * 7
                    model: [root.sampleText, "Second option", "Third option"]
                    currentIndex: root.sampleOption
                    enabled: root.sampleEnabled
                    onActivated: root.sampleOption = index
                }
            }
            PreviewCard {
                title: "Icon and disabled"
                StyledComboBox {
                    width: Appearance.spacing.xxl * 7
                    model: ["First", "Second"]
                    buttonIcon: "tune"
                }
                StyledComboBox {
                    width: Appearance.spacing.xxl * 7
                    model: ["Unavailable"]
                    enabled: false
                }
            }
        }
    }

    Component {
        id: textAreaPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledTextArea"
                detail: "A multi-line editor with the shell's selection and placeholder colors."
            }
            PreviewCard {
                title: "Live editor"
                Rectangle {
                    width: Appearance.spacing.xxl * 10
                    height: Appearance.spacing.xxl * 4
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    StyledTextArea {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.m
                        placeholderText: root.sampleText
                        enabled: root.sampleEnabled
                        readOnly: root.sampleReadOnly
                    }
                }
            }
            PreviewCard {
                title: "Read only and disabled"
                StyledTextArea { text: root.sampleText; readOnly: true }
                StyledTextArea { text: root.sampleText; enabled: false }
            }
        }
    }

    Component {
        id: circularPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "CircularProgress"
                detail: "Ring and filled variants use the active theme colors."
            }
            PreviewCard {
                title: "Live ring"
                CircularProgress {
                    value: root.sampleValue
                    implicitSize: Appearance.spacing.xxl * 2
                    opacity: root.sampleEnabled ? 1 : 0.4
                }
            }
            PreviewCard {
                title: "Variants"
                CircularProgress { value: 0.25; implicitSize: Appearance.spacing.xxl * 2 }
                CircularProgress { value: 0.75; implicitSize: Appearance.spacing.xxl * 2; drainClockwise: true }
                CircularProgress { value: 0.5; implicitSize: Appearance.spacing.xxl * 2; fill: true }
            }
        }
    }

    Component {
        id: indeterminatePage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "StyledIndeterminateProgressBar"
                detail: "Use this when a task has no measurable completion value."
            }
            PreviewCard {
                title: "Active"
                StyledIndeterminateProgressBar {
                    width: Appearance.spacing.xxl * 8
                    enabled: root.sampleEnabled
                }
            }
            PreviewCard {
                title: "Disabled"
                StyledIndeterminateProgressBar {
                    width: Appearance.spacing.xxl * 8
                    enabled: false
                }
            }
        }
    }

    Component {
        id: noticePage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "NoticeBox"
                detail: "A message container with an optional Material Symbol and action."
            }
            PreviewCard {
                title: "Live notice"
                NoticeBox {
                    width: Appearance.spacing.xxl * 12
                    text: root.sampleText
                    materialIcon: root.sampleIcon
                    opacity: root.sampleEnabled ? 1 : 0.4
                }
            }
            PreviewCard {
                title: "With action"
                NoticeBox {
                    width: Appearance.spacing.xxl * 12
                    text: "A setting is available."
                    materialIcon: "info"
                    RippleButton { buttonText: "Review" }
                }
            }
        }
    }
}
