pragma Singleton
import QtQuick
import Quickshell.Io

// ── SystemStatsState — REAL ──────────────────────────────────
// System vitals for dashboard widgets. Linux exposes CPU, memory,
// temperature, and filesystem counters through /proc, /sys, and
// statfs/df without a native Quickshell event source, so this is a
// justified D-008 tier 4 poll: one short process every 3s, only
// reading kernel counters, no long-lived polling loop per metric.
//
//   state: available, busy, error, cpuLoad [0..1], memoryPercent,
//          temperatureC (-1 when absent), diskPercent, byte totals

Item {
    id: stats

    readonly property bool mock: false
    property bool available: false
    property bool busy: false
    property string error: ""

    property real cpuLoad: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    readonly property real memoryPercent: memoryTotal > 0 ? memoryUsed / memoryTotal : 0
    property real temperatureC: -1
    property real diskUsed: 0
    property real diskTotal: 0
    readonly property real diskPercent: diskTotal > 0 ? diskUsed / diskTotal : 0

    property real _lastCpuTotal: 0
    property real _lastCpuIdle: 0

    function refresh() {
        if (probe.running)
            return;
        busy = true;
        probe.running = true;
    }

    function _number(map, key, fallback) {
        const value = Number(map[key]);
        return Number.isFinite(value) ? value : fallback;
    }

    function _parse(text) {
        const map = {};
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const cut = lines[i].indexOf("=");
            if (cut > 0)
                map[lines[i].slice(0, cut)] = lines[i].slice(cut + 1);
        }

        const total = _number(map, "cpuTotal", _lastCpuTotal);
        const idle = _number(map, "cpuIdle", _lastCpuIdle);
        const totalDelta = total - _lastCpuTotal;
        const idleDelta = idle - _lastCpuIdle;
        if (_lastCpuTotal > 0 && totalDelta > 0)
            cpuLoad = Math.max(0, Math.min(1, 1 - idleDelta / totalDelta));
        _lastCpuTotal = total;
        _lastCpuIdle = idle;

        memoryTotal = _number(map, "memTotal", memoryTotal);
        memoryUsed = _number(map, "memUsed", memoryUsed);
        diskTotal = _number(map, "diskTotal", diskTotal);
        diskUsed = _number(map, "diskUsed", diskUsed);
        temperatureC = _number(map, "tempC", -1);
        available = memoryTotal > 0 || diskTotal > 0 || total > 0;
    }

    Component.onCompleted: refresh()

    // No event source exists for aggregate CPU load, memory pressure,
    // hwmon temperature, or root filesystem usage. Keep the timer
    // coarse: dashboard vitals are glance data, not a profiler.
    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: stats.refresh()
    }

    Process {
        id: probe
        command: ["sh", "-c", "LC_ALL=C; awk '/^cpu / { total=0; for (i=2; i<=NF; i++) total += $i; printf \"cpuTotal=%s\\n\", total; printf \"cpuIdle=%s\\n\", $5 + $6 }' /proc/stat; awk '/^MemTotal:/ { total=$2 } /^MemAvailable:/ { avail=$2 } END { if (total > 0) { printf \"memTotal=%s\\n\", total * 1024; printf \"memUsed=%s\\n\", (total - avail) * 1024 } }' /proc/meminfo; df -Pk / | awk 'NR == 2 { printf \"diskTotal=%s\\n\", $2 * 1024; printf \"diskUsed=%s\\n\", $3 * 1024 }'; temp=; for f in /sys/class/hwmon/hwmon*/temp*_input; do [ -r \"$f\" ] || continue; v=$(cat \"$f\" 2>/dev/null) || continue; case \"$v\" in ''|*[!0-9-]*) continue ;; esac; if [ \"$v\" -gt 0 ] && [ \"$v\" -lt 120000 ]; then temp=$v; break; fi; done; [ -n \"$temp\" ] && awk -v t=\"$temp\" 'BEGIN { printf \"tempC=%.1f\\n\", t / 1000 }'"]
        stdout: StdioCollector { id: stdout; waitForEnd: true }
        stderr: StdioCollector { id: stderr; waitForEnd: true }
        onExited: (code, status) => {
            stats.busy = false;
            if (code !== 0) {
                stats.error = "stats probe failed (exit " + code + ")";
                return;
            }
            stats.error = "";
            stats._parse(stdout.text);
        }
    }
}
