import QtQuick
import "../core"

// ── PageStack ─────────────────────────────────────────────────
// Home and drill-in pages inside one popout. `pages` maps a name to a
// Component; `open(name)` slides it in from the right, `back()` slides
// home back from the left. Under reduce-motion pages only fade. The
// stack's height follows the shown page. Each page may define
// `function focusFirst()`, called once it is in.
// Keys: ←, Backspace or Esc on a page goes back.

FocusScope {
    id: root

    property Component home: null
    property var pages: ({})
    readonly property string current: _shown

    property string _shown: ""
    property string _next: ""
    property int _direction: 1

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0
    clip: true

    Behavior on implicitHeight {
        MotionAnim {
            spec: Motion.stateChange
        }
    }

    function open(name) {
        if (!(name in root.pages) || name === root._shown)
            return;
        root._go(name, 1);
    }
    function back() {
        if (root._shown.length > 0)
            root._go("", -1);
    }

    function _go(name, direction) {
        root._next = name;
        root._direction = direction;
        swap.restart();
    }

    Loader {
        id: loader
        width: root.width
        focus: true
        sourceComponent: root._shown.length > 0 ? root.pages[root._shown] : root.home
        onLoaded: Qt.callLater(() => {
            if (loader.item && typeof loader.item.focusFirst === "function")
                loader.item.focusFirst();
            else if (loader.item)
                loader.item.forceActiveFocus();
        })
    }

    SequentialAnimation {
        id: swap
        ParallelAnimation {
            MotionAnim {
                target: loader
                property: "opacity"
                to: 0
                spec: Motion.panelClose
            }
            MotionAnim {
                target: loader
                property: "x"
                to: Motion.enabled ? -root._direction * root.width * 0.25 : 0
                spec: Motion.panelClose
            }
        }
        ScriptAction {
            script: {
                root._shown = root._next;
                loader.x = Motion.enabled ? root._direction * root.width * 0.25 : 0;
            }
        }
        ParallelAnimation {
            MotionAnim {
                target: loader
                property: "opacity"
                to: 1
                spec: Motion.panelOpen
            }
            MotionAnim {
                target: loader
                property: "x"
                to: 0
                spec: Motion.panelOpen
            }
        }
    }

    Keys.onPressed: event => {
        if (root._shown.length === 0)
            return;
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace || event.key === Qt.Key_Escape) {
            root.back();
            event.accepted = true;
        }
    }
}
