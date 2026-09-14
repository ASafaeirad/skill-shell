pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    signal closeRequested

    property var entries: []
    property string loadedEntry: ""
    property string secret: ""
    property var fields: []
    property bool hasOtp: false
    property var otpEntries: ({})
    property bool loading: false
    property string errorText: ""
    property string revealedEntry: ""
    property string pendingAction: ""
    property string clipboardSecret: ""
    property string statusMessage: ""

    readonly property var preparedEntries: entries.map(entry => ({
        name: Fuzzy.prepare(entry.name),
        entry: entry
    }))

    function iconFor(name) {
        const group = name.split("/")[0].toLowerCase();
        if (["web", "website", "sites"].includes(group))
            return "language";
        if (["ssh", "server", "servers"].includes(group))
            return "terminal";
        if (["aws", "cloud", "infra"].includes(group))
            return "cloud";
        if (["mail", "email"].includes(group))
            return "mail";
        if (["bank", "finance"].includes(group))
            return "account_balance";
        if (["wifi", "network"].includes(group))
            return "wifi";
        if (["archive", "old"].includes(group))
            return "archive";
        return "key";
    }

    function refresh() {
        entriesProc.running = false;
        entriesProc.running = true;
    }

    function isIgnored(name, ignoredPatterns) {
        return ignoredPatterns.some(pattern => {
            if (typeof pattern !== "string" || pattern.trim().length === 0)
                return false;
            try {
                return new RegExp(pattern, "i").test(name);
            } catch (error) {
                return false;
            }
        });
    }

    function fuzzyQuery(search, showIgnored = false, ignoredPatterns = []) {
        const visibleEntries = showIgnored ? root.preparedEntries
                                           : root.preparedEntries.filter(item => !root.isIgnored(item.entry.name,
                                                                                                  ignoredPatterns));
        const query = search.trim();
        if (query.length === 0)
            return visibleEntries.map(item => item.entry);
        return Fuzzy.go(query, visibleEntries, {
                            all: true,
                            key: "name"
                        }).map(result => result.obj.entry);
    }

    function clearSecrets() {
        detailsProc.running = false;
        otpProc.running = false;
        root.loadedEntry = "";
        root.secret = "";
        root.fields = [];
        root.hasOtp = false;
        root.loading = false;
        root.pendingAction = "";
        root.revealedEntry = "";
        revealTimer.stop();
    }

    function loadEntry(name, action = "") {
        if (!name)
            return;
        if (root.loadedEntry === name && root.secret.length > 0) {
            if (action.length > 0)
                root.runAction(action, name);
            return;
        }

        detailsProc.running = false;
        root.loadedEntry = "";
        root.secret = "";
        root.fields = [];
        root.hasOtp = false;
        root.errorText = "";
        root.loading = true;
        root.pendingAction = action;
        detailsProc.entryName = name;
        detailsProc.command = ["pass", "show", "--", name];
        detailsProc.running = true;
    }

    function requestAction(action, name) {
        if (!name)
            return;
        if (action === "otp") {
            copyOtp(name);
            return;
        }
        loadEntry(name, action);
    }

    function runAction(action, name) {
        if (action === "copy") {
            root.copyToClipboard(root.secret, "Password copied");
            root.closeRequested();
        } else if (action === "reveal") {
            if (root.revealedEntry === name) {
                root.revealedEntry = "";
                revealTimer.stop();
            } else {
                root.revealedEntry = name;
                revealTimer.restart();
            }
        } else if (action === "autotype") {
            autotypeTimer.payload = root.secret;
            autotypeTimer.restart();
            root.closeRequested();
        }
    }

    function copyOtp(name) {
        otpProc.running = false;
        root.errorText = "";
        otpProc.entryName = name;
        otpProc.command = ["pass", "otp", "code", "--clip", name];
        otpProc.running = true;
    }

    function copyToClipboard(value, message) {
        if (!value)
            return;
        Quickshell.clipboardText = value;
        root.clipboardSecret = value;
        clipboardClearTimer.restart();
        root.showStatus(message);
    }

    function showStatus(message) {
        root.statusMessage = message;
        statusTimer.restart();
    }

    function parseDetails(name, text) {
        const lines = text.replace(/\r/g, "").split("\n");
        root.loadedEntry = name;
        root.secret = lines.shift() ?? "";
        const parsed = [];
        let noteLines = [];
        let otp = false;

        for (const line of lines) {
            if (line.startsWith("otpauth://")) {
                otp = true;
                continue;
            }
            const separator = line.indexOf(":");
            if (separator > 0 && !line.includes("://")) {
                const key = line.slice(0, separator).trim();
                const value = line.slice(separator + 1).trim();
                if (key.length > 0 && value.length > 0)
                    parsed.push({
                                    key: key,
                                    value: value
                                });
            } else if (line.trim().length > 0) {
                noteLines.push(line.trim());
            }
        }
        if (noteLines.length > 0)
            parsed.push({
                            key: "notes",
                            value: noteLines.join(" · ")
                        });

        root.fields = parsed;
        root.hasOtp = otp;
        if (otp) {
            const knownOtpEntries = Object.assign({}, root.otpEntries);
            knownOtpEntries[name] = true;
            root.otpEntries = knownOtpEntries;
        }
        root.loading = false;
        const action = root.pendingAction;
        root.pendingAction = "";
        if (action.length > 0)
            root.runAction(action, name);
    }

    Process {
        id: entriesProc
        command: ["sh", "-c",
            "store=\"${PASSWORD_STORE_DIR:-$HOME/.password-store}\"; [ -d \"$store\" ] || exit 0; find \"$store\" -type f -name '*.gpg' -printf '%P\\t%T@\\n' | LC_ALL=C sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = [];
                for (const line of text.split("\n")) {
                    if (!line.trim())
                        continue;
                    const tab = line.lastIndexOf("\t");
                    if (tab < 0)
                        continue;
                    const path = line.slice(0, tab).replace(/\.gpg$/, "");
                    const parts = path.split("/");
                    parsed.push({
                                    name: path,
                                    topGroup: parts.length > 1 ? parts[0] : "Other",
                                    relativeName: parts.length > 1 ? parts.slice(1).join("/") : path,
                                    label: parts[parts.length - 1],
                                    icon: root.iconFor(path),
                                    modified: Number(line.slice(tab + 1)) * 1000
                                });
                }
                parsed.sort((left, right) => {
                    const leftGroup = left.topGroup === "Other" ? "\uffff" : left.topGroup.toLowerCase();
                    const rightGroup = right.topGroup === "Other" ? "\uffff" : right.topGroup.toLowerCase();
                    const groupOrder = leftGroup.localeCompare(rightGroup);
                    return groupOrder !== 0 ? groupOrder : left.relativeName.localeCompare(
                                                  right.relativeName);
                });
                root.entries = parsed;
            }
        }
    }

    Process {
        id: detailsProc
        property string entryName: ""
        stdout: StdioCollector {
            onStreamFinished: root.parseDetails(detailsProc.entryName, text)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.loading = false;
                root.errorText = "Could not unlock this entry";
                root.pendingAction = "";
            }
        }
    }

    Process {
        id: otpProc
        property string entryName: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.errorText = "This entry has no usable OTP";
                root.statusMessage = "";
                return;
            }
            root.showStatus("OTP copied");
            root.closeRequested();
        }
    }

    Process {
        id: autotypeProc
        command: ["wtype", "-"]
        stdinEnabled: true
        property string payload: ""
        onRunningChanged: {
            if (!running)
                return;
            write(payload);
            payload = "";
            stdinEnabled = false;
        }
    }

    Timer {
        id: autotypeTimer
        property string payload: ""
        interval: Appearance.animation.elementMoveExit.duration
        onTriggered: {
            autotypeProc.running = false;
            autotypeProc.payload = payload;
            payload = "";
            autotypeProc.stdinEnabled = true;
            autotypeProc.running = true;
            root.clearSecrets();
        }
    }

    Timer {
        id: revealTimer
        interval: Appearance.animation.elementMove.duration * 16
        onTriggered: root.revealedEntry = ""
    }

    Timer {
        id: clipboardClearTimer
        interval: Appearance.animation.elementMove.duration * 90
        onTriggered: {
            if (Quickshell.clipboardText === root.clipboardSecret)
                Quickshell.clipboardText = "";
            root.clipboardSecret = "";
        }
    }

    Timer {
        id: statusTimer
        interval: Appearance.animation.elementMove.duration * 4
        onTriggered: root.statusMessage = ""
    }
}
