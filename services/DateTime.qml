pragma Singleton
pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    readonly property string shortDateFormat: "dd/MM"
    readonly property string dateWithYearFormat: "dd/MM/yyyy"
    readonly property string dateFormat: "dd/MM, ddd"

    property var clock: SystemClock {
        id: clock
        precision: {
            if (Config.options.time.secondPrecision || GlobalStates.screenLocked)
                return SystemClock.Seconds;
            return SystemClock.Minutes;
        }
    }
    property string time: Qt.locale().toString(clock.date, Config.options?.time.format ?? "hh:mm")
    property string shortDate: Qt.locale().toString(clock.date, root.shortDateFormat)
    property string date: Qt.locale().toString(clock.date, root.dateWithYearFormat)
    property string longDate: Qt.locale().toString(clock.date, root.dateFormat)
    property string collapsedCalendarFormat: Qt.locale().toString(clock.date, "dddd, MMMM dd")
    property string localTimeZone: Qt.locale().toString(clock.date, "t")
    property string worldClockTime: "--:--"
    property string worldClockAbbreviation: ""
    property string worldClockWeekday: ""
    property string uptime: "0h, 0m"

    readonly property string worldClockTimeZone: {
        const configured = Config.options?.time.worldClock.timeZone?.trim() ?? "";
        return configured.length > 0 ? configured : "America/New_York";
    }
    readonly property string worldClockLocation: {
        const segments = worldClockTimeZone.split("/");
        return segments[segments.length - 1].replace(/_/g, " ");
    }
    readonly property string worldClockDateFormat: {
        switch (Config.options?.time.format ?? "hh:mm") {
        case "h:mm ap":
            return "+%-I:%M %P|%Z|%a";
        case "h:mm AP":
            return "+%-I:%M %p|%Z|%a";
        default:
            return "+%H:%M|%Z|%a";
        }
    }

    function refreshWorldClock() {
        if (!worldClock.running)
            worldClock.running = true;
    }

    onWorldClockDateFormatChanged: refreshWorldClock()
    onWorldClockTimeZoneChanged: refreshWorldClock()

    Process {
        id: worldClock

        running: true
        command: ["date", root.worldClockDateFormat]
        environment: ({ "TZ": root.worldClockTimeZone })
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                if (parts.length !== 3)
                    return;
                root.worldClockTime = parts[0];
                root.worldClockAbbreviation = parts[1];
                root.worldClockWeekday = parts[2];
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refreshWorldClock()
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: {
            fileUptime.reload();
            const textUptime = fileUptime.text();
            const uptimeSeconds = Number(textUptime.split(" ")[0] ?? 0);

            // Convert seconds to days, hours, and minutes
            const days = Math.floor(uptimeSeconds / 86400);
            const hours = Math.floor((uptimeSeconds % 86400) / 3600);
            const minutes = Math.floor((uptimeSeconds % 3600) / 60);

            // Build the formatted uptime string
            let formatted = "";
            if (days > 0)
                formatted += `${days}d`;
            if (hours > 0)
                formatted += `${formatted ? ", " : ""}${hours}h`;
            if (minutes > 0 || !formatted)
                formatted += `${formatted ? ", " : ""}${minutes}m`;
            uptime = formatted;
            interval = ResourceUsage.updateInterval;
        }
    }

    FileView {
        id: fileUptime

        path: "/proc/uptime"
    }
}
