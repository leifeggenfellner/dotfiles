pragma Singleton
import QtQuick
import Quickshell.Io

// ── WindowStatsState — REAL ──────────────────────────────────
// Visible windows joined with per-process resource use, for the
// window inspector overlay (D-043). Updates run ONLY while a
// consumer holds them (acquireUpdates/releaseUpdates); with no
// consumer there is no timer and no process.
//
// Backend: one short probe per tick — `hyprctl -j clients`,
// `hyprctl -j monitors`, and every /proc/<pid>/stat. Justified
// D-008 tier 4: per-process CPU/RSS counters have no event source,
// and Quickshell's native lastIpcObject refresh is asynchronous with
// no completion signal, so one process is the only way to get
// geometry and counters from the same instant.
//
//   state:    available, busy, error, updatesActive, sampled
//             windows: [{ address, pid, title, appClass, monitorName,
//                         workspaceId, workspaceName, special,
//                         floating, fullscreen, focused,
//                         x, y, width, height  (monitor-local),
//                         cpuPercent  (% of one core over the subtree,
//                                      -1 until two samples exist),
//                         memoryBytes (RSS summed over the subtree),
//                         processCount, pidWindowCount }]
//   commands: acquireUpdates(), releaseUpdates(), refresh()
//
// A window is listed when it is mapped, not a hidden group member,
// and on its monitor's active workspace — or on the monitor's open
// special workspace, which then hides the regular one. When a
// fullscreen window is visible on a monitor, only it is listed.
// Resource figures cover the window's PID and all its descendants;
// windows sharing a PID (one process, several windows) report the
// same figures and carry pidWindowCount > 1.

Item {
    id: stats

    readonly property bool mock: false
    property bool available: false
    property bool busy: false
    property string error: ""
    property var windows: []

    readonly property bool updatesActive: _updateConsumers > 0
    readonly property bool sampled: _lastSampleMs > 0
    property int _updateConsumers: 0
    property var _lastTicks: ({})
    property real _lastSampleMs: 0
    property int _sampleCount: 0

    function acquireUpdates() {
        _updateConsumers++;
        if (_updateConsumers === 1)
            refresh();
    }

    function releaseUpdates() {
        _updateConsumers = Math.max(0, _updateConsumers - 1);
        if (_updateConsumers === 0) {
            // Stale baselines would produce a bogus first CPU delta.
            _lastTicks = {};
            _lastSampleMs = 0;
            _sampleCount = 0;
            windows = [];
        }
    }

    function refresh() {
        if (probe.running)
            return;
        busy = true;
        probe.running = true;
    }

    function _section(text, name) {
        const start = text.indexOf("\n@@" + name + "\n");
        if (start < 0)
            return "";
        const from = start + name.length + 4;
        const next = text.indexOf("\n@@", from);
        return text.slice(from, next < 0 ? text.length : next);
    }

    function _parse(text, nowMs) {
        let clients, monitors;
        try {
            clients = JSON.parse(_section(text, "clients"));
            monitors = JSON.parse(_section(text, "monitors"));
        } catch (e) {
            error = "compositor query failed";
            return;
        }

        const header = _section(text, "sys").trim().split(" ");
        const clk = Number(header[0]) > 0 ? Number(header[0]) : 100;
        const page = Number(header[1]) > 0 ? Number(header[1]) : 4096;

        // pid → { ppid, ticks, rss } for every process, then children.
        const procs = {};
        const children = {};
        const lines = _section(text, "proc").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const f = lines[i].split(" ");
            if (f.length !== 4)
                continue;
            procs[f[0]] = {
                ppid: f[1],
                ticks: Number(f[2]),
                rss: Number(f[3]) * page
            };
            (children[f[1]] = children[f[1]] ?? []).push(f[0]);
        }

        const subtreeCache = {};
        function subtree(pid) {
            const key = String(pid);
            if (subtreeCache[key])
                return subtreeCache[key];
            const total = {
                ticks: 0,
                rss: 0,
                count: 0
            };
            const stack = [key];
            const seen = {};
            while (stack.length > 0) {
                const p = stack.pop();
                if (seen[p] || !procs[p])
                    continue;
                seen[p] = true;
                total.ticks += procs[p].ticks;
                total.rss += procs[p].rss;
                total.count++;
                const kids = children[p] ?? [];
                for (let k = 0; k < kids.length; k++)
                    stack.push(kids[k]);
            }
            subtreeCache[key] = total;
            return total;
        }

        const monitorById = {};
        for (let i = 0; i < monitors.length; i++) {
            const m = monitors[i];
            monitorById[m.id] = {
                name: m.name,
                x: m.x,
                y: m.y,
                activeId: m.activeWorkspace?.id,
                special: m.specialWorkspace?.name ?? "",
                focused: m.focused === true
            };
        }

        const visible = [];
        for (let i = 0; i < clients.length; i++) {
            const c = clients[i];
            const m = monitorById[c.monitor];
            if (!m || !c.mapped || c.hidden || !(c.pid > 0))
                continue;
            const wsName = c.workspace?.name ?? "";
            const onSpecial = m.special !== "" && wsName === m.special;
            const onActive = m.special === "" && c.workspace?.id === m.activeId;
            if (onSpecial || onActive)
                visible.push({
                    client: c,
                    monitor: m,
                    special: onSpecial
                });
        }

        const fullscreenOn = {};
        const pidWindows = {};
        for (let i = 0; i < visible.length; i++) {
            if (visible[i].client.fullscreen > 0)
                fullscreenOn[visible[i].monitor.name] = true;
            pidWindows[visible[i].client.pid] = (pidWindows[visible[i].client.pid] ?? 0) + 1;
        }

        const elapsed = _lastSampleMs > 0 ? (nowMs - _lastSampleMs) / 1000 : 0;
        const nextTicks = {};
        const next = [];
        for (let i = 0; i < visible.length; i++) {
            const c = visible[i].client;
            const m = visible[i].monitor;
            if (fullscreenOn[m.name] && !(c.fullscreen > 0))
                continue;
            const usage = subtree(c.pid);
            nextTicks[c.pid] = usage.ticks;
            const previous = _lastTicks[c.pid];
            const cpu = elapsed > 0 && previous !== undefined ? Math.max(0, (usage.ticks - previous) / clk / elapsed * 100) : -1;
            next.push({
                address: c.address,
                pid: c.pid,
                title: c.title ?? "",
                appClass: c.class ?? "",
                monitorName: m.name,
                workspaceId: c.workspace?.id ?? 0,
                workspaceName: c.workspace?.name ?? "",
                special: visible[i].special,
                floating: c.floating === true,
                fullscreen: c.fullscreen > 0,
                focused: c.focusHistoryID === 0,
                x: c.at[0] - m.x,
                y: c.at[1] - m.y,
                width: c.size[0],
                height: c.size[1],
                cpuPercent: cpu,
                memoryBytes: usage.rss,
                processCount: usage.count,
                pidWindowCount: pidWindows[c.pid]
            });
        }

        _lastTicks = nextTicks;
        _lastSampleMs = nowMs;
        _sampleCount++;
        windows = next;
        available = true;
        error = "";
    }

    // Per-process counters have no event source (see header). 1s is
    // the coarsest cadence that still reads as live while held; the
    // first follow-up sample comes sooner so CPU appears quickly.
    Timer {
        interval: stats._sampleCount < 2 ? 350 : 1000
        repeat: true
        running: stats.updatesActive
        onTriggered: stats.refresh()
    }

    Process {
        id: probe
        // Section markers keep one stdout stream parseable; the awk
        // strips "pid (comm) " up to the LAST ") " because comm may
        // contain spaces and parentheses. Fields after it: state,
        // ppid, … utime=12, stime=13, rss=22 (pages).
        command: ["sh", "-c", "LC_ALL=C; printf '\\n@@sys\\n%s %s\\n' \"$(getconf CLK_TCK)\" \"$(getconf PAGESIZE)\"; printf '\\n@@clients\\n'; hyprctl -j clients || exit 3; printf '\\n@@monitors\\n'; hyprctl -j monitors || exit 3; printf '\\n@@proc\\n'; cat /proc/[0-9]*/stat 2>/dev/null | awk '{ pid = $1; rest = $0; sub(/^.*\\) /, \"\", rest); n = split(rest, f, \" \"); if (n >= 22) printf \"%s %s %s %s\\n\", pid, f[2], f[12] + f[13], f[22] }'"]
        stdout: StdioCollector {
            id: stdout
            waitForEnd: true
        }
        onExited: (code, status) => {
            stats.busy = false;
            if (!stats.updatesActive)
                return;
            if (code !== 0) {
                stats.available = false;
                stats.error = "window probe failed (exit " + code + ")";
                return;
            }
            stats._parse(stdout.text, Date.now());
        }
    }
}
