import QtQuick
import qs.services

QuickToggleModel {
    name: "Camera"
    statusText: Camera.busy ? "Changing…" : Camera.error ? "Failed" : !Camera.available ? "Unavailable" : Camera.blocked ? "Blocked" : "Allowed"
    toggled: Camera.available && !Camera.blocked
    available: Camera.available && !Camera.busy
    icon: Camera.blocked ? "videocam_off" : "videocam"
    mainAction: () => Camera.toggle()
    tooltipText: Camera.error || (Camera.busy ? "Waiting for camera access change" : !Camera.available ? "No supported USB camera found" : Camera.blocked ? "Allow camera access for apps. Requires authentication." : "Block camera access for all apps. Requires authentication.")
}
