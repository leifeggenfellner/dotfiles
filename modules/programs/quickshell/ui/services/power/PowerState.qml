pragma Singleton
import QtQuick
import QtQuick.Io

Item {
    id: powerState

    // 0-100 or -1 when no battery is present
    property int batteryPercent: -1
    // "charging" | "discharging" | "full" | "unknown"
    property string batteryStatus: "unknown"
    property bool acConnected: false
    // "performance" | "balanced" | "power-saver"
    property string powerProfile: "balanced"

    readonly property bool hasBattery: batteryPercent >= 0

    function setProfile(p) {
        _setProfile.command = [
            "powerprofilesctl",
            "set",
            p
        ]

        _setProfile.running = true;
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            _pollBattery.running = true
            _pollProfile.running = true
    }

    Process {
        id: _pollBattery
        command: ["sh", "-c",
            "bat=$(ls /sys/class/power_supply/BAT* 2>/dev/null | head -1); " +
            "[ -z \"$bat\" ] && echo '-1 unknown false' && exit; " +
            "cap=$(cat $bat/capacity 2>/dev/null || echo -1); " +
            "sta=$(cat $bat/status 2>/dev/null || echo unknown); " +
            "ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1 || echo 0); " +
            "echo \"$cap $sta $ac\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(/\s+/)
                if (parts.length < 3) return
                powerState.batteryPercent = parseInt(parts[0])
                powerState.batteryStatus = parts[1].toLowerCase()
                powerState.acConnected = parts[2] === "1"
            }
        }
    }

    Process {
        id: _pollProfile
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                powerState.powerProfile = this.text.trim()
            }
        }
    }

    Process {
        id: _setProfile
        onExited: {
            _pollProfile.running = true
        }
    }
}
