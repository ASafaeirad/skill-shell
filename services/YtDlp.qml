pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * yt-dlp front end for the media grabber panel: fetches a link's metadata,
 * downloads it in the chosen format and quality into the Downloads folder, and
 * reports progress. Lives in a singleton so a download keeps going while the
 * panel is closed.
 *
 * The flow is a single state machine, `view`:
 *   idle → fetching → ready → downloading → done
 * with `error` reachable from fetching and downloading. Fetching starts on its
 * own once a pasted or typed link settles, so there is no button to press.
 */
Singleton {
    id: root

    // "idle" | "fetching" | "ready" | "downloading" | "done" | "error"
    property string view: "idle"
    property string url: ""
    // "video" | "audio"
    property string format: "video"
    // Key within the current format's quality list; empty selects its first entry.
    property string quality: ""

    // Metadata from the fetch step.
    property string title: ""
    property string uploader: ""
    property string duration: ""
    property real durationSeconds: 0
    property string thumbnail: ""
    property string extractor: ""
    property string mediaId: ""
    // [{ key, label, height, bytes }], best first.
    property var videoQualities: []
    // [{ key, label, height, bytes }]
    property var audioQualities: []
    // The link the current metadata describes, so a settled link fetches once.
    property string fetchedUrl: ""

    property real progress: 0 // 0..1 across every stream of the download
    property string speed: ""
    property string eta: ""
    property string savedPath: ""

    // Which step failed, so Retry repeats it: "fetch" | "download".
    property string failedStep: ""
    property string errorMessage: ""

    // How long a link has to sit still before it is fetched.
    readonly property int autoFetchDelay: 450
    // Sites list dozens of heights; the picker only shows the best few.
    readonly property int maxQualityCount: 5

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

    readonly property var qualities: root.format === "audio" ? root.audioQualities : root.videoQualities
    readonly property var selectedQuality: {
        const list = root.qualities;
        if (!list || list.length === 0)
            return null;
        return list.find(entry => entry.key === root.quality) ?? list[0];
    }
    readonly property real selectedSize: root.selectedQuality?.bytes ?? 0
    readonly property string sizeLabel: root.selectedSize > 0 ? `~${root.formatBytes(root.selectedSize)}` : ""

    onUrlChanged: root.linkChanged()

    // Reacting to a new link: drop the old metadata and queue a fetch.
    function linkChanged(): void {
        if (root.view === "downloading")
            return;
        const link = root.url.trim();
        if (link.length > 0 && link === root.fetchedUrl && root.view !== "idle")
            return;
        abortFetch();
        autoFetchTimer.stop();
        root.fetchedUrl = "";
        root.failedStep = "";
        root.errorMessage = "";
        clearMetadata();
        if (link.length === 0) {
            root.view = "idle";
            return;
        }
        // Show the spinner while the link is still being typed.
        root.view = "fetching";
        autoFetchTimer.restart();
    }

    function clearMetadata(): void {
        root.title = "";
        root.uploader = "";
        root.duration = "";
        root.durationSeconds = 0;
        root.thumbnail = "";
        root.extractor = "";
        root.mediaId = "";
        root.videoQualities = [];
        root.audioQualities = [];
        root.quality = "";
        root.progress = 0;
        root.speed = "";
        root.eta = "";
        root.savedPath = "";
    }

    function fetch(): void {
        const url = root.url.trim();
        if (url.length === 0)
            return;
        if (fetchProcess.running) {
            // Come back for it once the stale fetch is gone.
            abortFetch();
            root.view = "fetching";
            autoFetchTimer.restart();
            return;
        }
        autoFetchTimer.stop();
        clearMetadata();
        root.failedStep = "";
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
            ...root.formatArgs(), "--", url];
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
        abortFetch();
        autoFetchTimer.stop();
        downloadProcess.running = false;
    }

    // Kill an in-flight fetch without its exit counting as a failure.
    function abortFetch(): void {
        if (!fetchProcess.running)
            return;
        fetchProcess.aborted = true;
        fetchProcess.running = false;
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

    // Back to an empty link, which drops the metadata with it.
    function clearLink(): void {
        cancel();
        root.url = "";
        root.fetchedUrl = "";
        clearMetadata();
        root.view = "idle";
    }

    function resetPanel(): void {
        autoPasteProcess.acceptResult = false;
        autoPasteProcess.running = false;
        clearLink();
        root.format = "video";
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

    function formatArgs(): var {
        if (root.format === "audio") {
            if (root.selectedQuality?.key === "mp3")
                return ["-f", "ba/b", "-x", "--audio-format", "mp3", "--audio-quality", "0"];
            return ["-f", "ba/b", "-x", "--audio-format", "best"];
        }
        const height = root.selectedQuality?.height ?? 0;
        const cap = height > 0 ? `[height<=${height}]` : "";
        return ["-f", `bv*${cap}[ext=mp4]+ba[ext=m4a]/b${cap}[ext=mp4]/bv*${cap}+ba/b${cap}/b`,
            "--merge-output-format", "mp4"];
    }

    // Turn the fetched format table into the two quality pickers the panel shows.
    function collectQualities(info: var): void {
        const streams = Array.isArray(info.formats) ? info.formats : [];
        const sizeOf = stream => stream.filesize ?? stream.filesize_approx ?? 0;
        const hasVideo = stream => (stream.vcodec ?? "none") !== "none";
        const hasAudio = stream => (stream.acodec ?? "none") !== "none";

        const audioStreams = streams.filter(stream => !hasVideo(stream) && hasAudio(stream));
        const bestAudio = audioStreams.reduce((best, stream) => !best || sizeOf(stream) > sizeOf(best) ? stream : best, null);
        const audioBytes = bestAudio ? sizeOf(bestAudio) : 0;

        // One entry per height, sized like the stream the download would pick:
        // the mp4 variant where the site offers one, the largest otherwise.
        const byHeight = {};
        for (const stream of streams.filter(candidate => hasVideo(candidate) && candidate.height > 0)) {
            const entry = byHeight[stream.height] ?? {
                mp4: 0,
                any: 0
            };
            const bytes = sizeOf(stream) + (hasAudio(stream) ? 0 : audioBytes);
            entry.any = Math.max(entry.any, bytes);
            if (stream.ext === "mp4")
                entry.mp4 = Math.max(entry.mp4, bytes);
            byHeight[stream.height] = entry;
        }
        const heights = Object.keys(byHeight).map(Number).sort((a, b) => b - a).slice(0, root.maxQualityCount);
        root.videoQualities = heights.length > 0 ? heights.map(height => ({
            key: String(height),
            label: `${height}p`,
            height: height,
            bytes: byHeight[height].mp4 || byHeight[height].any
        })) : [
            {
                key: "best",
                label: "Best",
                height: 0,
                bytes: sizeOf(info)
            }
        ];
        root.audioQualities = [
            {
                key: "best",
                label: root.audioCodecLabel(bestAudio?.acodec ?? ""),
                height: 0,
                bytes: audioBytes
            },
            {
                key: "mp3",
                label: "MP3 320",
                height: 0,
                // 320 kbit/s is 40 kB of audio per second.
                bytes: Math.round(root.durationSeconds * 40000)
            }
        ];
    }

    function audioCodecLabel(codec: string): string {
        const key = codec.toLowerCase();
        if (key.startsWith("opus"))
            return "Opus";
        if (key.startsWith("mp4a") || key.startsWith("aac"))
            return "AAC";
        if (key.startsWith("mp3"))
            return "MP3";
        if (key.startsWith("vorbis"))
            return "Vorbis";
        if (key.startsWith("flac"))
            return "FLAC";
        return "Original";
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

    function formatBytes(bytes: real): string {
        if (!(bytes > 0))
            return "";
        const units = ["B", "KB", "MB", "GB"];
        let value = bytes;
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit += 1;
        }
        return `${unit === 0 || value >= 100 ? Math.round(value) : value.toFixed(1)} ${units[unit]}`;
    }

    function fail(step: string, stderr: string): void {
        root.failedStep = step;
        root.errorMessage = root.lastError(stderr);
        root.view = "error";
    }

    Timer {
        id: autoFetchTimer

        interval: root.autoFetchDelay
        onTriggered: {
            if (fetchProcess.running) {
                root.abortFetch();
                autoFetchTimer.restart();
                return;
            }
            root.fetch();
        }
    }

    Process {
        id: fetchProcess

        // Set while a fetch is killed on purpose, so its exit isn't a failure.
        property bool aborted: false

        stdout: StdioCollector {
            id: fetchOutput
        }
        stderr: StdioCollector {
            id: fetchErrors
        }

        onExited: (exitCode, exitStatus) => {
            if (fetchProcess.aborted) {
                fetchProcess.aborted = false;
                return;
            }
            if (root.view !== "fetching")
                return; // cancelled
            if (exitCode !== 0)
                return root.fail("fetch", fetchErrors.text);
            try {
                const info = JSON.parse(fetchOutput.text);
                root.title = info.title ?? info.fulltitle ?? info.id ?? "";
                root.uploader = info.uploader ?? info.channel ?? info.uploader_id ?? "";
                root.durationSeconds = info.duration ?? 0;
                root.duration = root.formatDuration(root.durationSeconds);
                root.thumbnail = info.thumbnail ?? "";
                root.extractor = info.extractor_key ?? info.extractor ?? "";
                root.mediaId = info.id ?? "";
                root.collectQualities(info);
                root.fetchedUrl = root.url.trim();
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
