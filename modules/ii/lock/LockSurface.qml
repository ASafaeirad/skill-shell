import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock
import qs.modules.common.widgets
import qs.modules.ii.bar as Bar
import qs.services

MouseArea {
    // RippleButton {
    //     anchors {
    //         top: parent.top
    //         left: parent.left
    //         leftMargin: 10
    //         topMargin: 10
    //     }
    //     implicitHeight: 40
    //     colBackground: Appearance.colors.colLayer2
    //     onClicked: {
    //         context.unlocked(LockContext.ActionEnum.Unlock);
    //         GlobalStates.screenLocked = false;
    //     }
    //     contentItem: StyledText {
    //         text: "[[ DEBUG BYPASS ]]"
    //     }
    // }

    id: root

    required property LockContext context
    property bool active: false
    property bool showInputField: active || context.currentText.length > 0
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower
    // Toolbar appearing animation
    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    // Key presses
    property bool ctrlHeld: false

    // Force focus on entry
    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: (mouse) => {
        forceFieldFocus();
    }
    onPositionChanged: (mouse) => {
        forceFieldFocus();
    }
    // Init
    Component.onCompleted: {
        forceFieldFocus();
        toolbarScale = 1;
        toolbarOpacity = 1;
    }
    Keys.onPressed: (event) => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control)
            root.ctrlHeld = true;

        if (event.key === Qt.Key_Escape)
            // Esc to clear
            root.context.currentText = "";

        forceFieldFocus();
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Control)
            root.ctrlHeld = false;

        forceFieldFocus();
    }

    Connections {
        function onShouldReFocus() {
            forceFieldFocus();
        }

        target: context
    }

    // Wallpaper backdrop. Hyprland doesn't render layer surfaces behind the session
    // lock, so the background panel can't show through here — draw the wallpaper as
    // part of the lock surface instead.
    Item {
        id: backdrop

        readonly property bool blurEnabled: Config.options.lock.blur.enable

        anchors.fill: parent
        z: -1
        clip: true

        Image {
            id: wallpaperImage

            anchors.fill: parent
            visible: !backdrop.blurEnabled
            source: Config.options.background.wallpaperPath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize: Qt.size(backdrop.width, backdrop.height)
        }

        Loader {
            anchors.fill: parent
            active: backdrop.blurEnabled

            sourceComponent: MultiEffect {
                source: wallpaperImage
                // Zoomed a bit so the blur doesn't sample past the wallpaper edges
                scale: Config.options.lock.blur.extraZoom
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                // blurMax tops out at 64
                blurMax: Math.min(64, Config.options.lock.blur.radius)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
        }
    }

    // lock status
    Toolbar {
        id: lockInfoIsland

        scale: root.toolbarScale
        opacity: root.toolbarOpacity
        padding: Appearance.rounding.small
        colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 1)
        enableShadow: false

        anchors {
            bottom: parent.verticalCenter
            bottomMargin: Appearance.sizes.elevationMargin
        }

        ColumnLayout {
            spacing: Appearance.rounding.verysmall

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: DateTime.time
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.hugeass * 3
                animateChange: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: DateTime.longDate
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.larger
                animateChange: true
            }
        }

        states: [
            State {
                name: "centered"
                when: Config.options.lock.centerClock

                AnchorChanges {
                    target: lockInfoIsland
                    anchors.left: undefined
                    anchors.horizontalCenter: root.horizontalCenter
                }

            },
            State {
                name: "leftAligned"
                when: !Config.options.lock.centerClock

                AnchorChanges {
                    target: lockInfoIsland
                    anchors.left: leftIsland.left
                    anchors.horizontalCenter: undefined
                }

            }
        ]
        transitions: Transition {
            AnchorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }

        }
    }

    // Main toolbar: password box
    Toolbar {
        id: mainIsland

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }

        // Fingerprint
        Loader {
            Layout.leftMargin: 10
            Layout.rightMargin: 6
            Layout.alignment: Qt.AlignVCenter
            active: root.context.fingerprintsConfigured
            visible: active

            sourceComponent: MaterialSymbol {
                id: fingerprintIcon

                fill: 1
                text: "fingerprint"
                iconSize: Appearance.font.pixelSize.hugeass
                color: Appearance.colors.colOnSurfaceVariant
            }

        }

        ToolbarTextField {
            id: passwordBox

            // We're drawing dots manually
            property bool materialShapeChars: Config.options.lock.materialShapeChars

            Layout.rightMargin: -Layout.leftMargin
            placeholderText: GlobalStates.screenUnlockFailed ? "Incorrect password" : "Enter password"
            // Style
            clip: true
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
            selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer
            // Password
            enabled: !root.context.unlockInProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            // Synchronizing (across monitors) and unlocking
            onTextChanged: root.context.currentText = this.text
            onAccepted: {
                root.context.tryUnlock(ctrlHeld);
            }
            Keys.onPressed: (event) => {
                root.context.resetClearTimer();
            }
            layer.enabled: true
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)

            Connections {
                function onCurrentTextChanged() {
                    passwordBox.text = root.context.currentText;
                }

                target: root.context
            }

            // Shake when wrong password
            ErrorShakeAnimation {
                id: wrongPasswordShakeAnim

                target: passwordBox
            }

            Connections {
                function onScreenUnlockFailedChanged() {
                    if (GlobalStates.screenUnlockFailed)
                        wrongPasswordShakeAnim.restart();

                }

                target: GlobalStates
            }

            Loader {
                active: passwordBox.materialShapeChars

                anchors {
                    fill: parent
                    leftMargin: passwordBox.padding
                    rightMargin: passwordBox.padding
                }

                sourceComponent: PasswordChars {
                    length: root.context.currentText.length
                    selectionStart: passwordBox.selectionStart
                    selectionEnd: passwordBox.selectionEnd
                    cursorPosition: passwordBox.cursorPosition
                }

            }

            layer.effect: OpacityMask {

                maskSource: Rectangle {
                    width: passwordBox.width - 8
                    height: passwordBox.height
                    radius: height / 2
                }

            }

        }

        ToolbarButton {
            id: confirmButton

            implicitWidth: height
            toggled: true
            enabled: !root.context.unlockInProgress
            colBackgroundToggled: Appearance.colors.colPrimary
            onClicked: root.context.tryUnlock()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: {
                    if (root.context.targetAction === LockContext.ActionEnum.Unlock)
                        return root.ctrlHeld ? "coffee" : "arrow_right_alt";
                    else if (root.context.targetAction === LockContext.ActionEnum.Poweroff)
                        return "power_settings_new";
                    else if (root.context.targetAction === LockContext.ActionEnum.Reboot)
                        return "restart_alt";
                }
                color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }

        }

        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

    }

    // Left toolbar
    Toolbar {
        id: leftIsland

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        anchors {
            right: mainIsland.left
            top: mainIsland.top
            bottom: mainIsland.bottom
            rightMargin: 10
        }

        // Username
        IconAndTextPair {
            Layout.leftMargin: 8
            icon: "account_circle"
            text: SystemInfo.username
        }

        // Keyboard layout (Xkb)
        Loader {
            Layout.rightMargin: 8
            Layout.fillHeight: true
            active: true
            visible: active

            sourceComponent: Row {
                spacing: 8

                MaterialSymbol {
                    id: keyboardIcon

                    anchors.verticalCenter: parent.verticalCenter
                    fill: 1
                    text: "keyboard_alt"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Loader {
                    anchors.verticalCenter: parent.verticalCenter

                    sourceComponent: StyledText {
                        text: StringUtils.toSmallCaps(HyprlandXkb.currentLayoutCode)
                        color: Appearance.colors.colOnSurfaceVariant
                        animateChange: true
                    }

                }

            }

        }

        // Keyboard layout (Fcitx)
        Bar.SysTray {
            Layout.rightMargin: 10
            Layout.alignment: Qt.AlignVCenter
            showSeparator: false
            showOverflowMenu: false
            pinnedItems: SystemTray.items.values.filter((i) => {
                return i.id == "Fcitx";
            })
            visible: pinnedItems.length > 0
        }

    }

    // Right toolbar
    Toolbar {
        id: rightIsland

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        anchors {
            left: mainIsland.right
            top: mainIsland.top
            bottom: mainIsland.bottom
            leftMargin: 10
        }

        IconAndTextPair {
            visible: Battery.available
            icon: Battery.isCharging ? "bolt" : "battery_android_full"
            text: Math.round(Battery.percentage * 100)
            color: (Battery.isLow && !Battery.isCharging) ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
        }

        IconToolbarButton {
            id: sleepButton

            onClicked: Session.suspend()
            text: "dark_mode"
        }

        PasswordGuardedIconToolbarButton {
            id: powerButton

            text: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }

        PasswordGuardedIconToolbarButton {
            id: rebootButton

            text: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }

    }

    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }

    }

    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    component PasswordGuardedIconToolbarButton: IconToolbarButton {
        id: guardedBtn

        required property var targetAction

        toggled: root.context.targetAction === guardedBtn.targetAction
        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guardedBtn.targetAction);
                return ;
            }
            if (root.context.targetAction === guardedBtn.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guardedBtn.targetAction;
                root.context.shouldReFocus();
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair

        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }

    }

}
