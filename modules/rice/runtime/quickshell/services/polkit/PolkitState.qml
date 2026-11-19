pragma Singleton
import QtQuick
import Quickshell.Services.Polkit

// ── PolkitState — REAL ────────────────────────────────────────
// The session's polkit authentication agent (D-008 tier 1: Quickshell
// native PolkitAgent). Requests queue in the agent; at most one is
// active. A failed attempt starts a fresh session automatically, so a
// wrong password just asks again with `error` set.
//
// The response (a password) passes straight from submit() to the
// agent: this service never stores, logs or exposes it.
//
//   state:    available, active, message, prompt, echo, responseRequired,
//             identity, actionId, iconName, notice, error, attemptFailed
//   commands: submit(response), cancel()

Item {
    id: polkit

    readonly property bool mock: false
    // False when another agent (e.g. polkit-gnome) already holds the session.
    readonly property bool available: agent.isRegistered
    readonly property bool active: agent.isActive && agent.flow !== null

    readonly property var _flow: agent.flow
    readonly property string message: _flow?.message ?? ""
    readonly property string prompt: _flow?.inputPrompt ?? ""
    readonly property bool echo: _flow?.responseVisible ?? false
    readonly property bool responseRequired: _flow?.isResponseRequired ?? false
    readonly property string identity: _flow?.selectedIdentity?.displayName ?? ""
    readonly property string actionId: _flow?.actionId ?? ""
    readonly property string iconName: _flow?.iconName ?? ""
    // PAM's supplementary line, split by kind ("Password: ", lockouts, …).
    readonly property string notice: _flow && !_flow.supplementaryIsError ? _flow.supplementaryMessage : ""
    readonly property string error: _flow && _flow.supplementaryIsError ? _flow.supplementaryMessage : ""
    readonly property bool attemptFailed: _flow?.failed ?? false

    // Edge for consumers that react to each wrong attempt (e.g. a shake).
    signal attemptRejected

    function submit(response) {
        if (_flow && _flow.isResponseRequired)
            _flow.submit(String(response ?? ""));
    }

    function cancel() {
        if (_flow)
            _flow.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent
    }

    Connections {
        target: polkit._flow
        function onAuthenticationFailed() {
            polkit.attemptRejected();
        }
    }
}
