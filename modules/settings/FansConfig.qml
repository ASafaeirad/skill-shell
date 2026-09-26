pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

ContentPage {
    id: root

    // Working copy of the curve. The page edits this and writes it on Apply rather than on
    // every drag: `fan curve set` also hands fan control from the firmware to the custom
    // curve, which is too large a change to make on every frame of one gesture.
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

    // Set while an Apply this page started is still running, so the button can report what
    // happened to it rather than to a write something else made.
    property bool applying: false
    property bool applied: false

    readonly property string profileHint: {
        const mode = Fans.selectedMode;
        if (mode === "auto") {
            if (Config.options.battery.powerMode === "performance")
                return "Follows your power mode, which pins Performance on both power sources.";
            if (Config.options.battery.powerMode === "powersaver")
                return "Follows your power mode, which pins Quiet on both power sources.";
            return "Follows your power mode — plugged in uses Default, on battery uses Quiet.";
        }
        if (Fans.autoAvailable)
            return "Overrides your power mode until you pick Auto again.";
        if (mode === "quiet")
            return "Caps fan speed; runs warmer under load.";
        if (mode === "default")
            return "Balanced noise and temperature.";
        if (mode === "max")
            return "Fans at full speed. Loud.";
        return "";
    }

    readonly property var profileOptions: {
        let options = [];
        if (Fans.autoAvailable)
            options.push({
                             "value": "auto",
                             "icon": "bolt",
                             "displayName": "Auto"
                         });
        return options.concat([
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
                              ]);
    }

    function fanRpm(id) {
        const fan = Fans.fanSpeeds.find(f => f.id === id);
        return fan ? fan.rpm : -1;
    }

    function seedDraft() {
        root.draftProfile = Fans.profile;
        root.draft = Fans.curve.map(p => ({
            "temp": p.temp,
            "pwm": p.pwm
        }));
    }

    function setPoint(index, temp, percent) {
        let next = root.draft.map(p => ({
            "temp": p.temp,
            "pwm": p.pwm
        }));

        // Both series have to rise. A curve whose fan speeds dip is accepted by asusctl with
        // exit 0 and then discarded by the firmware, so a dragged point would appear to save
        // and change nothing. A point is therefore penned in by its neighbours on both axes,
        // which is also what stops a drag from reordering the curve under itself.
        const low = index > 0 ? next[index - 1] : null;
        const high = index < next.length - 1 ? next[index + 1] : null;
        next[index] = {
            "temp": Math.max(low ? low.temp : 0, Math.min(high ? high.temp : 110, temp)),
            "pwm": Math.max(low ? low.pwm : 0, Math.min(high ? high.pwm : 255, Fans.percentToPwm(Math.max(0,
                                                                                                          Math.min(100,
                                                                                                                   percent)))))
        };

        root.draft = next;
    }

    forceWidth: true

    Component.onCompleted: {
        Fans.monitoring = true;
        root.seedDraft();
    }
    Component.onDestruction: Fans.monitoring = false

    onDirtyChanged: {
        if (root.dirty)
            root.applied = false;
    }

    Connections {
        target: Fans

        // Re-seed only when the user has nothing in flight, so a background refresh cannot
        // silently discard edits that have not been applied yet -- unless the profile itself
        // changed, in which case the draft describes a curve that is no longer on screen.
        function onCurveChanged() {
            if (!root.dirty || root.draftProfile !== Fans.profile)
                root.seedDraft();
        }

        function onBusyChanged() {
            if (Fans.busy || !root.applying)
                return;
            root.applying = false;
            root.applied = Fans.lastError.length === 0;
        }
    }

    /**
    * The fan glyph, turning at the speed of the fan it stands for.
    *
    * Geared down 40:1. A fan at 4700 rpm is 78 turns a second; drawn honestly it is a
    * flicker, and the point of the thing is to show which fan is working, not to be read as
    * a tachometer -- the number next to it is that. Driven from a frame callback rather than
    * a looping animation so a new reading every two seconds changes the speed instead of
    * restarting the turn from zero.
    */
    component FanSpinner: MaterialSymbol {
        id: spinner

        property int rpm: -1
        readonly property real degreesPerSecond: spinner.rpm > 0 ? spinner.rpm / 60 / 40 * 360 : 0

        text: "mode_fan"
        iconSize: Appearance.font.pixelSize.smallie
        color: Appearance.colors.colPrimary
        opacity: spinner.rpm > 0 ? 1 : 0.4

        FrameAnimation {
            running: spinner.visible && spinner.rpm > 0
            onTriggered: spinner.rotation = (spinner.rotation + frameTime * spinner.degreesPerSecond) % 360
        }
    }

    // A live reading: what the sensor says, and under it the fan that answers to it, turning
    // at its own speed. Inline rather than a file in this directory: modules/settings is not
    // a registered QML module, so a sibling .qml here is not importable.
    component StatCard: Rectangle {
        id: card

        property string icon: ""
        property string label: ""
        property string value: ""
        property string unit: ""
        property string caption: ""
        property int rpm: -1

        Layout.fillWidth: true
        implicitHeight: cardColumn.implicitHeight + Appearance.spacing.m * 2
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1

        ColumnLayout {
            id: cardColumn

            anchors.fill: parent
            anchors.margins: Appearance.spacing.m
            spacing: Appearance.spacing.xs

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
                    font.pixelSize: Appearance.font.pixelSize.smallie
                }
            }

            RowLayout {
                spacing: Appearance.spacing.xxs

                StyledText {
                    Layout.alignment: Qt.AlignBaseline
                    text: card.value
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.family: Appearance.font.family.numbers
                }

                StyledText {
                    Layout.alignment: Qt.AlignBaseline
                    visible: card.unit.length > 0
                    text: card.unit
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }

            RowLayout {
                spacing: Appearance.spacing.xs

                FanSpinner {
                    rpm: card.rpm
                }

                StyledText {
                    Layout.fillWidth: true
                    text: card.caption
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.family: Appearance.font.family.numbers
                    elide: Text.ElideRight
                }
            }
        }
    }

    /**
    * The curve, as a curve: fan speed against temperature, with a draggable handle per point
    * and a marker for what the CPU is asking for right now.
    *
    * Both axes are dragged at once, so the temperature thresholds need no separate control.
    * Speed is carried as raw PWM in the model and only ever shown as a percentage: asusctl
    * truncates when it renders one, so a curve that round-trips through percent loses ~1% per
    * cycle and ratchets itself down. Only the point actually dragged is converted.
    */
    component CurvePlot: Rectangle {
        id: plot

        property var points: []
        property bool editable: true
        property int liveTemp: -1
        property int activeIndex: -1

        signal pointDragged(int index, int temp, int percent)

        // Geometry the design fixes and the theme has no token for: the height of a chart
        // body, and the size of a grab handle.
        readonly property real plotHeight: 230
        readonly property real handleSize: 28
        readonly property real dotSize: 12
        readonly property real dotSizeActive: 18
        // The line is punched out from under each handle, so the dots read as points on the
        // curve rather than beads laid over it.
        readonly property real ringRadius: plot.dotSize / 2 + 3

        // 40-100 °C covers every curve this machine ships with. Widen rather than clip if one
        // reaches past it.
        readonly property int xMin: {
            let lowest = 40;
            for (const point of plot.points)
                lowest = Math.min(lowest, point.temp);
            return Math.floor(lowest / 10) * 10;
        }
        readonly property int xMax: {
            let highest = 100;
            for (const point of plot.points)
                highest = Math.max(highest, point.temp);
            return Math.ceil(highest / 10) * 10;
        }
        readonly property var xTicks: {
            let ticks = [];
            for (let temp = plot.xMin; temp <= plot.xMax; temp += 10)
                ticks.push(temp);
            return ticks;
        }
        readonly property var yTicks: [100, 75, 50, 25, 0]

        readonly property var activePoint: (plot.activeIndex >= 0 && plot.activeIndex < plot.points.length)
                                           ? plot.points[plot.activeIndex] : ({
                                                                                  "temp": 0,
                                                                                  "pwm": 0
                                                                              })

        function xAt(temp) {
            return (temp - plot.xMin) / (plot.xMax - plot.xMin) * plotArea.width;
        }

        function yAt(percent) {
            return (1 - percent / 100) * plotArea.height;
        }

        function tempAt(x) {
            return Math.round(plot.xMin + x / plotArea.width * (plot.xMax - plot.xMin));
        }

        function percentAt(y) {
            return Math.round((1 - y / plotArea.height) * 100);
        }

        // What the curve asks for at a temperature, interpolated the way the firmware reads
        // it: linear between points and flat outside the first and the last.
        function percentFor(temp) {
            const points = plot.points;
            if (points.length === 0)
                return 0;
            if (temp <= points[0].temp)
                return Fans.pwmToPercent(points[0].pwm);
            for (let i = 1; i < points.length; i++) {
                if (temp > points[i].temp)
                    continue;
                const from = points[i - 1];
                const to = points[i];
                if (to.temp === from.temp)
                    return Fans.pwmToPercent(to.pwm);
                return Fans.pwmToPercent(from.pwm + (to.pwm - from.pwm) * (temp - from.temp) / (to.temp
                                                                                                - from.temp));
            }
            return Fans.pwmToPercent(points[points.length - 1].pwm);
        }

        // The points in plot coordinates. Everything that draws or measures the curve reads
        // them from here, so the painted line, the handles and the live marker agree.
        function curveXs() {
            return plot.points.map(point => plot.xAt(point.temp));
        }

        function curveYs() {
            return plot.points.map(point => plot.yAt(Fans.pwmToPercent(point.pwm)));
        }

        // Fritsch-Carlson tangents for a monotone cubic through the points. A plain
        // Catmull-Rom bows past its own values, which on a fan curve draws a dip in speed
        // between two rising steps and can leave the 0-100% band entirely; this cannot
        // overshoot, so a curve that only rises only rises on screen too.
        function curveSlopes(xs, ys) {
            const count = xs.length;
            if (count < 2)
                return [0];

            const secants = [];
            for (let i = 0; i < count - 1; i++) {
                const dx = xs[i + 1] - xs[i];
                secants.push(dx === 0 ? 0 : (ys[i + 1] - ys[i]) / dx);
            }

            const slopes = [secants[0]];
            for (let i = 1; i < count - 1; i++)
                slopes.push(secants[i - 1] * secants[i] <= 0 ? 0 : (secants[i - 1] + secants[i]) / 2);
            slopes.push(secants[count - 2]);

            // Clamp each tangent into the circle of radius 3 that keeps the segment monotone.
            for (let i = 0; i < count - 1; i++) {
                if (secants[i] === 0) {
                    slopes[i] = 0;
                    slopes[i + 1] = 0;
                    continue;
                }
                const a = slopes[i] / secants[i];
                const b = slopes[i + 1] / secants[i];
                const magnitude = Math.sqrt(a * a + b * b);
                if (magnitude > 3) {
                    slopes[i] = 3 * a / magnitude * secants[i];
                    slopes[i + 1] = 3 * b / magnitude * secants[i];
                }
            }
            return slopes;
        }

        // Continues the current path along the smoothed curve, point to point. The caller
        // owns the ends: the firmware holds the first and the last speed beyond them, so both
        // runs out to the edge of the plot stay flat.
        function traceCurve(ctx, xs, ys) {
            const slopes = plot.curveSlopes(xs, ys);
            for (let i = 0; i < xs.length - 1; i++) {
                const dx = xs[i + 1] - xs[i];
                ctx.bezierCurveTo(xs[i] + dx / 3, ys[i] + slopes[i] * dx / 3, xs[i + 1] - dx / 3,
                                  ys[i + 1] - slopes[i + 1] * dx / 3, xs[i + 1], ys[i + 1]);
            }
        }

        // Where the drawn curve sits at an x, so the live marker rides the line rather than
        // floating beside it. Its label still reports percentFor: the number the firmware
        // acts on is the linear one, and only the drawing is smoothed.
        function curveYAt(x) {
            const xs = plot.curveXs();
            const ys = plot.curveYs();
            const count = xs.length;
            if (count === 0)
                return plotArea.height;
            if (count === 1 || x <= xs[0])
                return ys[0];
            if (x >= xs[count - 1])
                return ys[count - 1];

            const slopes = plot.curveSlopes(xs, ys);
            for (let i = 1; i < count; i++) {
                if (x > xs[i])
                    continue;
                const dx = xs[i] - xs[i - 1];
                if (dx === 0)
                    return ys[i];
                const t = (x - xs[i - 1]) / dx;
                const t2 = t * t;
                const t3 = t2 * t;
                return (2 * t3 - 3 * t2 + 1) * ys[i - 1] + (t3 - 2 * t2 + t) * dx * slopes[i - 1] + (-2 * t3 + 3 * t2) * ys[i] + (t3 - t2) * dx * slopes[i];
            }
            return ys[count - 1];
        }

        implicitHeight: plot.plotHeight + chart.labelRowHeight + Appearance.spacing.m * 2
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1

        Item {
            id: chart

            anchors.fill: parent
            anchors.margins: Appearance.spacing.m

            // The axes are sized from the tick text rather than from a fixed gutter, so they
            // stay legible at any font scale.
            readonly property real gutterWidth: tickMetrics.width + Appearance.spacing.s
            readonly property real labelRowHeight: tickMetrics.height + Appearance.spacing.xs

            TextMetrics {
                id: tickMetrics

                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.smallest
                text: "100%"
            }

            Repeater {
                model: plot.yTicks

                StyledText {
                    required property int modelData

                    x: chart.gutterWidth - Appearance.spacing.s - width
                    y: plotArea.y + plot.yAt(modelData) - height / 2
                    text: `${modelData}%`
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                }
            }

            Repeater {
                model: plot.xTicks

                StyledText {
                    required property int modelData

                    x: plotArea.x + plot.xAt(modelData) - width / 2
                    y: plotArea.height + Appearance.spacing.xs
                    text: `${modelData}°`
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                }
            }

            Item {
                id: plotArea

                anchors {
                    left: parent.left
                    leftMargin: chart.gutterWidth
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    bottomMargin: chart.labelRowHeight
                }

                Repeater {
                    model: plot.yTicks

                    Rectangle {
                        required property int modelData

                        anchors.left: parent.left
                        anchors.right: parent.right
                        y: Math.min(plot.yAt(modelData), plotArea.height - 1)
                        implicitHeight: 1
                        color: Appearance.colors.colOutlineVariant
                        opacity: 0.5
                    }
                }

                Canvas {
                    id: curveCanvas

                    // One binding to hang every repaint off: the point list, the live reading,
                    // the size and the palette, which the wallpaper can change under us.
                    readonly property var repaintTrigger: [plot.points, plot.liveTemp, width, height,
                        Appearance.colors.colPrimary, Appearance.colors.colTertiary]

                    anchors.fill: parent
                    onRepaintTriggerChanged: curveCanvas.requestPaint()
                    onPaint: {
                        const ctx = curveCanvas.getContext("2d");
                        ctx.reset();
                        if (plot.points.length === 0)
                            return;

                        const xs = plot.curveXs();
                        const ys = plot.curveYs();
                        const last = xs.length - 1;

                        ctx.beginPath();
                        ctx.moveTo(0, height);
                        ctx.lineTo(0, ys[0]);
                        ctx.lineTo(xs[0], ys[0]);
                        plot.traceCurve(ctx, xs, ys);
                        ctx.lineTo(width, ys[last]);
                        ctx.lineTo(width, height);
                        ctx.closePath();
                        ctx.fillStyle = ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88);
                        ctx.fill();

                        ctx.beginPath();
                        ctx.moveTo(0, ys[0]);
                        ctx.lineTo(xs[0], ys[0]);
                        plot.traceCurve(ctx, xs, ys);
                        ctx.lineTo(width, ys[last]);
                        ctx.lineWidth = 2.5;
                        ctx.lineJoin = "round";
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Appearance.colors.colPrimary;
                        ctx.stroke();

                        if (liveMarker.visible) {
                            const markerX = plot.xAt(plot.liveTemp);
                            ctx.beginPath();
                            ctx.setLineDash([4, 4]);
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = ColorUtils.transparentize(Appearance.colors.colTertiary, 0.2);
                            ctx.moveTo(markerX, 0);
                            ctx.lineTo(markerX, height);
                            ctx.stroke();
                            ctx.setLineDash([]);
                        }

                        // Clear a ring under every handle instead of drawing one: the card is
                        // a translucent layer colour, so a ring painted in it would let the
                        // line straight through.
                        ctx.globalCompositeOperation = "destination-out";
                        for (let i = 0; i <= last; i++) {
                            ctx.beginPath();
                            ctx.arc(xs[i], ys[i], plot.ringRadius, 0, Math.PI * 2);
                            ctx.fill();
                        }
                        ctx.globalCompositeOperation = "source-over";
                    }
                }

                Item {
                    id: liveMarker

                    readonly property real markerX: plot.xAt(plot.liveTemp)
                    readonly property real markerY: plot.curveYAt(liveMarker.markerX)

                    anchors.fill: parent
                    visible: plot.points.length > 0 && plot.liveTemp >= plot.xMin && plot.liveTemp
                             <= plot.xMax

                    Rectangle {
                        x: liveMarker.markerX - width / 2
                        y: liveMarker.markerY - height / 2
                        width: 18
                        height: 18
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colTertiaryContainer

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colTertiary
                        }
                    }

                    Rectangle {
                        // Sits beside the marker line, and flips to its other side rather than
                        // running off the plot when the machine is hot.
                        x: Math.max(0, Math.min(liveMarker.markerX + Appearance.spacing.xs, parent.width
                                                - width))

                        y: Appearance.spacing.xs
                        width: liveLabel.implicitWidth + Appearance.spacing.s * 2
                        height: liveLabel.implicitHeight + Appearance.spacing.xxs * 2
                        radius: Appearance.rounding.verysmall
                        color: Appearance.colors.colTertiaryContainer

                        StyledText {
                            id: liveLabel

                            anchors.centerIn: parent
                            text: `CPU ${plot.liveTemp}° → ${plot.percentFor(plot.liveTemp)}%`
                            color: Appearance.colors.colOnTertiaryContainer
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.family: Appearance.font.family.numbers
                        }
                    }
                }

                Repeater {
                    // The model is the point count, not the array: `points` is reassigned on
                    // every frame of a drag, and a Repeater told to watch the array itself
                    // would rebuild its delegates and drop the grab mid-gesture.
                    model: plot.points.length

                    Item {
                        id: handle

                        required property int index
                        readonly property var point: plot.points[handle.index] ?? ({
                                                                                       "temp": plot.xMin,
                                                                                       "pwm": 0
                                                                                   })
                        readonly property bool active: plot.activeIndex === handle.index

                        x: plot.xAt(handle.point.temp) - width / 2
                        y: plot.yAt(Fans.pwmToPercent(handle.point.pwm)) - height / 2
                        implicitWidth: plot.handleSize
                        implicitHeight: plot.handleSize
                        z: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: handle.active ? plot.dotSizeActive + 20 : plot.dotSizeActive
                            height: width
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colPrimaryActive
                            opacity: handle.active ? 1 : 0

                            Behavior on width {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(
                                               this)
                            }

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(
                                               this)
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: handle.active ? plot.dotSizeActive : plot.dotSize
                            height: width
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colPrimary

                            Behavior on width {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(
                                               this)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: plot.editable
                            cursorShape: plot.editable ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) :
                                                         Qt.ArrowCursor

                            onPressed: plot.activeIndex = handle.index
                            onReleased: plot.activeIndex = -1
                            onCanceled: plot.activeIndex = -1
                            onPositionChanged: mouse => {
                                if (!pressed)
                                    return;
                                const local = mapToItem(plotArea, mouse.x, mouse.y);
                                plot.pointDragged(handle.index, plot.tempAt(local.x), plot.percentAt(
                                                      local.y));

                            }
                        }
                    }
                }

                Rectangle {
                    // Reads out the point being dragged. Above the handle rather than on it:
                    // the finger, and the halo, are already there.
                    x: Math.max(0, Math.min(plot.xAt(plot.activePoint.temp) - width / 2, parent.width
                                            - width))

                    y: plot.yAt(Fans.pwmToPercent(plot.activePoint.pwm)) - height - Appearance.spacing.xl
                    width: dragLabel.implicitWidth + Appearance.spacing.s * 2
                    height: dragLabel.implicitHeight + Appearance.spacing.xxs * 2
                    radius: Appearance.rounding.verysmall
                    color: Appearance.colors.colOnLayer1
                    visible: plot.activeIndex >= 0
                    z: 3

                    StyledText {
                        id: dragLabel

                        anchors.centerIn: parent
                        text: `${plot.activePoint.temp}° · ${Fans.pwmToPercent(plot.activePoint.pwm)}%`
                        color: Appearance.colors.colLayer0Base
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.family: Appearance.font.family.numbers
                        font.weight: Font.Medium
                    }
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: plot.points.length === 0
            text: Fans.ready ? "No fan curve reported by asusctl." : "Reading the fan curve…"
            color: Appearance.colors.colSubtext
        }
    }

    ContentSection {
        icon: "mode_fan"
        title: "Fans"

        headerTrailing: Component {
            RowLayout {
                spacing: Appearance.spacing.xs
                visible: Fans.monitoring && Fans.ready

                Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: "Live"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: Fans.lastError.length > 0
            color: Appearance.colors.colErrorContainer
            materialIcon: "error"
            text: Fans.lastError
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.s

            StatCard {
                icon: "memory"
                label: "CPU"
                value: Fans.cpuTemp >= 0 ? `${Fans.cpuTemp}` : "--"
                unit: Fans.cpuTemp >= 0 ? "°C" : ""
                rpm: root.fanRpm("cpu")
                caption: rpm >= 0 ? `${rpm} rpm` : "No reading"
            }

            StatCard {
                icon: "deployed_code"
                label: "GPU"
                // The dGPU exposes no temperature while runtime-suspended, and the only way
                // to ask is nvidia-smi, which wakes it and costs several watts. Naming the
                // reason beats a dash that reads like a broken sensor.
                value: Fans.gpuTemp >= 0 ? `${Fans.gpuTemp}` : (Fans.dgpuStatus === "suspended" ? "Asleep" :
                                                                                                  "--")
                unit: Fans.gpuTemp >= 0 ? "°C" : ""
                rpm: root.fanRpm("gpu")
                caption: rpm >= 0 ? `${rpm} rpm` : "No reading"
            }

            StatCard {
                icon: "mode_fan"
                label: "Chassis"
                value: root.fanRpm("mid") >= 0 ? `${root.fanRpm("mid")}` : "--"
                unit: root.fanRpm("mid") >= 0 ? "rpm" : ""
                rpm: root.fanRpm("mid")
                caption: "Mid fan"
            }
        }

        ContentSubsection {
            title: "Profile"

            ConfigSelectionArray {
                currentValue: Fans.selectedMode
                onSelected: newValue => Fans.setMode(newValue)
                options: root.profileOptions
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.xxs
                spacing: Appearance.spacing.s
                visible: root.profileHint.length > 0

                MaterialSymbol {
                    Layout.alignment: Qt.AlignTop
                    text: "info"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.profileHint
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    wrapMode: Text.WordWrap
                }
            }
        }

        ContentSubsection {
            title: "Curve"
            tooltip: "Applies to the profile that is active right now. Your power mode switches profiles, so a curve saved here follows the profile it was saved on."

            headerTrailing: Component {
                Rectangle {
                    implicitWidth: differLabel.implicitWidth + Appearance.spacing.m * 2
                    implicitHeight: differLabel.implicitHeight + Appearance.spacing.xs * 2
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colTertiaryContainer
                    visible: Fans.fansDiffer && !Fans.fullSpeed

                    RowLayout {
                        id: differLabel

                        anchors.centerIn: parent
                        spacing: Appearance.spacing.xs

                        MaterialSymbol {
                            text: "call_split"
                            iconSize: Appearance.font.pixelSize.smallie
                            color: Appearance.colors.colOnTertiaryContainer
                        }

                        StyledText {
                            text: "Fans differ · saving syncs all three"
                            color: Appearance.colors.colOnTertiaryContainer
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }

                    HoverHandler {
                        id: differHover
                    }

                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: differHover.hovered
                        text: "The CPU, GPU and chassis fans currently use different curves. This editor shows the CPU fan and writes one curve to all three."
                    }
                }
            }

            NoticeBox {
                Layout.fillWidth: true
                visible: Fans.fullSpeed
                materialIcon: "priority_high"
                text: "Max runs every fan flat out, so the curve below is that override rather than your own. Choose Quiet or Default to edit it and put your saved curve back."
            }

            CurvePlot {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.xxs
                points: root.draft
                editable: !root.locked
                liveTemp: Fans.cpuTemp
                onPointDragged: (index, temp, percent) => root.setPoint(index, temp, percent)
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.spacing.xs
                text: "Drag points to adjust. Speed stays flat beyond the first and last point."
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.m
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.s
                spacing: Appearance.spacing.s

                MaterialSymbol {
                    text: "memory"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (Fans.fullSpeed)
                            return "Overridden by Max";
                        if (root.dirty)
                            return Fans.profile.length > 0 ? `Unsaved changes to the ${Fans.profile} curve` :
                                                             "Unsaved curve";
                        if (!Fans.ready)
                            return "";
                        // Split rather than one long ternary: qmlformat wraps at 110 columns
                        // and will break a template literal across lines, putting a real
                        // newline into the string it was only trying to reindent.
                        const mode = Fans.curveEnabled ? "Custom curve active on" : "Firmware control on";
                        return `${mode} ${Fans.profile}`;
                    }
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    // One line: this sits beside the buttons, and wrapping shoves the row
                    // taller for a status string that is never interesting enough to earn it.
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                RippleButtonWithIcon {
                    visible: root.dirty
                    materialIcon: "undo"
                    mainText: "Revert"
                    enabled: !Fans.busy
                    onClicked: root.seedDraft()
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

                RippleButtonWithIcon {
                    materialIcon: root.applied ? "check" : "save"
                    mainText: root.applied ? "Applied" : "Apply"
                    primary: root.dirty
                    enabled: root.dirty && !root.locked
                    onClicked: {
                        root.applying = true;
                        Fans.applyCurve(root.draft);
                    }
                }
            }
        }
    }
}
