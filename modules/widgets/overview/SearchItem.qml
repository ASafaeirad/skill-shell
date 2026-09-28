// pragma NativeMethodBehavior: AcceptThisObject
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.m3 as M3
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

M3.ListItem {
    id: root
    property LauncherSearchResult entry
    property string query
    property bool entryShown: entry?.shown ?? true
    property string itemType: entry?.type ?? "App"
    property string itemName: entry?.name ?? ""
    property var iconType: entry?.iconType
    property string iconName: entry?.iconName ?? ""
    property var itemExecute: entry?.execute
    // The monospace font renders Arabic-script text with broken, fixed-width glyphs;
    // the main family falls back to the proper Persian font instead
    property bool hasArabicScript: /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/.test(entry?.name ?? "")
    property var fontType: switch(entry?.fontType) {
        case LauncherSearchResult.FontType.Monospace:
            return root.hasArabicScript ? "main" : "monospace"
        case LauncherSearchResult.FontType.Normal:
            return "main"
        default:
            return "main"
    }
    property string itemClickActionName: entry?.verb ?? "Open"
    property string bigText: entry?.iconType === LauncherSearchResult.IconType.Text ? entry?.iconName ?? "" : ""
    property string materialSymbol: entry.iconType === LauncherSearchResult.IconType.Material ? entry?.iconName ?? "" : ""
    property string cliphistRawString: entry?.rawValue ?? ""
    property bool blurImage: entry?.blurImage ?? false

    visible: root.entryShown
    selected: root.hovered || root.focus
    density: -3
    overline: root.itemType && root.itemType != "App" ? root.itemType : ""
    leadingIcon: root.materialSymbol
    leadingIconSource: root.iconType === LauncherSearchResult.IconType.System ? Quickshell.iconPath(root.iconName, "image-missing") : ""
    leadingText: root.bigText
    text: root.selected ? StringUtils.escapeHtml(root.itemName) : root.displayContent
    textFormat: Text.StyledText // RichText also works, but StyledText ensures elide work
    monospace: root.fontType === "monospace"
    trailingText: root.selected ? root.itemClickActionName : ""

    readonly property string highlightPrefix: `<u><font color="${Appearance.colors.colPrimary}">`
    readonly property string highlightSuffix: `</font></u>`
    // Note that this highlighting is independent from the search
    // It's close, but does not accurately represent how the fuzzy algorithm works
    function highlightContent(content, query) {
        if (!query || query.length === 0 || content == query || fontType === "monospace")
            return StringUtils.escapeHtml(content);

        let contentLower = content.toLowerCase();
        let queryLower = query.toLowerCase();

        let result = "";
        let lastIndex = 0;
        let qIndex = 0;

        for (let i = 0; i < content.length && qIndex < query.length; i++) {
            if (contentLower[i] === queryLower[qIndex]) {
                // Add non-highlighted part (escaped)
                if (i > lastIndex)
                    result += StringUtils.escapeHtml(content.slice(lastIndex, i));
                // Add highlighted character (escaped)
                result += root.highlightPrefix + StringUtils.escapeHtml(content[i]) + root.highlightSuffix;
                lastIndex = i + 1;
                qIndex++;
            }
        }
        // Add the rest of the string (escaped)
        if (lastIndex < content.length)
            result += StringUtils.escapeHtml(content.slice(lastIndex));

        return result;
    }
    property string displayContent: highlightContent(root.itemName, root.query)

    property list<string> urls: {
        if (!root.itemName) return [];
        // Regular expression to match URLs
        const urlRegex = /https?:\/\/[^\s<>"{}|\\^`[\]]+/gi;
        const matches = root.itemName?.match(urlRegex)
            ?.filter(url => !url.includes("…")) // Elided = invalid
        return matches ? matches : [];
    }
    

    onClicked: {
        GlobalStates.search?.close()
        root.itemExecute()
    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Delete && event.modifiers === Qt.ShiftModifier) {
            const deleteAction = root.entry.actions.find(action => action.name == "Delete");

            if (deleteAction) {
                deleteAction.execute()
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked()
            event.accepted = true;
        }
    }

    headlineLeadingData: Row {
        spacing: Appearance.spacing.xs
        MaterialSymbol { // Checkmark for copied clipboard entry
            visible: root.itemName == Quickshell.clipboardText && root.cliphistRawString
            text: "check_circle"
            fill: 1
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colPrimary
        }
        Repeater { // Favicons for links
            model: root.query == root.itemName ? [] : root.urls
            Favicon {
                required property var modelData
                size: Appearance.font.pixelSize.larger
                url: modelData
            }
        }
    }

    supportingData: Loader { // Clipboard image preview
        id: imagePreviewLoader
        Layout.fillWidth: true
        active: root.cliphistRawString && Cliphist.entryIsImage(root.cliphistRawString)
        sourceComponent: CliphistImage {
            entry: root.cliphistRawString
            maxWidth: imagePreviewLoader.width
            maxHeight: 140
            blur: root.blurImage
        }
    }

    Repeater {
        model: (root.entry.actions ?? []).slice(0, 4)
        delegate: M3.IconButton {
            required property var modelData
            readonly property bool systemIcon: modelData.iconType === LauncherSearchResult.IconType.System && (modelData.iconName ?? "") !== ""
            materialIcon: systemIcon ? "" : (modelData.iconName || "video_settings")
            iconSource: systemIcon ? Quickshell.iconPath(modelData.iconName) : ""
            tooltip: modelData.name
            onClicked: modelData.execute()
        }
    }
}
