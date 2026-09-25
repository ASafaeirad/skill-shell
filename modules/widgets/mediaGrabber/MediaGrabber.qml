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

    function open(): void {
        root.opened = true;
        dialog.open();
    }

    function close(): void {
        dialog.close();
        root.opened = false;
    }

    function toggle(): void {
        if (dialog.opened)
            root.close();
        else
            root.open();
    }

    // Open on a link and start fetching it straight away.
    function grab(url: string): void {
        YtDlp.reset();
        YtDlp.url = url;
        root.open();
        YtDlp.fetch();
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
