import QtQuick
import "../../services/polkit"

// ── PolkitSurface ─────────────────────────────────────────────
// Per-screen loader for the authentication prompt. Referencing
// PolkitState here also creates the singleton at shell start, which is
// what registers the session's polkit agent.

Loader {
    id: surface

    required property var modelData

    active: PolkitState.active || (item !== null && item.visible)
    sourceComponent: PolkitPrompt {
        modelData: surface.modelData
    }
}
