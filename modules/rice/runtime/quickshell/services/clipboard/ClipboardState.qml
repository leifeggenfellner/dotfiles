pragma Singleton
import QtQuick
import Quickshell.Io

// ── ClipboardState — REAL ────────────────────────────────────
// cliphist-backed clipboard history. Hyprland owns the long-lived
// `wl-paste --watch cliphist store` process; this service refreshes
// the list on user demand and executes copy/delete commands.
// D-008 tier 3: event-triggered Process calls, no polling.
//
//   state:    available, busy, error, entries[] {key, raw, preview, kind}
//   commands: refresh(), copy(entry), deleteEntry(entry), clearError(),
//             search(query, limit)

Item {
    id: clipboard

    readonly property bool mock: false
    property bool available: true
    property bool busy: false
    property string error: ""
    property var entries: []

    function refresh() {
        if (busy)
            return;
        busy = true;
        error = "";
        list.running = true;
    }

    function clearError() {
        error = "";
    }

    function copy(entry) {
        if (!entry || busy)
            return;
        busy = true;
        error = "";
        copyProc.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "rice-clipboard-copy", entry.raw];
        copyProc.running = true;
    }

    function deleteEntry(entry) {
        if (!entry || busy)
            return;
        busy = true;
        error = "";
        deleteProc.command = ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "rice-clipboard-delete", entry.raw];
        deleteProc.running = true;
    }

    function search(query, limit) {
        const q = (query ?? "").trim().toLowerCase();
        const max = limit ?? 30;
        const filtered = q.length === 0
            ? entries
            : entries.filter(e => e.preview.toLowerCase().indexOf(q) >= 0 || e.kind.indexOf(q) >= 0);
        return filtered.slice(0, max);
    }

    function _parse(text) {
        const out = [];
        const seen = {};
        for (const line of text.split("\n")) {
            if (line.length === 0)
                continue;
            const tab = line.indexOf("\t");
            const key = tab >= 0 ? line.slice(0, tab) : line;
            const rawPreview = tab >= 0 ? line.slice(tab + 1) : line;
            const preview = _cleanPreview(rawPreview);
            if (key.length === 0 || seen[key])
                continue;
            seen[key] = true;
            out.push({
                key: key,
                raw: line,
                preview: preview,
                kind: _kind(preview)
            });
        }
        entries = out;
    }

    function _cleanPreview(text) {
        const s = (text ?? "").replace(/\s+/g, " ").trim();
        return s.length > 0 ? s : "empty clipboard entry";
    }

    function _kind(preview) {
        const p = preview.toLowerCase();
        if (p.indexOf("[[ binary data") >= 0 || p.indexOf("image/") >= 0)
            return "image";
        if (p.indexOf("file://") >= 0)
            return "file";
        return "text";
    }

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector { id: listOut; waitForEnd: true }
        stderr: StdioCollector { id: listErr; waitForEnd: true }
        onExited: (code, status) => {
            clipboard.busy = false;
            clipboard.available = (code !== 127);
            if (code === 0) {
                clipboard.error = "";
                clipboard._parse(listOut.text);
            } else {
                clipboard.error = code === 127 ? "cliphist is not installed" : (listErr.text.trim() || "cliphist list failed (exit " + code + ")");
            }
        }
    }

    Process {
        id: copyProc
        stderr: StdioCollector { id: copyErr; waitForEnd: true }
        onExited: (code, status) => {
            clipboard.busy = false;
            if (code === 0)
                clipboard.error = "";
            else
                clipboard.error = copyErr.text.trim() || "copy failed (exit " + code + ")";
        }
    }

    Process {
        id: deleteProc
        stderr: StdioCollector { id: deleteErr; waitForEnd: true }
        onExited: (code, status) => {
            clipboard.busy = false;
            if (code === 0) {
                clipboard.error = "";
                clipboard.refresh();
            } else {
                clipboard.error = deleteErr.text.trim() || "delete failed (exit " + code + ")";
            }
        }
    }
}
