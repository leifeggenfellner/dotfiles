import QtQuick

// ── TarotDraw ────────────────────────────────────────────────
// LOTM theme plugin. Receives `prefs` by widget service injection;
// receives theme/motion facades by mount injection so it does not
// instantiate runtime singletons from its packaged store path.

Rectangle {
    id: root

    property var services: ({})
    property var settings: ({})
    property var theme: ({
            colors: {
                bg: {
                    base: "#1b1510",
                    elevated: "#2a211a",
                    sunken: "#0e0a06",
                    surface1: "#3e3121"
                },
                fg: {
                    primary: "#e6d7b8",
                    muted: "#b5a284",
                    subtle: "#857556"
                },
                accent: {
                    primary: "#c79a3a"
                }
            },
            metrics: {
                radius: {
                    small: 8,
                    medium: 10
                },
                space: {
                    xs: 4,
                    md: 12,
                    lg: 16
                }
            },
            typography: {
                families: {
                    display: "serif",
                    sans: "sans-serif",
                    mono: "monospace"
                },
                sizes: {
                    small: 10,
                    body: 13,
                    heading: 18
                }
            }
        })
    property var motion: ({
            sealPress: {
                duration: 160,
                easing: Easing.OutCubic
            },
            cardFlip: {
                duration: 280,
                easing: Easing.OutBack
            }
        })

    readonly property var prefs: services.prefs ?? null
    readonly property string namespace: "tarotDraw"
    readonly property string key: "daily"
    readonly property string today: Qt.formatDate(new Date(), "yyyy-MM-dd")
    readonly property string title: settings.title ?? "Tarot Draw"
    readonly property string prompt: settings.prompt ?? "Draw today's omen"
    readonly property string redrawLabel: settings.redrawLabel ?? "redraw"
    readonly property string emptyLabel: settings.emptyLabel ?? "No omen has been drawn."
    readonly property var daily: prefs ? prefs.extra(namespace, key, ({})) : ({})
    readonly property bool hasDaily: daily.date === today && daily.card !== undefined
    readonly property var currentCard: hasDaily ? cards[Math.max(0, Math.min(cards.length - 1, daily.card))] : null

    property bool revealed: hasDaily

    width: 672
    height: 252
    radius: theme.metrics.radius.medium
    color: theme.colors.bg.base
    border.width: 1
    border.color: theme.colors.bg.surface1

    onHasDailyChanged: revealed = hasDaily

    readonly property var cards: [
        {
            name: "The Fool",
            sequence: "0",
            phrase: "A door opens above the gray fog.",
            face: "fool.png",
            back: "fool.png"
        },
        {
            name: "The Magician",
            sequence: "I",
            phrase: "A precise hand turns chance into ritual.",
            face: "magician.png",
            back: "magician.png"
        },
        {
            name: "The High Priestess",
            sequence: "II",
            phrase: "Silence keeps the safer half of knowledge.",
            face: "priestess.png",
            back: "priestess.png"
        },
        {
            name: "The Hermit",
            sequence: "IX",
            phrase: "A lamp is enough when the path is honest.",
            face: "hermit.png",
            back: "hermit.png"
        },
        {
            name: "Wheel of Fortune",
            sequence: "X",
            phrase: "The machine turns; the omen is timing.",
            face: "wheel.png",
            back: "wheel.png"
        },
        {
            name: "The Moon",
            sequence: "XVIII",
            phrase: "Not every shadow belongs to a monster.",
            face: "moon.png",
            back: "moon.png"
        },
        {
            name: "The World",
            sequence: "XXI",
            phrase: "A circle closes without becoming a cage.",
            face: "world.png",
            back: "world.png"
        }
    ]

    function facePath(card) {
        return "assets/faces/" + card.face;
    }

    function backPath(card) {
        return card && card.back ? "assets/backs/" + card.back : "assets/back.svg";
    }

    function visibleCardPath() {
        if (root.hasDaily && root.revealed && root.currentCard)
            return facePath(root.currentCard);
        return backPath(root.currentCard);
    }

    function draw() {
        if (!prefs)
            return;
        const seed = today.split("").reduce((acc, ch) => acc + ch.charCodeAt(0), 0) + Math.floor(Math.random() * 1000);
        const index = seed % cards.length;
        prefs.setExtra(namespace, key, {
            date: today,
            card: index
        });
        revealed = false;
        revealTimer.restart();
    }

    Timer {
        id: revealTimer
        interval: root.motion.cardFlip.duration
        repeat: false
        onTriggered: root.revealed = true
    }

    Row {
        anchors.fill: parent
        anchors.margins: root.theme.metrics.space.lg
        spacing: root.theme.metrics.space.lg

        Rectangle {
            id: cardFrame
            width: 144
            height: 204
            radius: root.theme.metrics.radius.medium
            color: root.theme.colors.bg.sunken
            border.width: 1
            border.color: root.hasDaily ? root.theme.colors.accent.primary : root.theme.colors.bg.surface1
            scale: drawMouse.pressed ? 0.96 : 1
            rotation: root.revealed ? 0 : 2

            Image {
                anchors.fill: parent
                anchors.margins: root.theme.metrics.space.xs
                source: Qt.resolvedUrl(root.visibleCardPath())
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                id: drawMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.draw()
            }

            Behavior on scale {
                NumberAnimation {
                    duration: root.motion.sealPress.duration
                    easing.type: root.motion.sealPress.easing
                }
            }
            Behavior on rotation {
                NumberAnimation {
                    duration: root.motion.cardFlip.duration
                    easing.type: root.motion.cardFlip.easing
                }
            }
        }

        Column {
            width: parent.width - cardFrame.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.metrics.space.md

            Row {
                width: parent.width
                spacing: root.theme.metrics.space.md

                Text {
                    text: root.title
                    color: root.theme.colors.fg.primary
                    font.family: root.theme.typography.families.display
                    font.pointSize: root.theme.typography.sizes.heading
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: drawText.width + root.theme.metrics.space.md * 2
                    height: 28
                    radius: root.theme.metrics.radius.small
                    color: actionMouse.containsMouse ? root.theme.colors.bg.elevated : root.theme.colors.bg.sunken
                    border.width: 1
                    border.color: actionMouse.containsMouse ? root.theme.colors.accent.primary : root.theme.colors.bg.surface1

                    Text {
                        id: drawText
                        anchors.centerIn: parent
                        text: root.hasDaily ? root.redrawLabel : root.prompt
                        color: root.theme.colors.fg.primary
                        font.family: root.theme.typography.families.sans
                        font.pointSize: root.theme.typography.sizes.small
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.draw()
                    }
                }
            }

            Text {
                width: parent.width
                text: root.currentCard ? root.currentCard.sequence + " · " + root.currentCard.name : root.emptyLabel
                color: root.currentCard ? root.theme.colors.accent.primary : root.theme.colors.fg.subtle
                font.family: root.theme.typography.families.display
                font.pointSize: root.theme.typography.sizes.heading
            }

            Text {
                width: parent.width
                text: root.currentCard ? root.currentCard.phrase : "A single card may be recorded for the day."
                color: root.theme.colors.fg.muted
                wrapMode: Text.WordWrap
                font.family: root.theme.typography.families.sans
                font.pointSize: root.theme.typography.sizes.body
            }

            Text {
                text: root.hasDaily ? "sealed for " + root.today : "waiting for a draw"
                color: root.theme.colors.fg.subtle
                font.family: root.theme.typography.families.mono
                font.pointSize: root.theme.typography.sizes.small
            }
        }
    }
}
