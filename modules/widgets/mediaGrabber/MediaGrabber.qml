import QtQml
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.modules.common.widgets

/**
 * Media grabber: paste a YouTube, Instagram or X link and download it with
 * yt-dlp. The download lives in the YtDlp service, so closing the panel does
 * not stop it.
 */
Panel {
    id: root
    name: "mediaGrabber"
    description: "Toggle media grabber"
    manageIpc: false
    property bool resetAfterDownload: false

    function showDialog(): void {
        root.opened = true;
        dialog.open();
    }

    function open(): void {
        root.resetAfterDownload = false;
        root.showDialog();
        if (YtDlp.view === "idle")
            YtDlp.autofillUrlFromClipboard();
    }

    function close(): void {
        dialog.close();
        root.opened = false;
        if (YtDlp.view === "downloading")
            root.resetAfterDownload = true;
        else
            YtDlp.resetPanel();
    }

    function toggle(): void {
        if (dialog.opened)
            root.close();
        else
            root.open();
    }

    // Open on a link and start fetching it straight away.
    function grab(url: string): void {
        root.resetAfterDownload = false;
        YtDlp.reset();
        YtDlp.url = url;
        root.showDialog();
        YtDlp.fetch();
    }

    Connections {
        target: YtDlp

        function onViewChanged(): void {
            if (root.resetAfterDownload && YtDlp.view !== "downloading") {
                root.resetAfterDownload = false;
                YtDlp.resetPanel();
            }
        }
    }

    OverlayDialog {
        id: dialog

        layerNamespace: "quickshell:mediaGrabber"
        keyboardFocus: WlrKeyboardFocus.Exclusive
        onDismissed: root.close()

        MediaGrabberContent {
            onCloseRequested: root.close()
        }
    }

    IpcHandler {
        target: "mediaGrabber"

        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        //   qs -c skill ipc call mediaGrabber grab 'https://youtu.be/…'
        function grab(url: string): void {
            root.grab(url);
        }
    }
}
