import qs
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * The lifecycle shared by the script-driven overlay dialogs (selector, text
 * popup, pass, pinentry): the GlobalStates flag that says whether the dialog is
 * open, the window that only exists while it is, the enter/exit animation
 * handshake with the card, and the fifo writer that unblocks a waiting script.
 *
 * A panel declares its state key, its keyboard focus mode and its content:
 *
 *     OverlayDialog {
 *         id: dialog
 *         stateKey: "selectorOpen"
 *         layerNamespace: "quickshell:selector"
 *         keyboardFocus: WlrKeyboardFocus.OnDemand
 *         onDismissed: root.finish("")
 *
 *         SelectorContent { ... }
 *     }
 *
 * The content must be an OverlayDialogCard: it is animated in on open, animated
 * out on close, and unloaded once it signals closeFinished(). Reopening while
 * the exit animation is still playing reuses the same instance and slides it
 * back in, so cards reset stale input in onAboutToAnimateIn.
 */
Scope {
    id: root

    // Optional name of a GlobalStates bool holding this dialog's open state.
    // Kept during migration; new panels drive opened directly.
    property string stateKey: ""

    property string layerNamespace: "quickshell:overlayDialog"
    property var keyboardFocus: WlrKeyboardFocus.OnDemand
    // Also dismiss when something else in the shell grabs focus.
    property bool dismissOnFocusGrab: true
    // Show the dialog on every monitor instead of the compositor's chosen one.
    property bool allScreens: false

    // The dialog card. Instantiated when the dialog opens, kept alive until the
    // exit animation finishes.
    default property Component content

    // An outside click, or another panel grabbing focus. Panels answer this the
    // same way they answer a cancel.
    signal dismissed()

    property bool opened: root.stateKey.length > 0 ? (GlobalStates[root.stateKey] ?? false) : false
    // True while the exit animation plays; keeps the window loaded until it
    // finishes. Internal — panels drive the dialog through open()/close().
    property bool closing: false

    function open(): void {
        root.opened = true;
        if (root.stateKey.length > 0 && (root.stateKey in GlobalStates))
            GlobalStates[root.stateKey] = true;
    }

    function close(): void {
        // Flip the public state now, but keep the window alive to play the
        // slide-down; the card signals closeFinished when it's done.
        if (root.opened && dialogLoader.item)
            root.closing = true;
        root.opened = false;
        if (root.stateKey.length > 0 && (root.stateKey in GlobalStates))
            GlobalStates[root.stateKey] = false;
    }

    function toggle(): void {
        if (root.opened)
            root.close();
        else
            root.open();
    }

    // Write `text` as a line to `path`, so a script blocked reading the fifo it
    // handed the dialog unblocks. Panels call this on cancel as well as on
    // confirm — a reader that never unblocks hangs the script forever.
    function writeResult(path: string, text: string): void {
        if (!path || path.length === 0)
            return;
        // A caller can disappear while the writer is still blocked on its fifo.
        // Stop that abandoned writer before reusing the Process for a new one.
        resultWriter.running = false;
        resultWriter.outText = text ?? "";
        resultWriter.outPath = path;
        resultWriter.running = true;
    }

    // Reopened mid-close: the window is still loaded, so cancel the exit
    // instead of waiting it out (the card slides back in below).
    onOpenedChanged: if (root.opened) root.closing = false

    Process {
        id: resultWriter

        property string outPath: ""
        property string outText: ""

        command: ["bash", "-c", `printf '%s\n' '${StringUtils.shellSingleQuoteEscape(resultWriter.outText)}' > '${StringUtils.shellSingleQuoteEscape(resultWriter.outPath)}'`]
    }

    Loader {
        id: dialogLoader

        active: root.opened || root.closing

        sourceComponent: Variants {
            // One window on the compositor's chosen output unless the dialog
            // asked for every monitor; a null screen means "you pick".
            model: root.allScreens ? Quickshell.screens : [null]

            delegate: OverlayDialogWindow {
                id: dialogWindow

                required property var modelData
                // Tracks the public flag: false means the dialog is on its way out.
                readonly property bool showing: root.opened

                screen: modelData
                layerNamespace: root.layerNamespace
                keyboardFocus: root.keyboardFocus
                dismissOnFocusGrab: root.dismissOnFocusGrab
                // Dim everything behind the dialog and fade the scrim with it.
                scrimOpacity: cardLoader.item?.opacity ?? 0
                onDismissed: root.dismissed()

                onShowingChanged: {
                    if (dialogWindow.showing)
                        cardLoader.item?.animateIn();
                    else if (cardLoader.item)
                        cardLoader.item.animateOut();
                    else
                        root.closing = false; // nothing to animate; don't strand the window
                }

                Loader {
                    id: cardLoader

                    anchors.centerIn: parent
                    focus: true
                    sourceComponent: root.content

                    // The card animates itself in on load; it tells us when the
                    // slide-down is done so the window can go away.
                    Connections {
                        target: cardLoader.item
                        ignoreUnknownSignals: true

                        function onCloseFinished(): void {
                            root.closing = false;
                        }
                    }
                }
            }
        }
    }
}
