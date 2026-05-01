pragma Singleton
import QtQuick
import QtQuick.Io

Item {
    id: privacyState

    property bool micActive: false
    property bool cameraActive: false
    property bool screenSharing: false

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            _checkMic.running = true;
            _checkCam.running = true;
            _checkScreen.running = true;
        }
    }

    // Count running PipeWire nodes of the relevant media classes
    Process {
        id: _checkMic
        command: ["sh", "-c", "pactl list source-outputs 2>/dev/null | grep -c 'State: RUNNING' || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                privacyState.micActive = parseInt(this.text.trim()) > 0;
            }
        }
    }

    Process {
        id: _checkCam
        command: ["sh", "-c", "ls /dev/video* 2>/dev/null | xargs -I{} sh -c 'fuser {} 2>/dev/null' | grep -c . || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                privacyState.cameraActive = parseInt(this.text.trim()) > 0;
            }
        }
    }

    Process {
        id: _checkScreen
        command: ["sh", "-c", "pw-dump 2>/dev/null | jq '[.[] | select(.type==\"PipeWire:Interface:Node\" and (.info.props[\"media.class\"]? // \"\" | test(\"Stream/Output/Video\")) and .info.state==\"running\")] | length' 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                privacyState.screenSharing = parseInt(this.text.trim() || "0") > 0;
            }
        }
    }
}
