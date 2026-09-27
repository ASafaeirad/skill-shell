import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.m3 as M3
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

M3.Button {
    id: button
    required property bool input
    variant: "tonal"
    tileLayout: true
    materialIcon: input ? "mic_external_on" : "media_output"
    text: input ? "Input" : "Output"
    supportingText: (input ? Pipewire.defaultAudioSource?.description : Pipewire.defaultAudioSink?.description) ?? "Unknown"
}
