pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: systemState

    // Normalized modulation channels in [0, 1].
    property real cpuLoad: 0.0
    property real netLoad: 0.0

    property real _prevCpuIdle: -1
    property real _prevCpuTotal: -1
    property real _prevNetBytes: -1
    property double _prevNetTimeMs: 0

    function _clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }

    function _poll() {
        if (!cpuPoll.running)
            cpuPoll.running = true;
        if (!netPoll.running)
            netPoll.running = true;
    }

    Timer {
        interval: 1200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: systemState._poll()
    }

    Process {
        id: cpuPoll
        command: [
            "sh",
            "-c",
            "awk 'NR==1 { idle=$5; total=0; for (i=2; i<=11; i++) total+=$i; print idle, total }' /proc/stat"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(/\s+/);
                if (parts.length < 2)
                    return;

                let idle = Number(parts[0]);
                let total = Number(parts[1]);

                if (isNaN(idle) || isNaN(total) || total <= 0)
                    return;

                if (systemState._prevCpuTotal >= 0 && total > systemState._prevCpuTotal) {
                    let deltaTotal = total - systemState._prevCpuTotal;
                    let deltaIdle = idle - systemState._prevCpuIdle;
                    let usage = systemState._clamp((deltaTotal - deltaIdle) / deltaTotal, 0.0, 1.0);

                    // Smooth spikes to keep modulation calm.
                    systemState.cpuLoad = systemState.cpuLoad * 0.65 + usage * 0.35;
                }

                systemState._prevCpuIdle = idle;
                systemState._prevCpuTotal = total;
            }
        }
    }

    Process {
        id: netPoll
        command: [
            "sh",
            "-c",
            "awk 'NR>2 { gsub(/:/, \"\", $1); if ($1 != \"lo\") { rx += $2; tx += $10 } } END { print rx + tx }' /proc/net/dev"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let bytes = Number(this.text.trim());
                if (isNaN(bytes) || bytes < 0)
                    return;

                let now = Date.now();

                if (systemState._prevNetBytes >= 0 && now > systemState._prevNetTimeMs) {
                    let deltaBytes = Math.max(0, bytes - systemState._prevNetBytes);
                    let dt = (now - systemState._prevNetTimeMs) / 1000.0;
                    let bytesPerSec = dt > 0 ? (deltaBytes / dt) : 0;
                    let normalized = systemState._clamp(bytesPerSec / 1000000.0, 0.0, 1.0);

                    // Smooth throughput spikes.
                    systemState.netLoad = systemState.netLoad * 0.75 + normalized * 0.25;
                }

                systemState._prevNetBytes = bytes;
                systemState._prevNetTimeMs = now;
            }
        }
    }
}
