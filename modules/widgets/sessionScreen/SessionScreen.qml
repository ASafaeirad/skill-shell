import qs
import qs.services
import qs.modules.common
import qs.modules.common.m3 as M3
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Panel {
    id: root
    name: "session"
    description: "Toggles session screen on press"
    hasOpenCloseShortcuts: true

    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    Loader {
        id: sessionLoader
        active: root.opened
        onActiveChanged: {
            if (sessionLoader.active)
                SessionWarnings.refresh();
        }

        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                if (GlobalStates.screenLocked) {
                    root.close();
                }
            }
        }

        sourceComponent: PanelWindow { // Session menu
            id: sessionRoot
            visible: sessionLoader.active
            property string subtitle

            function hide() {
                root.close();
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, Appearance.m3colors.darkmode ? 0.05 : 0.12)

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: root.focusedScreen?.width ?? 0
            implicitHeight: root.focusedScreen?.height ?? 0

            MouseArea {
                id: sessionMouseArea
                anchors.fill: parent
                onClicked: {
                    sessionRoot.hide();
                }
            }

            ColumnLayout { // Content column
                id: contentColumn
                anchors.centerIn: parent
                spacing: Appearance.spacing.lg

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_S:
                        sessionShutdown.forceActiveFocus();
                        event.accepted = true;
                        break;
                    case Qt.Key_R:
                        sessionReboot.forceActiveFocus();
                        event.accepted = true;
                        break;
                    case Qt.Key_X:
                        sessionLogout.forceActiveFocus();
                        event.accepted = true;
                        break;
                    case Qt.Key_L:
                        sessionLock.forceActiveFocus();
                        event.accepted = true;
                        break;
                    case Qt.Key_H:
                        sessionHibernate.forceActiveFocus();
                        event.accepted = true;
                        break;
                    case Qt.Key_Escape:
                        sessionRoot.hide();
                        event.accepted = true;
                        break;
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0
                    StyledText {
                        // Title
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.title
                            variableAxes: Appearance.font.variableAxes.title
                        }
                        text: "Sorry to see you go!"
                    }
                }

                GridLayout {
                    columns: 3
                    columnSpacing: Appearance.spacing.lg
                    rowSpacing: Appearance.spacing.lg

                    SessionActionButton {
                        id: sessionLock
                        focus: sessionRoot.visible
                        materialIcon: "lock"
                        tooltip: "Lock"
                        onClicked: {
                            Session.lock();
                            sessionRoot.hide();
                        }
                        onFocusChanged: {
                            if (focus)
                                sessionRoot.subtitle = tooltip;
                        }
                        KeyNavigation.right: sessionSleep
                        KeyNavigation.down: sessionHibernate
                    }
                    SessionActionButton {
                        id: sessionSleep
                        materialIcon: "dark_mode"
                        tooltip: "Sleep"
                        onClicked: {
                            Session.suspend();
                            sessionRoot.hide();
                        }
                        onFocusChanged: {
                            if (focus)
                                sessionRoot.subtitle = tooltip;
                        }
                        KeyNavigation.left: sessionLock
                        KeyNavigation.right: sessionLogout
                        KeyNavigation.down: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionLogout
                        materialIcon: "logout"
                        tooltip: "Logout"
                        onClicked: {
                            Session.logout();
                            sessionRoot.hide();
                        }
                        onFocusChanged: {
                            if (focus)
                                sessionRoot.subtitle = tooltip;
                        }
                        KeyNavigation.left: sessionSleep
                        KeyNavigation.down: sessionReboot
                        KeyNavigation.right: sessionHibernate
                    }

                    SessionActionButton {
                        id: sessionHibernate
                        materialIcon: "downloading"
                        tooltip: "Hibernate"
                        onClicked: {
                            Session.hibernate();
                            sessionRoot.hide();
                        }
                        onFocusChanged: {
                            if (focus)
                                sessionRoot.subtitle = tooltip;
                        }
                        KeyNavigation.up: sessionLock
                        KeyNavigation.right: sessionShutdown
                    }
                    SessionActionButton {
                        id: sessionShutdown
                        materialIcon: "power_settings_new"
                        tooltip: "Shutdown"
                        onClicked: {
                            Session.poweroff();
                            sessionRoot.hide();
                        }
                        onFocusChanged: {
                            if (focus)
                                sessionRoot.subtitle = tooltip;
                        }
                        KeyNavigation.left: sessionHibernate
                        KeyNavigation.right: sessionReboot
                        KeyNavigation.up: sessionSleep
                    }
                    SessionActionButton {
                        id: sessionReboot
                        materialIcon: "restart_alt"
                        tooltip: "Reboot"
                        onClicked: {
                            Session.reboot();
                            sessionRoot.hide();
                        }
                        onFocusChanged: {
                            if (focus)
                                sessionRoot.subtitle = tooltip;
                        }
                        KeyNavigation.left: sessionShutdown
                        KeyNavigation.up: sessionLogout
                    }
                }

                DescriptionLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: sessionRoot.subtitle
                }
            }

            ColumnLayout {
                anchors {
                    top: contentColumn.bottom
                    topMargin: Appearance.spacing.m
                    horizontalCenter: contentColumn.horizontalCenter
                }
                spacing: Appearance.spacing.m

                Loader {
                    Layout.alignment: Qt.AlignHCenter
                    active: SessionWarnings.downloadRunning
                    visible: active
                    sourceComponent: DescriptionLabel {
                        text: "There might be a download in progress. Check your Downloads folder."
                        error: true
                    }
                }

                Loader {
                    Layout.alignment: Qt.AlignHCenter
                    active: SessionWarnings.packageManagerRunning
                    visible: active
                    sourceComponent: DescriptionLabel {
                        text: "Your package manager is running"
                        error: true
                    }
                }
            }
        }
    }

    component DescriptionLabel: M3.Card {
        id: descriptionLabel
        property string text
        variant: "filled"
        padding: Appearance.spacing.m

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        StyledText {
            color: descriptionLabel.contentColor
            text: descriptionLabel.text
        }
    }
}
