import qs.modules.common
import qs.modules.common.widgets

/** Supporting text for an M3.Dialog or M3.DialogCard. */
WindowDialogParagraph {
    property bool error: false
    color: error ? Appearance.m3colors.m3error : Appearance.colors.colOnSurfaceVariant
}
