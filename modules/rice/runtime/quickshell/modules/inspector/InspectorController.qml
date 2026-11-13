import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/windows"

// ── InspectorController ──────────────────────────────────────
// Owns the window inspector's lifecycle (D-043): IPC flips the
// ShellState flag, and while it is set this controller holds
// WindowStatsState updates. Hidden → no hold → no timer, no probe.
//
//   quickshell -c rice ipc call inspector open|close|toggle|status
//
// Hold-to-show is a press bind (open) plus a release bind (close).

Item {
    id: controller

    property bool _holding: false

    function _sync() {
        const want = ShellState.inspectorVisible;
        if (want && !_holding) {
            _holding = true;
            WindowStatsState.acquireUpdates();
        } else if (!want && _holding) {
            _holding = false;
            WindowStatsState.releaseUpdates();
        }
    }

    Connections {
        target: ShellState
        function onInspectorVisibleChanged() {
            controller._sync();
        }
    }

    Component.onDestruction: {
        if (_holding)
            WindowStatsState.releaseUpdates();
    }

    IpcHandler {
        target: "inspector"

        function open(): void {
            ShellState.setInspectorVisible(true);
        }
        function close(): void {
            ShellState.setInspectorVisible(false);
        }
        function toggle(): void {
            ShellState.setInspectorVisible(!ShellState.inspectorVisible);
        }
        function status(): string {
            return JSON.stringify({
                visible: ShellState.inspectorVisible,
                updatesActive: WindowStatsState.updatesActive,
                available: WindowStatsState.available,
                error: WindowStatsState.error,
                windows: WindowStatsState.windows.map(w => ({
                            monitor: w.monitorName,
                            workspace: w.workspaceName,
                            pid: w.pid,
                            appClass: w.appClass,
                            cpuPercent: Math.round(w.cpuPercent * 10) / 10,
                            memoryBytes: w.memoryBytes,
                            processCount: w.processCount
                        }))
            });
        }
    }
}
