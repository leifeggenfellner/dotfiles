import QtQuick
import QtQuick.Effects
import "../../core"
import "../../services/apps"

// ── CarouselCard ──────────────────────────────────────────────
// One card plate on the carousel drum (D-067). In front, the
// workspace's sigil with a glow in its colour; behind it, the app
// icons of its windows, or an ink fog in its colour when it has none
// (captures replace the icons in phase 4c); along the bottom, a
// nameplate with the workspace label and its window count.
//
//   entry    a widgets.workspaces.settings.items entry
//   windows  its window count (HyprState.workspaceWindows)
//   apps     app ids of its windows (HyprState.workspaceApps)
//   style    widgets.workspaces.settings.carousel
//   front    the card the drum faces

Item {
    id: card

    required property var entry
    required property int windows
    required property var apps
    property var style: ({})
    property bool front: false

    readonly property color tint: entry.color ?? Theme.colors.accent.primary
    readonly property var copy: style.copy ?? ({})
    readonly property int maxIcons: 6
    readonly property string countText: {
        if (windows === 0)
            return copy.none ?? "No windows";
        if (windows === 1)
            return copy.one ?? "1 window";
        return (copy.many ?? "{n} windows").replace("{n}", windows);
    }
    readonly property int inset: Theme.metrics.space.md

    component Plate: Item {
        id: plate

        property var piece: null

        BorderImage {
            visible: plate.piece !== null
            anchors.fill: parent
            source: plate.piece ? Theme.assetUrl(plate.piece.src) : ""
            border.left: plate.piece ? plate.piece.slice[0] : 0
            border.top: plate.piece ? plate.piece.slice[1] : 0
            border.right: plate.piece ? plate.piece.slice[2] : 0
            border.bottom: plate.piece ? plate.piece.slice[3] : 0
            smooth: true
        }
    }

    // ── Frame ─────────────────────────────────────────────────
    Rectangle {
        visible: !card.style.card
        anchors.fill: parent
        radius: Theme.metrics.radius.medium
        color: Theme.colors.bg.mantle
        border.width: 1
        border.color: card.front ? card.tint : Theme.colors.bg.surface1
    }

    Plate {
        anchors.fill: parent
        piece: card.style.card ?? null
    }

    Item {
        id: face

        anchors.fill: parent
        anchors.margins: card.inset
        anchors.bottomMargin: card.inset + nameplate.height

        // Empty: an ink fog in the workspace's colour.
        Rectangle {
            visible: card.windows === 0
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.9
            height: width
            radius: width / 2
            color: card.tint
            opacity: 0.4

            layer.enabled: visible
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 48
            }
        }

        // Occupied: its windows' app icons, sitting back.
        Row {
            visible: card.windows > 0
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.metrics.space.sm
            opacity: 0.7

            layer.enabled: visible
            layer.effect: MultiEffect {
                saturation: -0.5
            }

            Repeater {
                model: card.apps.slice(0, card.maxIcons)

                delegate: Image {
                    required property string modelData

                    width: 22
                    height: 22
                    source: AppsState.iconFor(modelData)
                    sourceSize.width: 44
                    sourceSize.height: 44
                    smooth: true
                }
            }

            Text {
                visible: card.apps.length > card.maxIcons
                anchors.verticalCenter: parent.verticalCenter
                text: "+" + (card.apps.length - card.maxIcons)
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }

        // The sigil, large, with its glow.
        Item {
            id: sigil

            readonly property string spec: card.entry.icon ?? ""
            readonly property bool isFile: Theme.iconIsFile(spec)
            readonly property int size: Math.min(72, face.height - 28)

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: size
            height: size

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: card.tint
                shadowBlur: 1
                shadowOpacity: card.front ? 0.9 : 0.45
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            Image {
                visible: sigil.isFile
                anchors.fill: parent
                source: sigil.isFile ? Theme.assetUrl(sigil.spec) : ""
                sourceSize.width: sigil.size * 2
                sourceSize.height: sigil.size * 2
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                visible: !sigil.isFile
                anchors.centerIn: parent
                text: sigil.isFile ? "" : (sigil.spec.length > 0 ? sigil.spec : String(card.entry.id))
                color: card.tint
                font.family: Theme.typography.families.mono
                font.pixelSize: sigil.size * 0.7
            }
        }
    }

    // ── Nameplate ─────────────────────────────────────────────
    Item {
        id: nameplate

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: card.inset / 2
        height: 46

        Rectangle {
            visible: !card.style.nameplate
            anchors.fill: parent
            radius: Theme.metrics.radius.small
            color: Theme.colors.bg.elevated
        }

        Plate {
            anchors.fill: parent
            piece: card.style.nameplate ?? null
        }

        Column {
            anchors.centerIn: parent
            spacing: 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: card.entry.label ?? String(card.entry.id)
                color: Theme.colors.fg.primary
                font.family: Theme.typography.families.display
                font.pointSize: Theme.typography.sizes.body
                font.capitalization: Font.SmallCaps
                font.letterSpacing: 1
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: card.countText
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
