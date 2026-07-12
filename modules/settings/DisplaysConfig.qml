import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    function rulesFromCards() {
        let rules = [];
        for (let i = 0; i < monitorRepeater.count; i++) {
            const card = monitorRepeater.itemAt(i);
            if (!card)
                continue;
            rules.push(card.rule());
        }
        return rules;
    }

    function saveAll() {
        const rules = rulesFromCards();
        for (const rule of rules)
            Monitors.applyRule(rule);
        Monitors.persist(rules);
    }

    ContentSection {
        icon: "monitor"
        title: Translation.tr("Displays")

        NoticeBox {
            Layout.fillWidth: true
            materialIcon: "bolt"
            text: Translation.tr("Save all changes applies every display card and writes the layout to ~/.config/hypr/monitors.conf. To load it on startup, add this line to hyprland.conf once: source = ~/.config/hypr/monitors.conf")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RippleButtonWithIcon {
                materialIcon: "save"
                mainText: Translation.tr("Save all changes")
                onClicked: root.saveAll()
            }
            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Refresh")
                onClicked: Monitors.refresh()
            }
            Item { Layout.fillWidth: true }
        }
    }

    Repeater {
        id: monitorRepeater
        model: Monitors.list

        delegate: Rectangle {
            id: card
            required property var modelData

            Layout.fillWidth: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            implicitHeight: cardColumn.implicitHeight + 24

            // ---- Local editable state, seeded from the live monitor ----
            property bool selEnabled: !modelData.disabled
            property string selRes: `${modelData.width}x${modelData.height}`
            property string selRefresh: Number(modelData.refreshRate).toFixed(2)
            property var selScale: modelData.scale
            property int selTransform: modelData.transform ?? 0
            property string selMirror: (modelData.mirrorOf && modelData.mirrorOf !== "none") ? modelData.mirrorOf : "none"
            property bool selVrr: modelData.vrr ?? false
            property int posX: modelData.x ?? 0
            property int posY: modelData.y ?? 0

            // ---- Derived option lists from availableModes ("2560x1600@240.00Hz") ----
            readonly property var modeList: modelData.availableModes ?? []
            readonly property var resolutions: {
                let seen = [];
                for (const m of card.modeList) {
                    const res = m.split("@")[0];
                    if (!seen.includes(res)) seen.push(res);
                }
                if (seen.length === 0) seen.push(card.selRes);
                return seen;
            }
            function refreshesFor(res) {
                let out = [];
                for (const m of card.modeList) {
                    const parts = m.split("@");
                    if (parts[0] !== res) continue;
                    out.push(parts[1].replace("Hz", ""));
                }
                if (out.length === 0) out.push(card.selRefresh);
                return out;
            }
            readonly property var refreshes: refreshesFor(card.selRes)

            readonly property var scaleOptions: [
                { label: Translation.tr("Auto"), value: "auto" },
                { label: "100%", value: 1.0 },
                { label: "125%", value: 1.25 },
                { label: "150%", value: 1.5 },
                { label: "175%", value: 1.75 },
                { label: "200%", value: 2.0 },
                { label: "250%", value: 2.5 },
                { label: "300%", value: 3.0 }
            ]
            readonly property var transformOptions: [
                { label: Translation.tr("Normal"), value: 0 },
                { label: "90°", value: 1 },
                { label: "180°", value: 2 },
                { label: "270°", value: 3 },
                { label: Translation.tr("Flipped"), value: 4 },
                { label: Translation.tr("Flipped 90°"), value: 5 },
                { label: Translation.tr("Flipped 180°"), value: 6 },
                { label: Translation.tr("Flipped 270°"), value: 7 }
            ]
            readonly property var mirrorOptions: {
                let opts = [{ label: Translation.tr("None"), value: "none" }];
                for (const m of Monitors.list) {
                    if (m.name !== card.modelData.name)
                        opts.push({ label: m.name, value: m.name });
                }
                return opts;
            }

            function rule() {
                return Monitors.buildRule(card.modelData.name, {
                    disabled: !card.selEnabled,
                    mode: `${card.selRes}@${card.selRefresh}`,
                    position: `${card.posX}x${card.posY}`,
                    scale: card.selScale,
                    transform: card.selTransform,
                    mirror: card.selMirror,
                    vrr: card.selVrr
                });
            }

            ColumnLayout {
                id: cardColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header: name + description + enable switch
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        text: card.selEnabled ? "desktop_windows" : "desktop_access_disabled"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colOnLayer1
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            text: card.modelData.name
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.description ?? ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                    }
                    StyledText {
                        visible: card.selEnabled
                        text: `${card.modelData.width}×${card.modelData.height} @ ${Number(card.modelData.refreshRate).toFixed(2)}Hz`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledSwitch {
                        checked: card.selEnabled
                        onToggled: card.selEnabled = checked
                    }
                }

                // Controls, disabled when the monitor is turned off
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 6
                    enabled: card.selEnabled
                    opacity: enabled ? 1 : 0.4

                    ContentSubsection {
                        title: Translation.tr("Resolution")
                        Layout.fillWidth: true
                        StyledComboBox {
                            buttonIcon: "aspect_ratio"
                            model: card.resolutions
                            currentIndex: Math.max(0, card.resolutions.indexOf(card.selRes))
                            onActivated: index => {
                                card.selRes = card.resolutions[index];
                                // Reset refresh to the fastest available for the new resolution
                                card.selRefresh = card.refreshesFor(card.selRes)[0];
                            }
                        }
                    }
                    ContentSubsection {
                        title: Translation.tr("Refresh rate")
                        Layout.fillWidth: true
                        StyledComboBox {
                            buttonIcon: "speed"
                            model: card.refreshes
                            currentIndex: Math.max(0, card.refreshes.indexOf(card.selRefresh))
                            onActivated: index => card.selRefresh = card.refreshes[index]
                        }
                    }
                    ContentSubsection {
                        title: Translation.tr("Scale")
                        Layout.fillWidth: true
                        StyledComboBox {
                            buttonIcon: "zoom_in"
                            textRole: "label"
                            model: card.scaleOptions
                            currentIndex: {
                                const i = card.scaleOptions.findIndex(o => o.value === card.selScale);
                                return i !== -1 ? i : 1;
                            }
                            onActivated: index => card.selScale = card.scaleOptions[index].value
                        }
                    }
                    ContentSubsection {
                        title: Translation.tr("Orientation")
                        Layout.fillWidth: true
                        StyledComboBox {
                            buttonIcon: "screen_rotation"
                            textRole: "label"
                            model: card.transformOptions
                            currentIndex: Math.max(0, card.transformOptions.findIndex(o => o.value === card.selTransform))
                            onActivated: index => card.selTransform = card.transformOptions[index].value
                        }
                    }
                    ContentSubsection {
                        title: Translation.tr("Mirror")
                        Layout.fillWidth: true
                        StyledComboBox {
                            buttonIcon: "content_copy"
                            textRole: "label"
                            model: card.mirrorOptions
                            currentIndex: Math.max(0, card.mirrorOptions.findIndex(o => o.value === card.selMirror))
                            onActivated: index => card.selMirror = card.mirrorOptions[index].value
                        }
                    }
                    ContentSubsection {
                        title: Translation.tr("Position (x, y)")
                        Layout.fillWidth: true
                        RowLayout {
                            spacing: 8
                            StyledSpinBox {
                                Layout.fillWidth: true
                                from: -32768
                                to: 32768
                                stepSize: 10
                                value: card.posX
                                onValueChanged: card.posX = value
                            }
                            StyledSpinBox {
                                Layout.fillWidth: true
                                from: -32768
                                to: 32768
                                stepSize: 10
                                value: card.posY
                                onValueChanged: card.posY = value
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ConfigSwitch {
                        buttonIcon: "sync"
                        text: Translation.tr("Adaptive sync (VRR)")
                        checked: card.selVrr
                        enabled: card.selEnabled
                        onCheckedChanged: card.selVrr = checked
                    }
                }
            }
        }
    }

    PagePlaceholder {
        visible: Monitors.list.length === 0
        Layout.fillWidth: true
        icon: "monitor"
        title: Translation.tr("No monitors detected")
        description: Translation.tr("Is Hyprland running?")
    }
}
