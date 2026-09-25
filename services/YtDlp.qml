pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * yt-dlp front end for the media grabber panel: fetches a link's metadata,
 * downloads it at the chosen quality into the Downloads folder, and reports
 * progress. Lives in a singleton so a download keeps going while the panel is
 * closed.
 *
 * The flow is a single state machine, `view`:
 *   idle → fetching → ready → downloading → done
 * with `error` reachable from fetching and downloading.
 */
Singleton {
    id: root

    // "idle" | "fetching" | "ready" | "downloading" | "done" | "error"
    property string view: "idle"
    property string url: ""
    // "best" | "medium" | "audio"
    property string quality: "best"

    // Metadata from the fetch step.
    property string title: ""
    property string duration: ""
    property string thumbnail: ""
    property string extractor: ""
    property string mediaId: ""

    property real progress: 0 // 0..1 across every stream of the download
    property string speed: ""
    property string eta: ""
    property string savedPath: ""

    // Which step failed, so Retry repeats it: "fetch" | "download".
    property string failedStep: ""
    property string errorMessage: ""

    readonly property string outputDirectory: FileUtils.trimFileProtocol(Directories.downloads)

    readonly property string platformIcon: {
        const key = root.extractor.toLowerCase();
        if (key.startsWith("youtube"))
            return "smart_display";
        if (key.startsWith("instagram"))
            return "photo_camera";
        if (key === "twitter" || key.startsWith("x"))
            return "tag";
        return "public";
    }
    readonly property string platformLabel: {
        const key = root.extractor.toLowerCase();
        if (key.startsWith("youtube"))
            return "YouTube";
        if (key.startsWith("instagram"))
            return "Instagram";
        if (key === "twitter")
            return "X";
        return root.extractor;
    }
    readonly property string qualityLabel: root.quality === "best" ? "Best quality · MP4"
        : root.quality === "medium" ? "Medium quality · MP4" : "Audio only · M4A"

    function fetch(): void {
        const url = root.url.trim();
        if (url.length === 0 || fetchProcess.running)
            return;
        root.title = "";
        root.duration = "";
        root.thumbnail = "";
        root.extractor = "";
        root.mediaId = "";
        root.errorMessage = "";
        root.view = "fetching";
        fetchProcess.command = ["yt-dlp", "--dump-single-json", "--no-playlist", "--no-warnings", "--", url];
        fetchProcess.running = true;
    }

    function download(): void {
        const url = root.url.trim();
        if (url.length === 0 || downloadProcess.running)
            return;
        root.progress = 0;
        root.speed = "";
        root.eta = "";
        root.savedPath = "";
        root.errorMessage = "";
        root.view = "downloading";
        downloadProcess.command = ["yt-dlp", "--no-playlist", "--no-warnings", "--newline", "--progress",
            "--progress-template", "download:progress %(info.format_id)s|%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s",
            "--print", "before_dl:formats %(format_id)s",
            "--print", "after_move:saved %(filepath)s",
            "--no-simulate",
            "-P", root.outputDirectory,
            "-o", "%(title).150B [%(id)s].%(ext)s",
            ...root.formatArgs(root.quality), "--", url];
        downloadProcess.running = true;
    }

    function retry(): void {
        if (root.failedStep === "download")
            download();
        else
            fetch();
    }

    // Stop whatever is running without changing the view.
    function cancel(): void {
        fetchProcess.running = false;
        downloadProcess.running = false;
    }

    function cancelDownload(): void {
        cancel();
        root.view = "ready";
        removePartialFiles();
    }

    // yt-dlp keeps .part files to resume from; a cancelled download shouldn't.
    function removePartialFiles(): void {
        if (root.mediaId.length === 0)
            return;
        Quickshell.execDetached(["bash", "-c", 'sleep 1; rm -f -- "$1"/*"[$2]".*.part "$1"/*"[$2]".*.ytdl',
            "remove-partial", root.outputDirectory, root.mediaId]);
    }

    function reset(): void {
        cancel();
        root.view = "idle";
    }

    function resetPanel(): void {
        autoPasteProcess.acceptResult = false;
        autoPasteProcess.running = false;
        reset();
        root.url = "";
        root.quality = "best";
        root.title = "";
        root.duration = "";
        root.thumbnail = "";
        root.extractor = "";
        root.mediaId = "";
        root.progress = 0;
        root.speed = "";
        root.eta = "";
        root.savedPath = "";
        root.failedStep = "";
        root.errorMessage = "";
    }

    function pasteUrl(): void {
        pasteProcess.running = true;
    }

    function autofillUrlFromClipboard(): void {
        autoPasteProcess.acceptResult = false;
        autoPasteProcess.running = false;
        autoPasteProcess.previousUrl = root.url;
        autoPasteProcess.acceptResult = true;
        autoPasteProcess.running = true;
    }

    function showInFolder(): void {
        if (root.savedPath.length === 0)
            return;
        // Highlight the file where the file manager supports it; open the folder otherwise.
        Quickshell.execDetached(["bash", "-c",
            'dbus-send --session --print-reply --dest=org.freedesktop.FileManager1 /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$1" string:"" >/dev/null 2>&1 || xdg-open "$(dirname "$1")"',
            "show-in-folder", root.savedPath]);
    }

    function formatArgs(quality: string): var {
        if (quality === "audio")
            return ["-f", "ba[ext=m4a]/ba", "-x", "--audio-format", "m4a"];
        const cap = quality === "medium" ? "[height<=720]" : "";
        return ["-f", `bv*${cap}[ext=mp4]+ba[ext=m4a]/b${cap}[ext=mp4]/bv*${cap}+ba/b${cap}/b`,
            "--merge-output-format", "mp4"];
    }

    function lastError(text: string): string {
        const lines = text.split("\n").map(line => line.trim()).filter(line => line.startsWith("ERROR:"));
        if (lines.length === 0)
            return "";
        return lines[lines.length - 1].replace(/^ERROR:\s*/, "").replace(/\s*\(caused by .*\)$/, "");
    }

    function formatDuration(seconds: real): string {
        if (!(seconds > 0))
            return "";
        const total = Math.round(seconds);
        const h = Math.floor(total / 3600);
        const m = Math.floor(total % 3600 / 60);
        const s = String(total % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${s}` : `${m}:${s}`;
    }

    function fail(step: string, stderr: string): void {
        root.failedStep = step;
        root.errorMessage = root.lastError(stderr);
        root.view = "error";
    }

    Process {
        id: fetchProcess

        stdout: StdioCollector {
            id: fetchOutput
        }
        stderr: StdioCollector {
            id: fetchErrors
        }

        onExited: (exitCode, exitStatus) => {
            if (root.view !== "fetching")
                return; // cancelled
            if (exitCode !== 0)
                return root.fail("fetch", fetchErrors.text);
            try {
                const info = JSON.parse(fetchOutput.text);
                root.title = info.title ?? info.fulltitle ?? info.id ?? "";
                root.duration = root.formatDuration(info.duration);
                root.thumbnail = info.thumbnail ?? "";
                root.extractor = info.extractor_key ?? info.extractor ?? "";
                root.mediaId = info.id ?? "";
                root.view = "ready";
            } catch (e) {
                root.fail("fetch", "");
            }
        }
    }

    Process {
        id: downloadProcess

        property string errors: ""
        // Format ids of the streams yt-dlp downloads one after another
        // (video then audio when merging), to report one overall progress.
        property var streams: []

        onStarted: {
            downloadProcess.errors = "";
            downloadProcess.streams = [];
        }

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("formats ")) {
                    downloadProcess.streams = line.slice(8).split("+");
                } else if (line.startsWith("progress ")) {
                    const [format, percent, speed, eta] = line.slice(9).split("|").map(part => part.trim());
                    const value = parseFloat(percent);
                    const count = Math.max(1, downloadProcess.streams.length);
                    const index = Math.max(0, downloadProcess.streams.indexOf(format));
                    if (!isNaN(value))
                        root.progress = Math.min(1, (index + value / 100) / count);
                    root.speed = speed === "Unknown B/s" || speed === "NA" ? "" : speed;
                    root.eta = eta === "Unknown" || eta === "NA" ? "" : eta;
                } else if (line.startsWith("saved ")) {
                    root.savedPath = line.slice(6);
                }
            }
        }
        stderr: SplitParser {
            onRead: line => downloadProcess.errors += line + "\n"
        }

        onExited: (exitCode, exitStatus) => {
            if (root.view !== "downloading")
                return; // cancelled
            if (exitCode !== 0)
                return root.fail("download", downloadProcess.errors);
            root.progress = 1;
            root.view = "done";
        }
    }

    Process {
        id: pasteProcess

        command: ["wl-paste", "--no-newline", "--type", "text"]
        stdout: StdioCollector {
            id: pasteOutput

            onStreamFinished: {
                const text = pasteOutput.text.trim();
                if (text.length > 0)
                    root.url = text;
            }
        }
    }

    Process {
        id: autoPasteProcess

        property string previousUrl: ""
        property bool acceptResult: false

        command: ["wl-paste", "--no-newline", "--type", "text"]
        stdout: StdioCollector {
            id: autoPasteOutput

            onStreamFinished: {
                const text = autoPasteOutput.text.trim();
                if (autoPasteProcess.acceptResult && root.view === "idle"
                        && root.url === autoPasteProcess.previousUrl
                        && /^https?:\/\/[^\s/?#]+(?:[/?#]\S*)?$/i.test(text))
                    root.url = text;
                autoPasteProcess.acceptResult = false;
            }
        }
    }
}
