pragma Singleton
import QtQuick
import Quickshell.Io

// Monitor-control daemon client (D-008 tier 3: event-triggered CLI).
//
//   state:    available, busy, error, mode, selectedProfile,
//             activeProfile, connectedOutputs, unknownOutputs,
//             availableProfiles, warnings, updatedAt
//   commands: refresh(), selectProfile(profile), useAuto(), reconcile(),
//             clearError()
//
// Durable selection and active topology remain owned by monitor-control.

Item {
    id: monitorControl

    readonly property bool mock: false
    property bool available: false
    property bool busy: false
    property string error: ""
    property string mode: ""
    property string selectedProfile: ""
    property string activeProfile: ""
    property var connectedOutputs: ({})
    property var unknownOutputs: []
    property var availableProfiles: []
    property var warnings: []
    property int updatedAt: 0
    property bool _refreshPending: false
    property bool _statusParsed: false

    function clearError() {
        error = "";
    }

    function refresh() {
        if (statusProc.running) {
            _refreshPending = true;
            return;
        }
        _statusParsed = false;
        statusProc.running = true;
    }

    function selectProfile(profile) {
        if (busy)
            return;
        if (typeof profile !== "string" || availableProfiles.indexOf(profile) < 0) {
            error = "Unknown monitor profile";
            return;
        }
        _run(["monitor-control", "select", profile]);
    }

    function useAuto() {
        _run(["monitor-control", "auto"]);
    }

    function reconcile() {
        _run(["monitor-control", "reconcile"]);
    }

    function _run(command) {
        if (busy)
            return;
        busy = true;
        error = "";
        actionProc.command = command;
        actionProc.running = true;
    }

    function _resetStatus(message) {
        available = false;
        mode = "";
        selectedProfile = "";
        activeProfile = "";
        connectedOutputs = ({});
        unknownOutputs = [];
        availableProfiles = [];
        warnings = [];
        updatedAt = 0;
        error = message;
    }

    function _stringList(value) {
        if (!Array.isArray(value))
            return [];

        const names = [];
        for (const profile of value) {
            if (typeof profile === "string" && profile.length > 0 && names.indexOf(profile) < 0)
                names.push(profile);
        }
        return names;
    }

    function _applyStatus(text) {
        _statusParsed = true;
        try {
            const status = JSON.parse(text.trim());
            if (status === null || Array.isArray(status) || typeof status !== "object" || status.schemaVersion !== 1)
                throw new Error("unsupported status schema");
            available = status.available === true;
            mode = typeof status.mode === "string" ? status.mode : "";
            selectedProfile = typeof status.selectedProfile === "string" ? status.selectedProfile : "";
            activeProfile = typeof status.activeProfile === "string" ? status.activeProfile : "";
            connectedOutputs = status.connected !== null && typeof status.connected === "object" && !Array.isArray(status.connected) ? status.connected : ({});
            unknownOutputs = _stringList(status.unknownOutputs);
            availableProfiles = _stringList(status.availableProfiles);
            warnings = available ? _stringList(status.warnings) : [];
            updatedAt = typeof status.updatedAt === "number" ? status.updatedAt : 0;
            error = typeof status.lastError === "string" ? status.lastError : "";
        } catch (parseError) {
            _resetStatus("Monitor status is unreadable");
        }
    }

    Process {
        id: statusProc
        command: ["monitor-control", "status"]
        stdout: StdioCollector {
            onStreamFinished: monitorControl._applyStatus(text)
        }
        stderr: StdioCollector {
            id: statusError
        }
        onExited: (code, status) => {
            if (!monitorControl._statusParsed) {
                monitorControl._resetStatus(statusError.text.trim().length > 0 ? "Monitor control is unavailable" : "Monitor status is unavailable");
            }
            if (monitorControl._refreshPending) {
                monitorControl._refreshPending = false;
                monitorControl.refresh();
            }
        }
    }

    Process {
        id: actionProc
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: actionError
        }
        onExited: (code, status) => {
            monitorControl.busy = false;
            if (code !== 0)
                monitorControl.error = actionError.text.trim().length > 0 ? "Monitor profile change failed" : "Monitor control service is unavailable";
            monitorControl.refresh();
        }
    }

    Component.onCompleted: refresh()
}
