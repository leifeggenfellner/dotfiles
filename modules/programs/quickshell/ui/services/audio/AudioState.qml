pragma Singleton
import QtQuick
import QtQuick.Io

Item {
    id: audioState

    // [0.0 - 1.0] normalized sink volume
    property real volume: 0.0
    property bool muted: false
    property string sinkName: ""

    function setVolume(v) {
        let pct = Math.round(Math.max(0, Math.min(1, v)) * 100) + "%";
        _setVol.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct];
        _setVol.running = true;
    }

    function setMuted(m) {
        _setMute.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", m ? "1" : "0"];
        _setMute.running = true;
    }

    function toggleMuted() {
        setMuted(!muted);
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            _pollVol.running = true;
            _pollMute.running = true;
        }
    }

    Process {
        id: _pollVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                let m = this.text.match(/Volume:\s*([\d.]+)/);
                if (m)
                    audioState.volume = parseFloat(m[1]);
            }
        }
    }

    Process {
        id: _pollMute
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                audioState.muted = this.text.trim() === "1";
            }
        }
    }

    Process {
        id: _setVol
    }
    Process {
        id: _setMute
        onExited: {
            _pollVol.running = true;
        }
    }
}
