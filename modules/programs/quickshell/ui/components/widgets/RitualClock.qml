import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    id: clock

    Layout.preferredHeight: parent.height
    Layout.preferredWidth: 82

    // ── External data ────────────────────────────────────────
    property var pathwayData: []
    property int activeWorkspace: 1
    property real activityLevel: 0.0
    property real workspacePulse: 0.0

    // ── Internal state ───────────────────────────────────────
    property string timeStr: ""
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property int lastSecond: -1
    property real secondsTarget: 0
    property real minutesTarget: 0
    property real hoursTarget: 0
    property real pulseTarget: 0
    property real secondPhase: 0
    property real minutePhase: 0
    property real hourPhase: 0
    property real pulseLevel: 0
    property real glowLevel: 0.18
    property color pathwayColor: Theme.accent

    // Bounded system modulation signals.
    property real cpuLoad: 0.0
    property real netLoad: 0.0
    property real workspaceBias: 0.0

    function clamp(v, minV, maxV) {
        return Math.max(minV, Math.min(maxV, v));
    }

    // Derive active pathway color from workspace
    function updatePathwayColor() {
        const activeWs = String(activeWorkspace);
        for (let i = 0; i < pathwayData.length; i++) {
            if (String(pathwayData[i].workspace) === activeWs) {
                pathwayColor = Qt.color(pathwayData[i].color);
                return;
            }
        }
        pathwayColor = Theme.accent;
    }

    onActiveWorkspaceChanged: {
        updatePathwayColor();
        workspaceBias = clamp(((activeWorkspace - 1) % 10) / 10.0, 0.0, 1.0);
    }
    onPathwayDataChanged: updatePathwayColor()

    // ── Time update ──────────────────────────────────────────
    Timer {
        interval: 50
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            let sec = now.getSeconds() + now.getMilliseconds() / 1000.0;
            let min = now.getMinutes() + sec / 60.0;
            let hour = (now.getHours() % 12) + min / 60.0;

            clock.timeStr = Qt.formatTime(now, "HH:mm");
            clock.hours = now.getHours();
            clock.minutes = now.getMinutes();
            clock.seconds = now.getSeconds();
            clock.secondsTarget = sec;
            clock.minutesTarget = min;
            clock.hoursTarget = hour;

            // Mechanical tick on second change
            if (clock.seconds !== clock.lastSecond) {
                clock.pulseTarget = 1.0;
                pulseReset.restart();
                clock.lastSecond = clock.seconds;
            }
        }
    }

    Timer {
        id: pulseReset
        interval: 120
        running: false
        repeat: false
        onTriggered: clock.pulseTarget = 0.0
    }

    // ── Spring-like smoothing ────────────────────────────────
    // Outer ring: responsive and lively.
    Behavior on secondPhase {
        SpringAnimation {
            spring: 4.6
            damping: 0.26
        }
    }

    // Inner ring: slower and heavier than seconds ring.
    Behavior on minutePhase {
        SpringAnimation {
            spring: 2.4
            damping: 0.33
        }
    }

    // Hour ring: very steady and deliberate.
    Behavior on hourPhase {
        SpringAnimation {
            spring: 1.8
            damping: 0.36
        }
    }

    // Pulse: short mechanical feedback.
    Behavior on pulseLevel {
        SpringAnimation {
            spring: 8.0
            damping: 0.30
        }
    }

    Behavior on glowLevel {
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    onSecondsTargetChanged: {
        secondPhase = secondsTarget;
    }

    onMinutesTargetChanged: {
        minutePhase = minutesTarget;
    }

    onHoursTargetChanged: {
        hourPhase = hoursTarget;
    }

    onPulseTargetChanged: {
        pulseLevel = pulseTarget;
    }

    onCpuLoadChanged: {
        glowLevel = clamp(0.12 + cpuLoad * 0.20 + netLoad * 0.14, 0.10, 0.46);
    }

    onNetLoadChanged: {
        glowLevel = clamp(0.12 + cpuLoad * 0.20 + netLoad * 0.14, 0.10, 0.46);
    }

    Component.onCompleted: {
        updatePathwayColor();
        workspaceBias = clamp(((activeWorkspace - 1) % 10) / 10.0, 0.0, 1.0);
    }

    // ── Visual container ─────────────────────────────────────
    Item {
        id: container
        anchors.centerIn: parent
        width: 60
        height: 60
        scale: 1.0 + (clock.pulseLevel * (0.016 + clock.cpuLoad * 0.01 + clock.workspacePulse * 0.004))
        property real jitterAmp: clock.clamp(clock.cpuLoad * 0.45, 0.0, 0.6)
        x: Math.sin(clock.secondsTarget * 6.0) * jitterAmp

        // ── Pulse layer ──────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(clock.pathwayColor.r, clock.pathwayColor.g, clock.pathwayColor.b, clock.glowLevel)
            opacity: 0.34 + (clock.pulseLevel * 0.30) + (clock.activityLevel * 0.08)
        }

        // ── Outer ring (seconds) ─────────────────────────────
        Rectangle {
            id: outerRing
            anchors.centerIn: parent
            width: 58
            height: 58
            radius: 29
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(clock.pathwayColor.r, clock.pathwayColor.g, clock.pathwayColor.b, 0.25 + clock.glowLevel * 0.45)
            rotation: ((clock.secondPhase / 60.0) * 360.0) + clock.clamp(clock.cpuLoad * 6.0 + clock.netLoad * 3.0 + clock.workspacePulse * 2.0, 0.0, 10.0)

            Rectangle {
                width: 2
                height: 6
                radius: 1
                color: clock.pathwayColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 0
                opacity: 0.9
            }
        }

        // ── Inner ring (minutes) ─────────────────────────────
        Rectangle {
            id: innerRing
            anchors.centerIn: parent
            width: 50
            height: 50
            radius: 25
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(clock.pathwayColor.r, clock.pathwayColor.g, clock.pathwayColor.b, 0.14 + clock.glowLevel * 0.24)
            rotation: ((clock.minutePhase / 60.0) * 360.0) + (clock.workspaceBias * 10.0)

            Rectangle {
                width: 2
                height: 4
                radius: 1
                color: Qt.rgba(clock.pathwayColor.r, clock.pathwayColor.g, clock.pathwayColor.b, 0.85)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 1
            }
        }

        // ── Hour ring (core cadence) ────────────────────────
        Rectangle {
            id: hourRing
            anchors.centerIn: parent
            width: 43
            height: 43
            radius: 21.5
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(clock.pathwayColor.r, clock.pathwayColor.g, clock.pathwayColor.b, 0.10 + clock.glowLevel * 0.16)
            rotation: (clock.hourPhase / 12.0) * 360.0

            Rectangle {
                width: 2
                height: 3
                radius: 1
                color: Qt.rgba(clock.pathwayColor.r, clock.pathwayColor.g, clock.pathwayColor.b, 0.78)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 1
            }
        }

        // ── Core text ────────────────────────────────────────
        Text {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            text: clock.timeStr
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: Theme.text
            opacity: 0.88
            font {
                family: Theme.fontDisplay
                pixelSize: 12
                weight: Font.Medium
                letterSpacing: 1.2
            }
        }
    }
}
