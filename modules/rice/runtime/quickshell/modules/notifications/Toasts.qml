import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../../core"
import "../../components"
import "../../components/effects"
import "../../services/notifications"

// ── Toasts ────────────────────────────────────────────────────
// Transient popup stack for incoming notifications (top-right).
// Subscribes to NotificationState.received — the user-initiated
// hint — so it never fires from boot-time state. Cards auto-expire
// after a few seconds; clicking dismisses the notification.
//
// Personas (D-056): correspondence settings may map apps to a
// persona — a card variant, icon, sound and a label shown beside
// the real app name. Unmapped apps keep the plain card; urgency
// still wins the colours and the critical sound.
//
// Ceremony (D-082): with correspondence.settings.ceremony every toast
// is a letter. It arrives as a sealed envelope filling its frame, the
// flap lifts, the envelope falls away and the message lies on paper,
// written in the theme's hand; when it goes, it burns away from the
// bottom edge (BurnEffect), or fades without the shader or with motion
// reduced. `{ paper; ink; wax; ember; seal?; hand?; print? }`: colour
// token refs, an .svg pressed into the wax, and the font families of
// the summary and the body.

PanelWindow {
    id: toasts

    required property var modelData
    screen: modelData

    visible: toastModel.count > 0

    WlrLayershell.namespace: "rice-toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
        right: Theme.metrics.bar.margin
    }

    implicitWidth: ceremonial ? 380 : 340
    implicitHeight: stack.height
    color: "transparent"

    readonly property var correspondence: Theme.widgetConfig("correspondence").settings ?? ({})
    readonly property var personas: correspondence.personas ?? []

    readonly property var ceremony: correspondence.ceremony ?? null
    readonly property bool ceremonial: ceremony !== null
    readonly property color paper: Effects.colorRef(ceremony?.paper ?? "fg.primary")
    readonly property color ink: Effects.colorRef(ceremony?.ink ?? "bg.sunken")
    readonly property color wax: Effects.colorRef(ceremony?.wax ?? "state.danger")
    readonly property color ember: Effects.colorRef(ceremony?.ember ?? "state.warn")
    // The envelope: the same paper, aged and warmed toward the wax.
    readonly property color envelope: Qt.darker(Qt.tint(paper, Qt.rgba(wax.r, wax.g, wax.b, 0.12)), 1.22)
    readonly property string seal: ceremony?.seal ?? ""
    readonly property string handFamily: ceremony?.hand ?? Theme.typography.families.display
    readonly property string printFamily: ceremony?.print ?? Theme.typography.families.sans

    // Matched case-insensitively on the app name or desktop entry.
    function personaFor(entry) {
        const keys = [entry.app, entry.desktopEntry].filter(k => k && k.length > 0).map(k => k.toLowerCase());
        return personas.find(p => (p.apps ?? []).some(a => keys.includes(a.toLowerCase()))) ?? null;
    }

    ListModel {
        id: toastModel
    }

    Connections {
        target: NotificationState
        function onReceived(entry) {
            if (ShellState.doNotDisturb)
                return;
            const persona = toasts.personaFor(entry);
            toastModel.append({
                nid: entry.id,
                app: entry.app,
                summary: entry.summary,
                body: entry.body,
                urgency: entry.urgency,
                variant: persona ? (persona.variant ?? "letter") : "",
                personaLabel: persona?.label ?? "",
                personaIcon: persona?.icon ?? ""
            });
            if (entry.urgency === 2 || !persona?.sound || !Sound.play(persona.sound))
                Sound.play(entry.urgency === 2 ? "notification-critical" : "notification");
            // Keep the stack shallow; oldest toast yields first.
            if (toastModel.count > 4)
                toastModel.remove(0);
        }
    }

    function removeToast(nid) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).nid === nid) {
                toastModel.remove(i);
                return;
            }
        }
    }

    // Whether the burn shader is compiled here (not in dev runs).
    BurnEffect {
        id: burnProbe
        visible: false
        width: 1
        height: 1
    }

    Column {
        id: stack
        width: parent.width
        spacing: Theme.metrics.space.sm

        Repeater {
            model: toastModel

            Rectangle {
                id: card

                required property var model
                readonly property bool letter: card.model.variant === "letter" || toasts.ceremonial
                readonly property bool urgent: card.model.urgency === 2
                // Letters open before they are read: 0 while sealed, 1
                // once the envelope has given way to the message.
                property real reveal: card.letter ? 0 : 1
                property real flapAngle: 0
                property real burn: 0
                property bool leaving: false

                // Inside the frame: its reach and border, then room so
                // the corner scrolls stay clear of the writing.
                readonly property int pad: plate.framed ? plate.reach + Theme.frameWidth + Theme.metrics.space.lg : Theme.metrics.space.md
                readonly property int inset: plate.framed ? plate.reach + Theme.frameWidth : 0

                width: stack.width
                height: content.height + card.pad * 2
                radius: plate.active ? 0 : Theme.metrics.radius.medium
                color: plate.active ? "transparent" : (card.urgent || card.letter ? Theme.colors.bg.elevated : Theme.colors.bg.mantle)
                border.width: plate.active ? 0 : 1
                border.color: card.urgent ? Theme.colors.state.danger
                    : (card.letter ? Qt.rgba(Theme.colors.accent.primary.r, Theme.colors.accent.primary.g, Theme.colors.accent.primary.b, 0.55) : Theme.colors.bg.surface1)

                // Persona letters without a ceremony keep their envelope
                // card; everything else may sit on the theme's toast frame
                // (D-076, D-081), urgent ones ruled red.
                PlateFrame {
                    id: plate
                    role: "toast"
                    visible: active
                    readonly property bool active: shown && (!card.letter || toasts.ceremonial)
                    rule: card.urgent ? Theme.colors.state.danger : Theme.colors.accent.primary
                    fill: toasts.ceremonial ? toasts.paper : Theme.colors.bg.mantle
                }
                Rectangle {
                    visible: plate.active && plate.piece !== null && card.urgent
                    anchors.fill: parent
                    anchors.margins: 6
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.colors.state.danger
                }

                // Parchment: the paper darkens toward its edges and foot.
                Rectangle {
                    visible: toasts.ceremonial && plate.framed
                    anchors.fill: parent
                    anchors.margins: card.inset
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Qt.rgba(1, 1, 1, 0.06)
                        }
                        GradientStop {
                            position: 0.55
                            color: "transparent"
                        }
                        GradientStop {
                            position: 1
                            color: Qt.rgba(toasts.ink.r, toasts.ink.g, toasts.ink.b, 0.16)
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 5
                        border.color: Qt.rgba(toasts.ink.r, toasts.ink.g, toasts.ink.b, 0.1)
                    }
                }

                opacity: 0
                // A letter is delivered: it slides in from the screen
                // edge. Motion specs collapse to 0ms under reduce-motion.
                transform: Translate {
                    id: arrival
                    x: card.letter ? Theme.metrics.space.lg * 2 : 0
                    Behavior on x {
                        MotionAnim {
                            spec: Motion.panelOpen
                        }
                    }
                }
                Component.onCompleted: {
                    opacity = 0.97;
                    arrival.x = 0;
                    if (card.letter)
                        opening.start();
                }

                // Arrive sealed, lift the flap, then let the envelope
                // fall away as the message and its seal come forward.
                // Every step is a Motion spec, so reduce-motion opens
                // the letter at once.
                // With a ceremony the sealed letter is held a moment and
                // every step takes the ceremonial pace.
                SequentialAnimation {
                    id: opening
                    PauseAnimation {
                        duration: toasts.ceremonial ? Motion.ritualAssemble.duration : Motion.panelOpen.duration
                    }
                    MotionAnim {
                        target: card
                        property: "flapAngle"
                        to: 180
                        spec: toasts.ceremonial ? Motion.ritualAssemble : Motion.cardFlip
                    }
                    ParallelAnimation {
                        MotionAnim {
                            target: card
                            property: "reveal"
                            to: 1
                            spec: toasts.ceremonial ? Motion.ritualAssemble : Motion.panelOpen
                        }
                        MotionAnim {
                            target: sealDisc
                            property: "scale"
                            from: 1.15
                            to: 1
                            spec: Motion.sealPress
                        }
                    }
                }

                // ── Leaving ──────────────────────────────────────
                // A letter burns away; anything else, or without the
                // shader or motion, fades.
                function leave() {
                    if (card.leaving)
                        return;
                    card.leaving = true;
                    if (toasts.ceremonial && burnProbe.ready && Motion.enabled)
                        burning.start();
                    else
                        fading.start();
                }

                layer.enabled: card.leaving && toasts.ceremonial && burnProbe.ready
                layer.effect: BurnEffect {
                    progress: card.burn
                    ember: toasts.ember
                    soot: toasts.ink
                }

                SequentialAnimation {
                    id: burning
                    NumberAnimation {
                        target: card
                        property: "burn"
                        to: 1
                        duration: Math.max(1400, Motion.ritualAssemble.duration * 2.4)
                        easing.type: Easing.InOutSine
                    }
                    ScriptAction {
                        script: toasts.removeToast(card.model.nid)
                    }
                }
                SequentialAnimation {
                    id: fading
                    MotionAnim {
                        target: card
                        property: "opacity"
                        to: 0
                        spec: Motion.fade
                    }
                    ScriptAction {
                        script: toasts.removeToast(card.model.nid)
                    }
                }

                // ── The envelope ─────────────────────────────────
                // With a ceremony it fills the frame; a persona letter
                // keeps the small envelope in its card.
                Item {
                    id: envelope
                    visible: card.letter && opacity > 0
                    x: toasts.ceremonial ? card.inset : (card.width - width) / 2
                    y: toasts.ceremonial ? card.inset : (card.height - height) / 2
                    width: toasts.ceremonial ? card.width - card.inset * 2 : height * 1.45
                    height: toasts.ceremonial ? card.height - card.inset * 2 : card.height - Theme.metrics.space.sm * 2
                    opacity: 1 - card.reveal
                    scale: 1 + card.reveal * 0.12

                    readonly property color ink: toasts.ceremonial ? Qt.rgba(toasts.ink.r, toasts.ink.g, toasts.ink.b, 0.45)
                        : (card.urgent ? Theme.colors.state.danger : Theme.colors.accent.primary)
                    readonly property color body: toasts.ceremonial ? toasts.envelope : Theme.colors.bg.sunken
                    readonly property color flap: toasts.ceremonial ? Qt.darker(toasts.envelope, 1.08) : Theme.colors.bg.elevated
                    readonly property color wax: toasts.ceremonial ? (card.urgent ? Theme.colors.state.danger : toasts.wax)
                        : (card.urgent ? Theme.colors.state.danger : Theme.colors.accent.primary)

                    Rectangle {
                        anchors.fill: parent
                        radius: toasts.ceremonial ? 0 : 2
                        color: envelope.body
                        border.width: 1
                        border.color: envelope.ink
                    }

                    // The folds below the flap.
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: envelope.ink
                            strokeWidth: 1
                            fillColor: "transparent"
                            startX: 1
                            startY: envelope.height - 1
                            PathLine {
                                x: envelope.width / 2
                                y: envelope.height * 0.5
                            }
                            PathLine {
                                x: envelope.width - 1
                                y: envelope.height - 1
                            }
                        }
                    }

                    // The flap swings up on its top edge and fades as it
                    // passes upright; the wax at its tip goes with it.
                    Item {
                        width: envelope.width
                        height: envelope.height * 0.6
                        opacity: card.flapAngle < 90 ? 1 : (180 - card.flapAngle) / 90
                        transform: Rotation {
                            origin.x: 0
                            origin.y: 0
                            axis {
                                x: 1
                                y: 0
                                z: 0
                            }
                            angle: card.flapAngle
                        }

                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: envelope.ink
                                strokeWidth: 1
                                fillColor: envelope.flap
                                joinStyle: ShapePath.RoundJoin
                                startX: 0.5
                                startY: 0.5
                                PathLine {
                                    x: envelope.width - 0.5
                                    y: 0.5
                                }
                                PathLine {
                                    x: envelope.width / 2
                                    y: envelope.height * 0.6
                                }
                                PathLine {
                                    x: 0.5
                                    y: 0.5
                                }
                            }
                        }

                        WaxSeal {
                            size: Math.min(envelope.height * 0.34, 40)
                            x: (envelope.width - size) / 2
                            y: envelope.height * 0.6 - size * 0.7
                            wax: envelope.wax
                            emblem: toasts.ceremonial ? toasts.seal : ""
                        }
                    }
                }

                Behavior on opacity {
                    enabled: !card.leaving
                    MotionAnim {
                        spec: Motion.panelOpen
                    }
                }

                Timer {
                    interval: card.urgent ? 8000 : (toasts.ceremonial ? 7500 : 5000)
                    running: true
                    onTriggered: card.leave()
                }

                Rectangle {
                    visible: !card.letter
                    width: 4
                    height: parent.height - Theme.metrics.space.md
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.metrics.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: card.urgent ? Theme.colors.state.danger
                        : (card.model.urgency === 0 ? Theme.colors.fg.subtle : Theme.colors.accent.primary)
                }

                // The letter's seal, broken open beside the message: the
                // persona's icon, or the ceremony's emblem in the wax.
                Item {
                    id: sealDisc
                    visible: card.letter
                    width: toasts.ceremonial ? 34 : Theme.typography.sizes.icon * 2
                    height: width
                    anchors.left: parent.left
                    anchors.leftMargin: toasts.ceremonial ? card.pad : Theme.metrics.space.md
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: card.reveal

                    WaxSeal {
                        visible: toasts.ceremonial
                        anchors.fill: parent
                        size: parent.width
                        wax: card.urgent ? Theme.colors.state.danger : toasts.wax
                        emblem: toasts.seal
                        icon: card.model.personaIcon
                    }

                    Rectangle {
                        visible: !toasts.ceremonial
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.colors.bg.sunken
                        border.width: 1
                        border.color: card.urgent ? Theme.colors.state.danger : Theme.colors.accent.primary

                        Icon {
                            anchors.centerIn: parent
                            name: card.model.personaIcon.length > 0 ? card.model.personaIcon : "mail"
                            size: Theme.typography.sizes.icon
                            color: Theme.colors.accent.primary
                        }
                    }
                }

                Column {
                    id: content
                    opacity: card.reveal
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: card.letter ? sealDisc.right : parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: card.letter ? Theme.metrics.space.md : Theme.metrics.space.lg
                    anchors.rightMargin: card.pad
                    spacing: toasts.ceremonial ? 1 : 2

                    readonly property color headInk: card.urgent ? Theme.colors.state.danger
                        : (toasts.ceremonial ? Qt.rgba(toasts.ink.r, toasts.ink.g, toasts.ink.b, 0.7) : Theme.colors.accent.primary)

                    Row {
                        width: parent.width
                        spacing: Theme.metrics.space.xs

                        Text {
                            id: appName
                            text: card.model.app
                            color: content.headInk
                            font.family: toasts.ceremonial ? Theme.typography.families.display : Theme.typography.families.sans
                            font.capitalization: toasts.ceremonial ? Font.SmallCaps : Font.MixedCase
                            font.letterSpacing: toasts.ceremonial ? 1 : 0
                            font.pointSize: Theme.typography.sizes.small
                        }
                        Text {
                            visible: card.model.personaLabel.length > 0
                            width: Math.max(0, parent.width - appName.width - parent.spacing)
                            text: "· " + card.model.personaLabel
                            color: toasts.ceremonial ? content.headInk : Theme.colors.fg.subtle
                            elide: Text.ElideRight
                            font.family: toasts.ceremonial ? toasts.printFamily : Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                            font.italic: true
                        }
                    }
                    Text {
                        width: parent.width
                        text: card.model.summary
                        color: toasts.ceremonial ? toasts.ink : Theme.colors.fg.primary
                        elide: Text.ElideRight
                        // A hand needs room: it may take a second line.
                        wrapMode: toasts.ceremonial ? Text.WordWrap : Text.NoWrap
                        maximumLineCount: toasts.ceremonial ? 2 : 1
                        lineHeight: toasts.ceremonial ? 0.85 : 1
                        font.family: toasts.ceremonial ? toasts.handFamily : Theme.typography.families.sans
                        font.pointSize: toasts.ceremonial ? Theme.typography.sizes.body * 1.7 : Theme.typography.sizes.body
                        font.weight: toasts.ceremonial ? Font.Normal : Theme.typography.weights.medium
                    }
                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: card.model.body
                        color: toasts.ceremonial ? Qt.rgba(toasts.ink.r, toasts.ink.g, toasts.ink.b, 0.85) : Theme.colors.fg.muted
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        font.family: toasts.ceremonial ? toasts.printFamily : Theme.typography.families.sans
                        font.italic: toasts.ceremonial
                        font.pointSize: toasts.ceremonial ? Theme.typography.sizes.small * 1.2 : Theme.typography.sizes.small
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        NotificationState.dismiss(card.model.nid);
                        card.leave();
                    }
                }
            }
        }
    }

    // A pressed wax disc: a darker rim and lip, a highlight, and the
    // emblem (an .svg) or icon sunk into it.
    component WaxSeal: Item {
        id: seal

        property real size: 32
        property color wax: "darkred"
        property string emblem: ""
        property string icon: ""

        width: size
        height: size

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.darker(seal.wax, 1.35)
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: seal.size * 0.09
            radius: width / 2
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.lighter(seal.wax, 1.25)
                }
                GradientStop {
                    position: 1
                    color: Qt.darker(seal.wax, 1.15)
                }
            }
            border.width: 1
            border.color: Qt.darker(seal.wax, 1.6)
        }
        Image {
            id: emblemImage
            visible: seal.emblem.length > 0
            anchors.centerIn: parent
            width: seal.size * 0.56
            height: width
            source: visible ? Theme.assetUrl(seal.emblem) : ""
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            layer.enabled: visible
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: Qt.darker(seal.wax, 1.7)
            }
        }
        Icon {
            visible: seal.emblem.length === 0 && seal.icon.length > 0
            anchors.centerIn: parent
            name: seal.icon.length > 0 ? seal.icon : "mail"
            size: seal.size * 0.45
            color: Qt.darker(seal.wax, 1.7)
        }
    }
}
