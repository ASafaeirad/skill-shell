//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.services
import "modules/widgets/designSystem"

ApplicationWindow {
    id: root

    property int currentTab: 0
    // Material 3 components from qs.modules.common.m3 first, then shell widgets
    // with no M3 counterpart. Keep in sync with modules/common/m3/README.md.
    readonly property var m3Tabs: [
        "Button", "ButtonGroup", "IconButton", "Fab", "Chip", "Card", "ListItem", "Menu", "MenuItem", "ExposedDropdownMenu", "FilterableExposedDropdownMenu", "Divider", "Badge",
        "Checkbox", "RadioButton", "Switch", "Slider", "TextField", "TextArea", "SearchBar", "Tabs", "Toolbar", "Snackbar", "Dialog",
        "LinearProgressIndicator", "CircularProgressIndicator", "LoadingIndicator"
    ]
    readonly property var shellTabs: [
        "StatusBadge", "NoticeBox", "StyledText", "MaterialSymbol",
        "StyledSpinBox", "StyledComboBox", "StyledTextArea"
    ]
    readonly property var tabs: m3Tabs.concat(shellTabs)
    readonly property var tabIcons: ({
        "Button": "smart_button",
        "ButtonGroup": "view_week",
        "IconButton": "touch_app",
        "Fab": "add_circle",
        "Chip": "sell",
        "Card": "crop_landscape",
        "ListItem": "list",
        "Menu": "menu_open",
        "MenuItem": "menu",
        "ExposedDropdownMenu": "arrow_drop_down_circle",
        "FilterableExposedDropdownMenu": "search",
        "Divider": "horizontal_rule",
        "Badge": "notifications_unread",
        "Checkbox": "check_box",
        "RadioButton": "radio_button_checked",
        "Switch": "toggle_on",
        "Slider": "tune",
        "TextField": "text_fields",
        "TextArea": "notes",
        "SearchBar": "search",
        "Tabs": "tab",
        "Toolbar": "toolbar",
        "Snackbar": "info",
        "Dialog": "dialogs",
        "LinearProgressIndicator": "linear_scale",
        "CircularProgressIndicator": "progress_activity",
        "LoadingIndicator": "hourglass_empty",
        "StatusBadge": "label",
        "NoticeBox": "info",
        "StyledText": "title",
        "MaterialSymbol": "interests",
        "StyledSpinBox": "pin",
        "StyledComboBox": "arrow_drop_down_circle",
        "StyledTextArea": "notes"
    })
    readonly property var variantOptions: ({
        "Button": ["filled", "tonal", "outlined", "text", "elevated"],
        "ButtonGroup": ["connected", "segmented"],
        "IconButton": ["standard", "filled", "tonal", "outlined"],
        "Fab": ["primary", "secondary", "tertiary"],
        "Chip": ["assist", "filter", "input", "suggestion"],
        "Card": ["filled", "elevated", "outlined"],
        "Tabs": ["secondary", "compact"],
        "Toolbar": ["floating", "docked"],
        "Snackbar": ["single-line", "two-line"],
        "StatusBadge": ["neutral", "primary", "success", "error"]
    })
    readonly property string currentComponent: tabs[currentTab]
    readonly property bool currentIsM3: m3Tabs.includes(currentComponent)
    readonly property var currentVariants: variantOptions[currentComponent] ?? []
    property string sampleText: "Sample label"
    property string sampleIcon: "star"
    property bool sampleEnabled: true
    property bool sampleChecked: true
    property bool sampleOutlined: false
    property real sampleValue: 0.6
    property string sampleVariant: ""
    property int sampleSize: Appearance.font.pixelSize.larger
    property int sampleOption: 0
    property bool sampleReadOnly: false
    property bool sampleWavy: false

    onCurrentTabChanged: {
        sampleVariant = currentVariants[0] ?? "";
        Qt.callLater(() => root.ensureSelectedTabVisible());
    }

    function shows(names) {
        return names.includes(currentComponent);
    }

    function ensureSelectedTabVisible() {
        const tab = tabRail.tabAt(currentTab);
        const view = tabScroll.contentItem;
        if (!tab || !view)
            return;
        const y = tab.mapToItem(view.contentItem, 0, 0).y;
        if (y < view.contentY)
            view.contentY = y;
        else if (y + tab.height > view.contentY + tabScroll.availableHeight)
            view.contentY = y + tab.height - tabScroll.availableHeight;
    }

    function componentForTab(name) {
        switch (name) {
        case "Button": return buttonPage;
        case "ButtonGroup": return buttonGroupPage;
        case "IconButton": return iconButtonPage;
        case "Fab": return fabPage;
        case "Chip": return chipPage;
        case "Card": return cardPage;
        case "ListItem": return listItemPage;
        case "Menu": return menuPage;
        case "MenuItem": return menuItemPage;
        case "ExposedDropdownMenu": return exposedDropdownPage;
        case "FilterableExposedDropdownMenu": return filterableExposedDropdownPage;
        case "Divider": return dividerPage;
        case "Badge": return badgePage;
        case "Checkbox": return checkboxPage;
        case "RadioButton": return radioPage;
        case "Switch": return switchPage;
        case "Slider": return sliderPage;
        case "TextField": return textFieldPage;
        case "TextArea": return m3TextAreaPage;
        case "SearchBar": return searchBarPage;
        case "Tabs": return tabsPage;
        case "Toolbar": return toolbarPage;
        case "Snackbar": return snackbarPage;
        case "Dialog": return dialogPage;
        case "LinearProgressIndicator": return linearProgressPage;
        case "CircularProgressIndicator": return circularPage;
        case "LoadingIndicator": return loadingPage;
        case "StatusBadge": return badgesPage;
        case "NoticeBox": return noticePage;
        case "StyledText": return textPage;
        case "MaterialSymbol": return symbolPage;
        case "StyledSpinBox": return spinPage;
        case "StyledComboBox": return comboPage;
        case "StyledTextArea": return textAreaPage;
        }
        return buttonPage;
    }

    visible: true
    title: "Skill Shell design system"
    width: Appearance.spacing.xxl * 36
    height: Appearance.spacing.xxl * 25
    minimumWidth: Appearance.spacing.xxl * 26
    minimumHeight: Appearance.spacing.xxl * 14
    color: Appearance.m3colors.m3background
    onClosing: Qt.quit()

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
        sampleVariant = currentVariants[0] ?? "";
    }

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

        function listTabs(): string {
            return root.tabs.join("\n");
        }
    }

    component SectionLabel: StyledText {
        color: Appearance.m3colors.m3onSurfaceVariant
        font.pixelSize: Appearance.font.pixelSize.smallie
    }

    component PageHeading: ColumnLayout {
        property string heading: ""
        property string detail: ""
        // Material 3 guideline slug, e.g. "buttons" for m3.material.io/components/buttons
        property string guideline: ""
        spacing: Appearance.spacing.xs

        StyledText {
            text: root.currentIsM3 ? "M3." + parent.heading : parent.heading
            color: Appearance.m3colors.m3onSurface
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.pixelSize.title
        }
        StyledText {
            text: root.currentIsM3 ? "import qs.modules.common.m3 as M3" : "import qs.modules.common.widgets · shell widget, no M3 counterpart"
            color: Appearance.m3colors.m3primary
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
        StyledText {
            text: parent.detail
            color: Appearance.m3colors.m3onSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        StyledText {
            visible: parent.guideline.length > 0
            text: "m3.material.io/components/" + parent.guideline
            color: Appearance.m3colors.m3primary
            font.pixelSize: Appearance.font.pixelSize.smallie
            font.underline: true
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("https://" + parent.text)
            }
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
                text: root.m3Tabs.length + " Material 3 components · " + root.shellTabs.length + " shell widgets"
                color: Appearance.m3colors.m3onSurfaceVariant
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.lg

            ScrollView {
                id: tabScroll
                Layout.preferredWidth: tabRail.implicitWidth
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                M3.NavigationRail {
                    id: tabRail
                    width: tabScroll.availableWidth
                    expanded: true
                    model: root.tabs.map(name => ({ name: name, icon: root.tabIcons[name] }))
                    currentIndex: root.currentTab
                    onTabSelected: index => root.currentTab = index
                }
            }

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
                            visible: root.currentVariants.length > 0
                            text: root.currentComponent === "StatusBadge" ? "Tone" : "Variant"
                        }
                        StyledComboBox {
                            visible: root.currentVariants.length > 0
                            Layout.fillWidth: true
                            model: root.currentVariants
                            currentIndex: Math.max(0, root.currentVariants.indexOf(root.sampleVariant))
                            onActivated: index => root.sampleVariant = root.currentVariants[index]
                        }

                        SectionLabel {
                            visible: !root.shows(["Slider", "CircularProgressIndicator", "LinearProgressIndicator",
                                "LoadingIndicator", "StyledSpinBox", "MaterialSymbol", "Divider"])
                            text: root.currentComponent === "Badge" ? "Count (empty for a dot)" : "Label"
                        }
                        M3.TextField {
                            visible: !root.shows(["Slider", "CircularProgressIndicator", "LinearProgressIndicator",
                                "LoadingIndicator", "StyledSpinBox", "MaterialSymbol", "Divider"])
                            Layout.fillWidth: true
                            text: root.sampleText
                            onTextEdited: root.sampleText = text
                        }

                        SectionLabel {
                            visible: root.shows(["Button", "IconButton", "Fab", "Chip", "ListItem", "StatusBadge", "MaterialSymbol", "NoticeBox"])
                            text: "Icon name"
                        }
                        M3.TextField {
                            visible: root.shows(["Button", "IconButton", "Fab", "Chip", "ListItem", "StatusBadge", "MaterialSymbol", "NoticeBox"])
                            Layout.fillWidth: true
                            text: root.sampleIcon
                            onTextEdited: root.sampleIcon = text
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { text: "Enabled"; Layout.fillWidth: true }
                            M3.Switch {
                                checked: root.sampleEnabled
                                onToggled: root.sampleEnabled = checked
                            }
                        }
                        RowLayout {
                            visible: root.shows(["Button", "IconButton", "Chip", "Checkbox", "RadioButton", "Switch", "ListItem", "Fab", "Toolbar"])
                            Layout.fillWidth: true
                            StyledText { text: root.shows(["Fab", "Toolbar"]) ? "Elevated" : "Selected"; Layout.fillWidth: true }
                            M3.Switch {
                                checked: root.sampleChecked
                                onToggled: root.sampleChecked = checked
                            }
                        }
                        RowLayout {
                            visible: root.shows(["StatusBadge", "Fab", "SearchBar"])
                            Layout.fillWidth: true
                            StyledText {
                                text: root.currentComponent === "Fab" ? "Expanded" : root.currentComponent === "SearchBar" ? "Compact" : "Outlined"
                                Layout.fillWidth: true
                            }
                            M3.Switch {
                                checked: root.sampleOutlined
                                onToggled: root.sampleOutlined = checked
                            }
                        }

                        SectionLabel {
                            visible: root.shows(["LinearProgressIndicator", "Slider", "StyledSpinBox", "CircularProgressIndicator"])
                            text: "Value · " + Math.round(root.sampleValue * 100) + "%"
                        }
                        M3.Slider {
                            visible: root.shows(["LinearProgressIndicator", "Slider", "StyledSpinBox", "CircularProgressIndicator"])
                            Layout.fillWidth: true
                            value: root.sampleValue
                            onMoved: root.sampleValue = value
                        }

                        SectionLabel {
                            visible: root.shows(["StyledText", "MaterialSymbol"])
                            text: "Size · " + root.sampleSize
                        }
                        M3.Slider {
                            visible: root.shows(["StyledText", "MaterialSymbol"])
                            Layout.fillWidth: true
                            from: Appearance.font.pixelSize.smallest
                            to: Appearance.font.pixelSize.title * 2
                            value: root.sampleSize
                            onMoved: root.sampleSize = Math.round(value)
                        }

                        RowLayout {
                            visible: root.shows(["TextField", "TextArea", "StyledTextArea"])
                            Layout.fillWidth: true
                            StyledText { text: "Read only"; Layout.fillWidth: true }
                            M3.Switch {
                                checked: root.sampleReadOnly
                                onToggled: root.sampleReadOnly = checked
                            }
                        }
                        RowLayout {
                            visible: root.shows(["LinearProgressIndicator", "Slider"])
                            Layout.fillWidth: true
                            StyledText { text: "Wavy"; Layout.fillWidth: true }
                            M3.Switch {
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
        id: dialogPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Dialog"
                guideline: "dialogs"
                detail: "Basic dialogs interrupt a task for a decision. Overlay dialogs use a separate focused window."
            }
            PreviewCard {
                title: "Live basic dialog"
                M3.Dialog {
                    width: parent.width
                    height: Appearance.sizes.m3DialogPreviewHeight
                    Component.onCompleted: show = true
                    M3.DialogTitle { text: root.sampleText }
                    M3.DialogParagraph { text: "Choose an action to continue." }
                    M3.DialogButtonRow {
                        Item { Layout.fillWidth: true }
                        M3.Button { variant: "text"; text: "Cancel"; enabled: root.sampleEnabled }
                        M3.Button { variant: "text"; text: "OK"; enabled: root.sampleEnabled }
                    }
                }
            }
            PreviewCard {
                title: "Focused overlay dialog"
                M3.Button {
                    variant: "tonal"
                    text: "Open overlay"
                    onClicked: exampleOverlay.open()
                }
            }
            PreviewCard {
                title: "Error supporting text"
                M3.DialogParagraph {
                    error: true
                    text: "Incorrect passphrase"
                }
            }
            PreviewCard {
                title: "Outlined surface"
                M3.DialogCard {
                    width: parent.width
                    height: Appearance.sizes.m3DialogOverlayHeight
                    outlinedSurface: true
                    Component.onCompleted: animateIn()
                    M3.DialogParagraph {
                        anchors.centerIn: parent
                        text: "Longer dialog content"
                    }
                }
            }
            M3.DialogOverlay {
                id: exampleOverlay
                layerNamespace: "quickshell:designSystemDialog"
                onDismissed: close()
                M3.DialogCard {
                    implicitWidth: Appearance.sizes.m3DialogOverlayWidth
                    implicitHeight: Appearance.sizes.m3DialogOverlayHeight
                    Component.onCompleted: animateIn()
                    M3.DialogTitle {
                        anchors.centerIn: parent
                        text: "Overlay dialog"
                    }
                }
            }
        }
    }

    Component {
        id: buttonGroupPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Button group"
                guideline: "button-groups"
                detail: "Connected groups collect related actions. Segmented groups choose one value from a set."
            }
            PreviewCard {
                title: "Live group"
                M3.ButtonGroup {
                    variant: root.sampleVariant === "segmented" ? "segmented" : "connected"
                    options: [
                        { displayName: "Video", icon: "movie", value: "video" },
                        { displayName: "Audio", icon: "music_note", value: "audio" }
                    ]
                    currentValue: root.sampleOption === 0 ? "video" : "audio"
                    onSelected: value => root.sampleOption = value === "video" ? 0 : 1
                    enabled: root.sampleEnabled
                    M3.Button { text: "Back"; materialIcon: "arrow_back"; variant: "tonal" }
                    M3.Button { text: "Forward"; materialIcon: "arrow_forward"; variant: "tonal" }
                }
            }
            PreviewCard {
                title: "Connected actions"
                M3.ButtonGroup {
                    padding: Appearance.spacing.xs
                    M3.IconButton { materialIcon: "undo"; tooltip: "Undo" }
                    M3.IconButton { materialIcon: "redo"; tooltip: "Redo" }
                }
            }
            PreviewCard {
                title: "Segmented choices and locked state"
                M3.ButtonGroup {
                    variant: "segmented"
                    options: [{ displayName: "Day", value: 0 }, { displayName: "Week", value: 1 }, { displayName: "Month", value: 2 }]
                    currentValue: 1
                }
                M3.ButtonGroup {
                    variant: "segmented"
                    readOnly: true
                    options: [{ displayName: "Video", value: 0 }, { displayName: "Audio", value: 1 }]
                    currentValue: 0
                }
            }
        }
    }

    Component {
        id: buttonPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Button"
                guideline: "buttons"
                detail: "Common buttons for actions, by emphasis: filled for the one primary action, tonal and elevated for secondary ones, outlined and text for the rest. selected turns any of them into a toggle button."
            }
            PreviewCard {
                title: "Live button"
                M3.Button {
                    variant: root.sampleVariant
                    text: root.sampleText
                    materialIcon: root.sampleIcon
                    enabled: root.sampleEnabled
                    selected: root.sampleChecked
                }
            }
            PreviewCard {
                title: "Variants"
                description: "filled · tonal · outlined · text · elevated"
                Repeater {
                    model: root.variantOptions["Button"]
                    M3.Button { required property string modelData; variant: modelData; text: modelData }
                }
            }
            PreviewCard {
                title: "With icon, and disabled"
                Repeater {
                    model: root.variantOptions["Button"]
                    M3.Button { required property string modelData; variant: modelData; text: "Retry"; materialIcon: "refresh"; enabled: false }
                }
            }
            PreviewCard {
                title: "Toggle buttons"
                description: "toggleable drops the unselected state to the neutral surface roles; selected takes the filled ones."
                Repeater {
                    model: root.variantOptions["Button"]
                    M3.Button { required property string modelData; variant: modelData; text: modelData; toggleable: true }
                }
                Repeater {
                    model: root.variantOptions["Button"]
                    M3.Button { required property string modelData; variant: modelData; text: modelData; toggleable: true; selected: true }
                }
            }
            PreviewCard {
                title: "Shapes"
                description: "shape: round (default) · square. Square keeps small corners for a button in a grid of equal cells, such as a calendar day; press it to see the corners tighten."
                Repeater {
                    model: ["round", "square"]
                    M3.Button { required property string modelData; variant: "tonal"; shape: modelData; text: modelData }
                }
                Repeater {
                    model: ["round", "square"]
                    M3.Button { required property string modelData; variant: "text"; shape: modelData; toggleable: true; selected: true; text: modelData }
                }
            }
            PreviewCard {
                title: "Destructive and error-recovery actions"
                description: "error swaps M3's accent roles for the error ones, for the action that deletes something or recovers from a failure."
                Repeater {
                    model: root.variantOptions["Button"]
                    M3.Button { required property string modelData; variant: modelData; text: "Delete"; materialIcon: "delete"; error: true }
                }
            }
            PreviewCard {
                title: "Trailing text, stretched"
                description: "trailingText adds a smaller figure after the label; the content stays centred at any width"
                M3.Button { width: 320; text: "Download"; materialIcon: "download"; trailingText: "~42 MB" }
            }
            PreviewCard {
                title: "Quick setting tile"
                description: "The icon can toggle a setting while the rest of the tile opens its menu."
                M3.Button {
                    width: 220
                    tileLayout: true
                    variant: "tonal"
                    text: "Bluetooth"
                    supportingText: "Connected"
                    materialIcon: "bluetooth"
                    leadingAction: () => sampleTileSelected = !sampleTileSelected
                    leadingSelected: sampleTileSelected
                    property bool sampleTileSelected: true
                }
            }
            PreviewCard {
                title: "Content slot, and external hover"
                description: "content replaces the icon/label row for a button whose label is not text. selectedVariant uses a tonal active state. externalHover lights the state layer from a larger hover region around it — hover the dashed area."
                Rectangle {
                    implicitWidth: statusPill.implicitWidth + Appearance.spacing.xxl * 2
                    implicitHeight: statusPill.implicitHeight + Appearance.spacing.lg * 2
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    MouseArea {
                        id: pillRegion
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    M3.Button {
                        id: statusPill
                        anchors.centerIn: parent
                        variant: "text"
                        selectedVariant: "tonal"
                        selected: root.sampleChecked
                        externalHover: pillRegion.containsMouse
                        onClicked: root.sampleChecked = !root.sampleChecked
                        content: RowLayout {
                            spacing: Appearance.spacing.m
                            Repeater {
                                model: ["volume_off", "keyboard", "battery_5_bar", "wifi"]
                                MaterialSymbol {
                                    required property string modelData
                                    text: modelData
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: statusPill.contentColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: iconButtonPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "IconButton"
                guideline: "icon-buttons"
                detail: "Compact actions carried by an icon. Give it a tooltip. With toggleable set, selected picks the selected colours and fills the icon; flip your own state in onClicked."
            }
            PreviewCard {
                title: "Live toggle"
                M3.IconButton {
                    variant: root.sampleVariant
                    materialIcon: root.sampleIcon
                    tooltip: root.sampleText
                    toggleable: true
                    selected: root.sampleChecked
                    enabled: root.sampleEnabled
                    onClicked: root.sampleChecked = !root.sampleChecked
                }
            }
            PreviewCard {
                title: "Variants"
                description: "standard · filled · tonal · outlined, as plain actions"
                Repeater {
                    model: root.variantOptions["IconButton"]
                    M3.IconButton { required property string modelData; variant: modelData; materialIcon: "settings"; tooltip: modelData }
                }
            }
            PreviewCard {
                title: "Toggle: unselected and selected"
                Repeater {
                    model: root.variantOptions["IconButton"]
                    M3.IconButton { required property string modelData; variant: modelData; materialIcon: "favorite"; toggleable: true }
                }
                Repeater {
                    model: root.variantOptions["IconButton"]
                    M3.IconButton { required property string modelData; variant: modelData; materialIcon: "favorite"; toggleable: true; selected: true }
                }
            }
            PreviewCard {
                title: "Tonal selected state"
                description: "selectedVariant: \"tonal\" keeps a standard toggle bare until selected, then gives it the secondary container, as in a toolbar"
                M3.IconButton { materialIcon: "dark_mode"; tooltip: "Unselected"; toggleable: true; selectedVariant: "tonal" }
                M3.IconButton { materialIcon: "power_settings_new"; tooltip: "Selected"; toggleable: true; selectedVariant: "tonal"; selected: true }
            }
            PreviewCard {
                title: "Sizes"
                description: "small (default, 40) · xsmall (32), for dense rows"
                Repeater {
                    model: ["small", "xsmall"]
                    M3.IconButton { required property string modelData; size: modelData; variant: "tonal"; materialIcon: "close"; tooltip: modelData }
                }
            }
            PreviewCard {
                title: "Destructive actions"
                description: "error swaps M3's accent roles for the error ones, so the icon of a delete action reads red."
                Repeater {
                    model: root.variantOptions["IconButton"]
                    M3.IconButton { required property string modelData; variant: modelData; materialIcon: "delete"; tooltip: "Move to trash"; error: true }
                }
            }
            PreviewCard {
                title: "Colour swatches"
                description: "dotColor puts a colour dot where the icon goes, for a button that picks a colour. As a toggle, the round container is the swatch's selection ring."
                Repeater {
                    model: ["term6", "term2", "term3", "term4", "term5", "term1"]
                    M3.IconButton {
                        required property string modelData
                        size: "xsmall"
                        toggleable: true
                        selectedVariant: "tonal"
                        dotColor: Appearance.m3colors[modelData]
                        selected: modelData === "term3"
                    }
                }
            }
            PreviewCard {
                title: "Application icon"
                M3.IconButton {
                    iconSource: Quickshell.iconPath("applications-multimedia", "image-missing")
                    tooltip: "Mute application"
                }
            }
            PreviewCard {
                title: "Rotating icon"
                description: "iconRotation turns the icon, animated, so the button points at the state it controls. Click to flip."
                M3.IconButton {
                    materialIcon: "expand_more"
                    tooltip: root.sampleChecked ? "Collapse" : "Expand"
                    toggleable: true
                    selected: root.sampleChecked
                    iconRotation: root.sampleChecked ? 180 : 0
                    onClicked: root.sampleChecked = !root.sampleChecked
                }
            }
        }
    }

    Component {
        id: fabPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Fab"
                guideline: "floating-action-button"
                detail: "The single most important action on a surface. variant picks the container role, expanded shows buttonText next to the icon (extended FAB), elevated draws its shadow."
            }
            PreviewCard {
                title: "Live FAB"
                M3.Fab {
                    variant: root.sampleVariant
                    iconText: root.sampleIcon
                    buttonText: root.sampleText
                    tooltip: root.sampleText
                    expanded: root.sampleOutlined
                    elevated: root.sampleChecked
                    enabled: root.sampleEnabled
                }
            }
            PreviewCard {
                title: "Variants"
                description: "primary · secondary · tertiary container roles"
                Repeater {
                    model: root.variantOptions["Fab"]
                    M3.Fab { required property string modelData; variant: modelData; iconText: "edit"; tooltip: modelData; elevated: true }
                }
            }
            PreviewCard {
                title: "Sizes"
                description: "regular (56) · toolbar (48), the tertiary FAB paired with a floating M3.Toolbar"
                M3.Fab { iconText: "add"; tooltip: "regular" }
                M3.Fab { size: "toolbar"; variant: "tertiary"; iconText: "close"; tooltip: "toolbar"; elevated: true }
            }
        }
    }

    Component {
        id: chipPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Chip"
                guideline: "chips"
                detail: "Assist chips start an action, filter chips narrow content, input chips hold an entered value and can be removed, suggestion chips offer a reply or query."
            }
            PreviewCard {
                title: "Live chip"
                M3.Chip {
                    variant: root.sampleVariant
                    text: root.sampleText
                    materialIcon: root.sampleVariant === "filter" ? "" : root.sampleIcon
                    selected: root.sampleChecked
                    enabled: root.sampleEnabled
                    onClicked: root.sampleChecked = !root.sampleChecked
                }
            }
            PreviewCard {
                title: "Variants"
                M3.Chip { variant: "assist"; text: "Add to calendar"; materialIcon: "event" }
                M3.Chip { variant: "filter"; text: "Unread" }
                M3.Chip { variant: "filter"; text: "Starred"; selected: true }
                M3.Chip { variant: "input"; text: "alex@example.com"; materialIcon: "person" }
                M3.Chip { variant: "suggestion"; text: "Sounds good" }
                M3.Chip { variant: "assist"; text: "Disabled"; materialIcon: "block"; enabled: false }
                M3.Chip { variant: "filter"; text: "Locked download"; selected: true; readOnly: true }
            }
        }
    }

    Component {
        id: cardPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Card"
                guideline: "cards"
                detail: "A container for content and actions about one subject. Children stack in a column. interactive adds the hover state layer and a clicked signal."
            }
            PreviewCard {
                title: "Live card"
                M3.Card {
                    width: Appearance.spacing.xxl * 10
                    variant: root.sampleVariant
                    interactive: root.sampleEnabled
                    StyledText {
                        text: root.sampleText
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSurface
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: "Supporting text for the card body."
                        color: Appearance.colors.colOnSurfaceVariant
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        M3.Button { variant: "text"; text: "Dismiss" }
                        M3.Button { variant: "filled"; text: "Open" }
                    }
                }
            }
            PreviewCard {
                title: "Selectable cards"
                RowLayout {
                    Repeater {
                        model: ["tonal", "filled"]
                        M3.Card {
                            id: selectableCard
                            required property string modelData
                            interactive: true
                            selectedVariant: modelData
                            selected: true
                            onClicked: selected = !selected
                            StyledText {
                                text: selectableCard.modelData + " selection"
                                color: selectableCard.contentColor
                            }
                        }
                    }
                }
            }
            PreviewCard {
                title: "Variants"
                Repeater {
                    model: root.variantOptions["Card"]
                    M3.Card {
                        required property string modelData
                        variant: modelData
                        StyledText { text: modelData; color: Appearance.colors.colOnSurface }
                    }
                }
            }
        }
    }

    Component {
        id: snackbarPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Snackbar"
                guideline: "snackbar"
                detail: "Brief feedback with an optional action. A second line and countdown can describe an undo window."
            }
            PreviewCard {
                title: "Live snackbar"
                M3.Snackbar {
                    width: Appearance.spacing.xxl * 12
                    variant: root.sampleVariant
                    text: root.sampleText
                    supportingText: "Message details"
                    leadingIcon: root.sampleIcon
                    actionText: "Undo"
                    actionTooltip: "Undo action"
                    progress: root.sampleVariant === "two-line" ? root.sampleValue : -1
                    enabled: root.sampleEnabled
                    onActionClicked: root.sampleText = "Undone"
                }
            }
            PreviewCard {
                title: "Variants"
                M3.Snackbar {
                    width: Appearance.spacing.xxl * 10
                    text: "Changes saved"
                    actionText: "Undo"
                }
                M3.Snackbar {
                    width: Appearance.spacing.xxl * 12
                    variant: "two-line"
                    text: "Moved to trash"
                    supportingText: "Alex · Meeting notes"
                    leadingIcon: "delete"
                    actionText: "Undo"
                    progress: root.sampleValue
                }
            }
        }
    }

    Component {
        id: listItemPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "ListItem"
                guideline: "lists"
                detail: "One row of a list: headline, optional supporting line, leading icon, and trailing text, icon or controls (children go to the trailing slot)."
            }
            PreviewCard {
                title: "Live item"
                M3.ListItem {
                    width: Appearance.spacing.xxl * 12
                    text: root.sampleText
                    supportingText: "Supporting text"
                    leadingIcon: root.sampleIcon
                    trailingText: "12:30"
                    selected: root.sampleChecked
                    enabled: root.sampleEnabled
                }
            }
            PreviewCard {
                title: "Lines and trailing parts"
                ColumnLayout {
                    width: Appearance.spacing.xxl * 12
                    spacing: 0
                    M3.ListItem { Layout.fillWidth: true; text: "One line"; leadingIcon: "inbox"; trailingIcon: "chevron_right" }
                    M3.Divider {}
                    M3.ListItem { Layout.fillWidth: true; text: "Compact one line"; leadingIcon: "check"; compact: true; M3.Switch { checked: true } }
                    M3.Divider {}
                    M3.ListItem {
                        Layout.fillWidth: true
                        text: "Wi-Fi"
                        supportingText: "Home network"
                        leadingIcon: "wifi"
                        M3.Switch { checked: true }
                    }
                    M3.Divider {}
                    M3.ListItem { Layout.fillWidth: true; text: "Static row"; supportingText: "interactive: false"; interactive: false }
                }
            }
            PreviewCard {
                title: "Leading elements, overline, selected and density"
                ColumnLayout {
                    width: Appearance.spacing.xxl * 12
                    spacing: 0
                    M3.ListItem {
                        Layout.fillWidth: true
                        text: "Files"
                        leadingIconSource: Quickshell.iconPath("system-file-manager", "image-missing")
                        trailingText: "Open"
                        selected: true
                        density: -2
                        M3.IconButton { materialIcon: "open_in_new"; tooltip: "New window" }
                    }
                    M3.ListItem {
                        Layout.fillWidth: true
                        overline: "Action"
                        text: "/wallpaper"
                        leadingIcon: "settings_suggest"
                        density: -2
                    }
                    M3.ListItem {
                        Layout.fillWidth: true
                        text: "fire <u>flame</u>"
                        textFormat: Text.StyledText
                        leadingText: "🔥"
                        density: -2
                    }
                    M3.ListItem {
                        Layout.fillWidth: true
                        text: "git status --short"
                        monospace: true
                        leadingIcon: "content_paste"
                        density: -2
                        headlineLeadingData: MaterialSymbol {
                            text: "check_circle"
                            fill: 1
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }
    }

    Component {
        id: menuPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Menu"
                guideline: "menus"
                detail: "A filled surface for menu actions, divided into groups."
            }
            PreviewCard {
                title: "Action menu"
                M3.Menu {
                    implicitWidth: Appearance.spacing.xxl * 9
                    implicitHeight: menuPreview.implicitHeight + Appearance.spacing.s * 2
                    ColumnLayout {
                        id: menuPreview
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.s
                        spacing: 0
                        M3.MenuItem { Layout.fillWidth: true; text: "Copy"; leadingIcon: "content_copy" }
                        M3.Divider {}
                        M3.MenuItem { Layout.fillWidth: true; text: "Paste"; leadingIcon: "content_paste" }
                    }
                }
            }
        }
    }

    Component {
        id: menuItemPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "MenuItem"
                guideline: "menus"
                detail: "One row of a menu: a label with an optional leading icon or image, a selection state, and a trailing icon for a submenu. Groups are separated by a Divider, never by a menu item."
            }
            PreviewCard {
                title: "Live item"
                M3.MenuItem {
                    width: Appearance.spacing.xxl * 9
                    text: root.sampleText
                    leadingIcon: root.sampleIcon
                    trailingIcon: "chevron_right"
                    enabled: root.sampleEnabled
                }
            }
            PreviewCard {
                title: "A menu"
                description: "reserveLeadingIcon keeps the icon column on the items that have none, so the labels line up"
                M3.Menu {
                    implicitWidth: Appearance.spacing.xxl * 9
                    implicitHeight: menuColumn.implicitHeight + Appearance.spacing.xs * 2

                    ColumnLayout {
                        id: menuColumn
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.xs
                        spacing: 0

                        M3.MenuItem { Layout.fillWidth: true; leadingIcon: "content_copy"; text: "Copy" }
                        M3.MenuItem { Layout.fillWidth: true; leadingIcon: "content_paste"; text: "Paste"; enabled: false }
                        M3.Divider { Layout.topMargin: Appearance.spacing.xs; Layout.bottomMargin: Appearance.spacing.xs }
                        M3.MenuItem { Layout.fillWidth: true; reserveLeadingIcon: true; text: "Preferences"; trailingIcon: "chevron_right" }
                        M3.MenuItem { Layout.fillWidth: true; reserveLeadingIcon: true; text: "Quit"; trailingText: "Ctrl+Q" }
                    }
                }
            }
            PreviewCard {
                title: "Selection and density"
                description: "selectionControl: checkbox · radio, with reserveSelectionControl on the rest of the menu. density runs from 0 (48) to -3 (36)."
                ColumnLayout {
                    width: Appearance.spacing.xxl * 9
                    spacing: 0
                    M3.MenuItem { Layout.fillWidth: true; text: "Show hidden"; selectionControl: "checkbox"; checkState: Qt.Checked }
                    M3.MenuItem { Layout.fillWidth: true; text: "Show mixed"; selectionControl: "checkbox"; checkState: Qt.PartiallyChecked }
                    M3.MenuItem { Layout.fillWidth: true; text: "Sort by name"; selectionControl: "radio"; checkState: Qt.Checked }
                    M3.MenuItem { Layout.fillWidth: true; text: "Sort by date"; selectionControl: "radio" }
                }
                ColumnLayout {
                    width: Appearance.spacing.xxl * 6
                    spacing: 0
                    Repeater {
                        model: [0, -1, -2, -3]
                        M3.MenuItem {
                            required property int modelData
                            Layout.fillWidth: true
                            density: modelData
                            leadingIcon: "density_medium"
                            text: `density ${modelData}`
                        }
                    }
                }
            }
        }
    }

    Component {
        id: exposedDropdownPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "ExposedDropdownMenu"
                guideline: "menus"
                detail: "Choose one value from a popup menu."
            }
            PreviewCard {
                title: "Live selection"
                M3.ExposedDropdownMenu {
                    width: Appearance.spacing.xxl * 7
                    model: [root.sampleText, "Second option", "Third option"]
                    currentIndex: root.sampleOption
                    enabled: root.sampleEnabled
                    onActivated: root.sampleOption = index
                }
            }
            PreviewCard {
                title: "Icon and disabled"
                M3.ExposedDropdownMenu {
                    width: Appearance.spacing.xxl * 7
                    model: ["First", "Second"]
                    buttonIcon: "tune"
                }
                M3.ExposedDropdownMenu {
                    width: Appearance.spacing.xxl * 7
                    model: ["Unavailable"]
                    enabled: false
                }
            }
        }
    }

    Component {
        id: filterableExposedDropdownPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "FilterableExposedDropdownMenu"
                guideline: "menus"
                detail: "An exposed dropdown with a text filter for long lists."
            }
            PreviewCard {
                title: "Filter and select"
                M3.FilterableExposedDropdownMenu {
                    width: Appearance.spacing.xxl * 9
                    sourceModel: ["Amsterdam", "Berlin", "London", "Paris"]
                    selectedValue: root.sampleText
                    filterPlaceholderText: "Filter cities"
                    onValueActivated: value => root.sampleText = value
                }
            }
        }
    }

    Component {
        id: dividerPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Divider"
                guideline: "divider"
                detail: "A thin line that groups content. Fills its layout's width by default; vertical for rows; insetStart and insetEnd to indent."
            }
            PreviewCard {
                title: "Full width and inset"
                ColumnLayout {
                    width: Appearance.spacing.xxl * 12
                    spacing: Appearance.spacing.m
                    StyledText { text: "Above" }
                    M3.Divider {}
                    StyledText { text: "Between" }
                    M3.Divider { insetStart: Appearance.spacing.xxl }
                    StyledText { text: "Below" }
                }
            }
            PreviewCard {
                title: "Vertical"
                RowLayout {
                    height: Appearance.spacing.xxl
                    spacing: Appearance.spacing.m
                    StyledText { text: "Left" }
                    M3.Divider { vertical: true }
                    StyledText { text: "Right" }
                }
            }
        }
    }

    Component {
        id: badgePage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Badge"
                guideline: "badges"
                detail: "A dot or short count on an icon. For a labelled status pill use StatusBadge."
            }
            PreviewCard {
                title: "Live badge"
                MaterialSymbol {
                    text: "mail"
                    iconSize: Appearance.font.pixelSize.title * 1.5
                    // A badge holds at most four characters, as "999+" does.
                    M3.Badge { text: root.sampleText.slice(0, 4); x: parent.width - width / 2; y: -height / 3 }
                }
            }
            PreviewCard {
                title: "Small and large"
                M3.Badge {}
                M3.Badge { text: "3" }
                M3.Badge { text: "999+" }
            }
        }
    }

    Component {
        id: checkboxPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Checkbox"
                guideline: "checkbox"
                detail: "Select one or more items from a set. tristate adds the indeterminate state; error draws it in the error colour."
            }
            PreviewCard {
                title: "Live checkbox"
                M3.Checkbox {
                    text: root.sampleText
                    checked: root.sampleChecked
                    enabled: root.sampleEnabled
                    onToggled: root.sampleChecked = checked
                }
            }
            PreviewCard {
                title: "States"
                M3.Checkbox { text: "Unchecked" }
                M3.Checkbox { text: "Checked"; checked: true }
                M3.Checkbox { text: "Indeterminate"; tristate: true; checkState: Qt.PartiallyChecked }
                M3.Checkbox { text: "Error"; checked: true; error: true }
                M3.Checkbox { text: "Disabled"; checked: true; enabled: false }
            }
        }
    }

    Component {
        id: radioPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "RadioButton"
                guideline: "radio-button"
                detail: "Pick one option from a set. The label is description."
            }
            PreviewCard {
                title: "Live choice"
                M3.RadioButton {
                    description: root.sampleText
                    checked: root.sampleChecked
                    enabled: root.sampleEnabled
                    onToggled: root.sampleChecked = checked
                }
            }
            PreviewCard {
                title: "Fixed states"
                M3.RadioButton { description: "Unchecked"; checked: false }
                M3.RadioButton { description: "Checked"; checked: true }
                M3.RadioButton { description: "Disabled"; checked: true; enabled: false }
            }
        }
    }

    Component {
        id: switchPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Switch"
                guideline: "switch"
                detail: "Turn one setting on or off. For a labelled settings row use ConfigSwitch, which wraps it."
            }
            PreviewCard {
                title: "Interactive"
                Row {
                    spacing: Appearance.spacing.m
                    StyledText { text: root.sampleText }
                    M3.Switch {
                        enabled: root.sampleEnabled
                        checked: root.sampleChecked
                        onToggled: root.sampleChecked = checked
                    }
                }
            }
            PreviewCard {
                title: "Fixed states"
                M3.Switch { checked: false }
                M3.Switch { checked: true }
                M3.Switch { checked: true; enabled: false }
            }
        }
    }

    Component {
        id: sliderPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Slider"
                guideline: "sliders"
                detail: "Pick a value from a range. configuration takes StyledSlider.Configuration (XS, S, M, L, XL, Wavy), which needs qs.modules.common.widgets imported."
            }
            PreviewCard {
                title: "Live slider"
                M3.Slider {
                    width: Appearance.spacing.xxl * 8
                    value: root.sampleValue
                    enabled: root.sampleEnabled
                    configuration: root.sampleWavy ? StyledSlider.Configuration.Wavy : StyledSlider.Configuration.S
                    onMoved: root.sampleValue = value
                }
            }
            PreviewCard {
                title: "Track variants"
                M3.Slider {
                    width: Appearance.spacing.xxl * 8
                    value: root.sampleValue
                    configuration: StyledSlider.Configuration.M
                    onMoved: root.sampleValue = value
                }
                M3.Slider {
                    width: Appearance.spacing.xxl * 8
                    value: root.sampleValue
                    configuration: StyledSlider.Configuration.L
                    enabled: false
                }
            }
        }
    }

    Component {
        id: textFieldPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "TextField"
                guideline: "text-fields"
                detail: "Single-line text entry. For multi-line text use StyledTextArea."
            }
            PreviewCard {
                title: "Empty and filled"
                M3.TextField {
                    width: Appearance.spacing.xxl * 7
                    placeholderText: root.sampleText
                    enabled: root.sampleEnabled
                    readOnly: root.sampleReadOnly
                }
                M3.TextField {
                    width: Appearance.spacing.xxl * 7
                    text: root.sampleText
                    enabled: root.sampleEnabled
                    readOnly: root.sampleReadOnly
                }
            }
            PreviewCard {
                title: "Read only and disabled"
                M3.TextField { width: Appearance.spacing.xxl * 7; text: root.sampleText; readOnly: true }
                M3.TextField { width: Appearance.spacing.xxl * 7; text: root.sampleText; enabled: false }
            }
        }
    }

    Component {
        id: m3TextAreaPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "TextArea"
                guideline: "text-fields"
                detail: "Filled multiline text entry."
            }
            PreviewCard {
                title: "Empty and filled"
                M3.TextArea { width: Appearance.spacing.xxl * 7; placeholderText: root.sampleText; enabled: root.sampleEnabled; readOnly: root.sampleReadOnly }
                M3.TextArea { width: Appearance.spacing.xxl * 7; text: root.sampleText; enabled: root.sampleEnabled; readOnly: root.sampleReadOnly }
            }
            PreviewCard {
                title: "Read only and disabled"
                M3.TextArea { width: Appearance.spacing.xxl * 7; text: root.sampleText; readOnly: true }
                M3.TextArea { width: Appearance.spacing.xxl * 7; text: root.sampleText; enabled: false }
            }
        }
    }

    Component {
        id: searchBarPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "SearchBar"
                guideline: "search"
                detail: "The pill-shaped query field that opens a search. Put a leading icon and trailing actions beside it."
            }
            PreviewCard {
                title: "Live search bar"
                RowLayout {
                    spacing: Appearance.spacing.xs
                    MaterialSymbol {
                        text: "search"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colOnSurface
                    }
                    M3.SearchBar {
                        implicitWidth: Appearance.spacing.xxl * 9
                        compact: root.sampleOutlined
                        placeholderText: root.sampleText
                        enabled: root.sampleEnabled
                    }
                    M3.IconButton { materialIcon: "image_search"; tooltip: "Google Lens" }
                }
            }
            PreviewCard {
                title: "Default and compact"
                M3.SearchBar { implicitWidth: Appearance.spacing.xxl * 9; placeholderText: "Search apps and actions" }
                M3.SearchBar { implicitWidth: Appearance.spacing.xxl * 9; compact: true; text: "firefox" }
            }
        }
    }

    Component {
        id: tabsPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Tabs"
                guideline: "tabs"
                detail: "Tabs switch between related views. Secondary tabs have an underline; compact tabs use a pill in narrow toolbars."
            }
            PreviewCard {
                title: "Live tabs"
                M3.Tabs {
                    width: Appearance.spacing.xxl * 12
                    variant: root.sampleVariant
                    M3.Tab { variant: root.sampleVariant; text: root.sampleText; materialIcon: root.sampleIcon; enabled: root.sampleEnabled }
                    M3.Tab { variant: root.sampleVariant; text: "Stopwatch"; materialIcon: "timer" }
                }
            }
            PreviewCard {
                title: "Secondary tabs"
                M3.Tabs {
                    width: Appearance.spacing.xxl * 12
                    M3.Tab { text: "Focus" }
                    M3.Tab { text: "Break"; materialIcon: "coffee" }
                }
            }
            PreviewCard {
                title: "Compact toolbar tabs"
                M3.Tabs {
                    variant: "compact"
                    M3.Tab { variant: "compact"; text: "Shot"; materialIcon: "photo_camera" }
                    M3.Tab { variant: "compact"; text: "Record"; materialIcon: "videocam" }
                    M3.Tab { variant: "compact"; text: "Record + audio"; materialIcon: "mic" }
                }
            }
        }
    }

    Component {
        id: toolbarPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "Toolbar"
                guideline: "toolbars"
                detail: "A row of actions for the current page. The floating toolbar is an elevated pill over content, paired with a tertiary FAB beside it; the docked toolbar spans the width flat. Toggles use M3.IconButton with selectedVariant: \"tonal\", inputs use M3.ToolbarTextField."
            }
            PreviewCard {
                title: "Live toolbar"
                M3.Toolbar {
                    variant: root.sampleVariant
                    elevated: root.sampleChecked
                    width: variant === "docked" ? Appearance.spacing.xxl * 16 : implicitWidth
                    M3.IconButton { materialIcon: root.sampleIcon; tooltip: root.sampleText; enabled: root.sampleEnabled }
                    M3.IconButton { materialIcon: "shuffle"; tooltip: "Random" }
                    M3.IconButton {
                        materialIcon: "dark_mode"
                        tooltip: "Dark mode"
                        toggleable: true
                        selectedVariant: "tonal"
                        selected: root.sampleOutlined
                        onClicked: root.sampleOutlined = !root.sampleOutlined
                    }
                    M3.ToolbarTextField { placeholderText: "Search wallpapers"; enabled: root.sampleEnabled }
                }
            }
            PreviewCard {
                title: "Floating toolbar with a paired FAB"
                M3.Toolbar {
                    M3.IconButton { materialIcon: "key"; tooltip: "Key input"; toggleable: true; selectedVariant: "tonal"; selected: true }
                    M3.ToolbarTextField { placeholderText: "Paste key here" }
                    M3.IconButton { materialIcon: "check"; tooltip: "Confirm" }
                }
                M3.Fab { size: "toolbar"; variant: "tertiary"; elevated: true; iconText: "close"; tooltip: "Close" }
            }
            PreviewCard {
                title: "Docked toolbar"
                M3.Toolbar {
                    variant: "docked"
                    implicitWidth: Appearance.spacing.xxl * 16
                    M3.IconButton { materialIcon: "arrow_back"; tooltip: "Back" }
                    Item { Layout.fillWidth: true }
                    M3.IconButton { materialIcon: "edit"; tooltip: "Edit" }
                    M3.IconButton { materialIcon: "delete"; tooltip: "Delete" }
                    M3.Button { variant: "filled"; text: "Save" }
                }
            }
        }
    }

    Component {
        id: linearProgressPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "LinearProgressIndicator"
                guideline: "progress-indicators"
                detail: "Progress along a line. value from 0 to 1, wavy for the expressive track, indeterminate when there is no measurable progress."
            }
            PreviewCard {
                title: "Determinate"
                M3.LinearProgressIndicator {
                    value: root.sampleValue
                    enabled: root.sampleEnabled
                    wavy: root.sampleWavy
                }
                M3.LinearProgressIndicator { value: root.sampleValue; wavy: true }
                M3.LinearProgressIndicator { value: root.sampleValue; enabled: false }
            }
            PreviewCard {
                title: "Indeterminate"
                M3.LinearProgressIndicator {
                    width: Appearance.spacing.xxl * 8
                    indeterminate: true
                    enabled: root.sampleEnabled
                }
            }
        }
    }

    Component {
        id: circularPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "CircularProgressIndicator"
                guideline: "progress-indicators"
                detail: "Progress around a ring, or a filled pie with fill."
            }
            PreviewCard {
                title: "Live ring"
                M3.CircularProgressIndicator {
                    value: root.sampleValue
                    opacity: root.sampleEnabled ? 1 : 0.4
                }
            }
            PreviewCard {
                title: "Variants"
                M3.CircularProgressIndicator { value: 0.25 }
                M3.CircularProgressIndicator { value: 0.75; drainClockwise: true }
                M3.CircularProgressIndicator { value: 0.5; fill: true }
                M3.CircularProgressIndicator { indeterminate: true }
            }
        }
    }

    Component {
        id: loadingPage
        ColumnLayout {
            spacing: Appearance.spacing.lg
            PageHeading {
                heading: "LoadingIndicator"
                guideline: "loading-indicator"
                detail: "The expressive morphing-shape indicator for short waits where progress is unknown."
            }
            PreviewCard {
                title: "Loading"
                M3.LoadingIndicator { loading: root.sampleEnabled }
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
                    tone: root.sampleVariant
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
}
