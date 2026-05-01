import QtQuick
import "../../"

// ── Sigil ─────────────────────────────────────────────────────
// Rounded bar button. Shows an icon glyph (Nerd Font or unicode).
// Drives its own hover glow; never owns a popout.

Item {
    id: sigil

    property string glyph: ""
    property color glyphColor: Theme.text
    property color activeColor: Theme.accent
    property bool active: false
    property int iconSize: Theme.fontSizeIcon

    implicitWidth: 36
    implicitHeight: Theme.barHeight

    property bool _hovered: false

    Rectangle {
        id: bg
        anchors.centerIn: parent
        width: sigil.implicitWidth
        height: 28
        radius: Theme.sigilRadius
        color: sigil.active ? Qt.rgba(sigil.activeColor.r, sigil.activeColor.g, sigil.activeColor.b, 0.15) : sigil._hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDurationFast
            }
        }

        Text {
            anchors.centerIn: parent
            text: sigil.glyph
            font.pixelSize: sigil.iconSize
            font.family: Theme.fontMono
            color: sigil.active ? sigil.activeColor : sigil.glyphColor

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animDurationFast
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: sigil._hovered = true
        onExited: sigil._hovered = false
        onClicked: sigil.clicked()
    }

    signal clicked
}
