pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    id: root

    // Working copy of the curve. The page edits this and writes it on Apply rather than on
    // every drag: `fan curve set` also hands fan control from the firmware to the custom
    // curve, which is too large a change to make eight times during one gesture.
    property var draft: []

    readonly property bool dirty: {
        if (!Fans.ready || root.draft.length === 0 || root.draft.length !== Fans.curve.length)
            return false;
        return root.draft.some((p, i) => p.temp !== Fans.curve[i].temp || p.pwm !== Fans.curve[i].pwm);
    }

    readonly property bool locked: Fans.fullSpeed || Fans.busy

    // Which profile the draft was read from. Each profile has its own curve, so a draft left
    // over from another one must not be offered for Apply against the new profile.
    property string draftProfile: ""

    function seedDraft() {
        root.draftProfile = Fans.profile;
        root.draft = Fans.curve.map(p => ({
            "temp": p.temp,
            "pwm": p.pwm
        }));
    }

    function setPoint(index, field, value) {
        let next = root.draft.map(p => ({
            "temp": p.temp,
            "pwm": p.pwm
        }));
        next[index][field] = value;

        // Both series have to rise. A curve whose fan speeds dip is accepted by asusctl with
        // exit 0 and then discarded by the firmware, so a dragged slider would appear to save
        // and change nothing. Push the neighbours along instead of letting that be built.
        for (let i = index + 1; i < next.length; i++)
            next[i][field] = Math.max(next[i][field], next[index][field]);
        for (let i = index - 1; i >= 0; i--)
            next[i][field] = Math.min(next[i][field], next[index][field]);

        root.draft = next;
    }

    forceWidth: true

    Component.onCompleted: {
        Fans.monitoring = true;
        root.seedDraft();
    }
    Component.onDestruction: Fans.monitoring = false

    Connections {
        target: Fans

        // Re-seed only when the user has nothing in flight, so a background refresh cannot
        // silently discard edits that have not been applied yet -- unless the profile itself
        // changed, in which case the draft describes a curve that is no longer on screen.
        function onCurveChanged() {
            if (!root.dirty || root.draftProfile !== Fans.profile)
                root.seedDraft();
        }
    }

    // A live reading with its icon and caption. Inline rather than a file in this directory:
    // modules/settings is not a registered QML module, so a sibling .qml here is not importable.
    component StatCard: Rectangle {
        id: card

        property string icon: ""
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        implicitHeight: cardColumn.implicitHeight + Appearance.spacing.m * 2
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1

        ColumnLayout {
            id: cardColumn

            anchors.fill: parent
            anchors.margins: Appearance.spacing.m
            spacing: Appearance.spacing.xxs

            RowLayout {
                spacing: Appearance.spacing.xs

                MaterialSymbol {
                    text: card.icon
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    text: card.label
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }

            StyledText {
                text: card.value
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.huge
                font.family: Appearance.font.family.numbers
            }
        }
    }

    /**
    * One point of the curve: a vertical slider for fan speed, the percentage above it and
    * the temperature threshold below it.
    *
    * StyledSlider is not reused. It lays its track and handle out along x and measures
    * against effectiveDraggingWidth, so `orientation: Qt.Vertical` leaves the fill and the
    * handle drawn horizontally across a vertical control. This draws the same Material
    * tokens along y instead.
    */
    component CurvePoint: ColumnLayout {
        id: point

        property int percent: 0
        property int temperature: 0
        property bool editable: true

        signal percentEdited(int value)
        signal temperatureEdited(int value)

        spacing: Appearance.spacing.xs
        opacity: point.editable ? 1 : 0.4

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: `${point.percent}%`
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
        }

        Item {
            id: trackArea

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            implicitWidth: 22
            implicitHeight: 200

            readonly property real trackWidth: 14
            readonly property real handleHeight: 4
            // The handle sits inside the track, so the reachable span is shortened by it:
            // without this the fill can never quite reach 0% or 100% at the extremes.
            readonly property real travel: Math.max(1, height - trackArea.handleHeight)
            readonly property real fillHeight: (point.percent / 100) * trackArea.travel
                                               + trackArea.handleHeight / 2

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: trackArea.trackWidth
                height: parent.height
                radius: Appearance.rounding.full
                color: Appearance.colors.colSurfaceContainerHighest
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                }
                width: trackArea.trackWidth
                height: trackArea.fillHeight
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary

                Behavior on height {
                    enabled: !dragArea.pressed
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: trackArea.height - trackArea.fillHeight - trackArea.handleHeight / 2
                width: trackArea.trackWidth + 8
                height: trackArea.handleHeight
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary

                Behavior on y {
                    enabled: !dragArea.pressed
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            MouseArea {
                id: dragArea

                anchors.fill: parent
                enabled: point.editable
                cursorShape: point.editable ? (pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor) :
                                              Qt.ArrowCursor

                function percentAt(y) {
                    const offset = y - trackArea.handleHeight / 2;
                    return Math.max(0, Math.min(100, Math.round((1 - offset / trackArea.travel) * 100)));
                }

                onPressed: mouse => point.percentEdited(percentAt(mouse.y))
                onPositionChanged: mouse => {
                    if (pressed)
                        point.percentEdited(percentAt(mouse.y));
                }
                onWheel: wheel => point.percentEdited(Math.max(0, Math.min(100, point.percent + (
                                                                               wheel.angleDelta.y > 0 ? 1 :
                                                                                                        -1))))

                StyledToolTip {
                    extraVisibleCondition: dragArea.pressed
                    text: `${point.temperature}°C → ${point.percent}%`
                }
            }
        }

        // The threshold is editable in place rather than through a separate control: a spin
        // box under every one of eight columns would dominate the curve it annotates.
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            implicitHeight: tempInput.implicitHeight + 4

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.verysmall
                color: tempInput.activeFocus ? Appearance.colors.colSecondaryContainer : (tempHover.hovered
                                                                                          ? Appearance.colors.colLayer1Hover :
                                                                                            "transparent")

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            StyledTextInput {
                id: tempInput

                anchors.centerIn: parent
                width: parent.width - 4
                enabled: point.editable
                horizontalAlignment: Text.AlignHCenter
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colSubtext
                validator: IntValidator {
                    bottom: 0
                    top: 110
                }
                // Deliberately not bound: a binding would fight the user mid-keystroke. It is
                // seeded here and re-seeded below whenever the model moves underneath.
                text: `${point.temperature}°`

                onActiveFocusChanged: {
                    if (activeFocus)
                        text = `${point.temperature}`;
                    else
                        commit();
                }
                onAccepted: focus = false

                function commit() {
                    const parsed = parseInt(text.replace(/[^0-9]/g, ""), 10);
                    if (!isNaN(parsed) && parsed !== point.temperature)
                        point.temperatureEdited(parsed);
                    text = `${point.temperature}°`;
                }

                Connections {
                    target: point

                    function onTemperatureChanged() {
                        if (!tempInput.activeFocus)
                            tempInput.text = `${point.temperature}°`;
                    }
                }
            }

            HoverHandler {
                id: tempHover
            }
        }
    }

    ContentSection {
        icon: "mode_fan"
        title: "Fans"

        NoticeBox {
            Layout.fillWidth: true
            visible: Fans.lastError.length > 0
            color: Appearance.colors.colErrorContainer
            materialIcon: "error"
            text: Fans.lastError
        }

        // Temperatures and fan speeds are laid out as two rows rather than one grid: there
        // are two of the former and three of the latter, so a single row leaves a ragged gap.
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.s

            StatCard {
                icon: "memory"
                label: "CPU"
                value: Fans.cpuTemp >= 0 ? `${Fans.cpuTemp} °C` : "--"
            }

            StatCard {
                icon: "deployed_code"
                label: "GPU"
                // The dGPU exposes no temperature while runtime-suspended, and the only way
                // to ask is nvidia-smi, which wakes it and costs several watts. Naming the
                // reason beats a dash that reads like a broken sensor.
                value: Fans.gpuTemp >= 0 ? `${Fans.gpuTemp} °C` : (Fans.dgpuStatus === "suspended" ? "Asleep" :
                                                                                                     "--")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.s

            Repeater {
                model: Fans.fanSpeeds

                StatCard {
                    required property var modelData

                    icon: "mode_fan"
                    label: `${modelData.label} fan`
                    value: modelData.rpm >= 0 ? `${modelData.rpm} rpm` : "--"
                }
            }
        }

        ContentSubsection {
            title: "Profile"

            ConfigSelectionArray {
                currentValue: Fans.mode
                onSelected: newValue => Fans.setMode(newValue)
                options: [
                    {
                        "value": "quiet",
                        "icon": "bedtime",
                        "displayName": "Quiet"
                    },
                    {
                        "value": "default",
                        "icon": "balance",
                        "displayName": "Default"
                    },
                    {
                        "value": "max",
                        "icon": "speed",
                        "displayName": "Max"
                    }
                ]
            }

            NoticeBox {
                Layout.fillWidth: true
                // Each profile carries its own curve, and the profile is one system-wide
                // setting that the power policy also drives. Saying so beats the user
                // wondering why their choice reverted when they unplugged.
                visible: Config.options.battery.autoPowerProfile && Config.options.battery.powerMode
                         === "auto"
                materialIcon: "info"
                text: "Automatic power management is on, so plugging in or unplugging sets the profile from your power mode and will override the choice above."
            }
        }

        ContentSubsection {
            title: "Curve"
            tooltip: "Applies to the profile that is active right now. Your power mode switches profiles, so a curve saved here follows the profile it was saved on."

            NoticeBox {
                Layout.fillWidth: true
                visible: Fans.fansDiffer && !Fans.fullSpeed
                materialIcon: "info"
                text: "The CPU, GPU and chassis fans currently use different curves. This editor shows the CPU fan and writes one curve to all three."
            }

            NoticeBox {
                Layout.fillWidth: true
                visible: Fans.fullSpeed
                materialIcon: "priority_high"
                text: "Max runs every fan flat out, so the curve below is that override rather than your own. Choose Quiet or Default to edit it and put your saved curve back."
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: curveRow.implicitHeight + Appearance.spacing.lg * 2
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1

                RowLayout {
                    id: curveRow

                    anchors.fill: parent
                    anchors.margins: Appearance.spacing.lg
                    spacing: Appearance.spacing.xs

                    Repeater {
                        model: root.draft

                        CurvePoint {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            editable: !root.locked
                            percent: Fans.pwmToPercent(modelData.pwm)
                            temperature: modelData.temp
                            onPercentEdited: value => root.setPoint(index, "pwm", Fans.percentToPwm(value))
                            onTemperatureEdited: value => root.setPoint(index, "temp", value)
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: root.draft.length === 0
                    text: Fans.ready ? "No fan curve reported by asusctl." : "Reading the fan curve…"
                    color: Appearance.colors.colSubtext
                }
            }

            Revealer {
                Layout.fillWidth: true
                reveal: root.dirty

                RowLayout {
                    width: parent.width
                    spacing: Appearance.spacing.s

                    StyledText {
                        Layout.fillWidth: true
                        text: Fans.profile.length > 0 ? `Unsaved changes to the ${Fans.profile} curve` :
                                                        "Unsaved changes"
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    RippleButtonWithIcon {
                        materialIcon: "undo"
                        mainText: "Revert"
                        enabled: !Fans.busy
                        onClicked: root.seedDraft()
                    }

                    RippleButtonWithIcon {
                        materialIcon: "check"
                        mainText: "Apply"
                        primary: true
                        enabled: !root.locked
                        onClicked: Fans.applyCurve(root.draft)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.xs
                spacing: Appearance.spacing.s

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (Fans.fullSpeed)
                            return "Overridden by Max";
                        if (!Fans.ready)
                            return "";
                        // Split rather than one long ternary: qmlformat wraps at 110 columns
                        // and will break a template literal across lines, putting a real
                        // newline into the string it was only trying to reindent.
                        const mode = Fans.curveEnabled ? "Custom curve active on" : "Firmware control on";
                        return `${mode} ${Fans.profile}`;
                    }
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    // One line: this sits beside a button, and wrapping shoves the row taller
                    // for a status string that is never interesting enough to earn the space.
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                RippleButtonWithIcon {
                    materialIcon: "restart_alt"
                    mainText: "Restore default"
                    enabled: !root.locked
                    onClicked: Fans.resetCurve()

                    StyledToolTip {
                        text: "Puts back the factory curve for this profile and hands fan control back to the firmware."
                    }
                }
            }
        }
    }
}
