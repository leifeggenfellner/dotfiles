import QtQuick
import "../../core"

// Descriptor-driven 12-column dashboard grid. The packer is deliberately kept
// here so Dashboard.qml only owns the shell/window lifecycle.
Item {
    id: root

    property var descriptors: []
    property var serviceResolver: null
    property bool surfaceActive: false
    property bool surfaceMapped: false
    property bool reducedMotion: false
    property int gap: Theme.metrics.space.md
    property int minColumns: 6
    property int maxColumns: 12
    property real compactBreakpoint: 900

    readonly property int columns: width < compactBreakpoint ? minColumns : maxColumns
    readonly property real columnWidth: columns > 0 ? Math.max(1, (width - gap * (columns - 1)) / columns) : 1
    readonly property real contentHeight: _contentHeight
    readonly property var placements: _placements
    property int focusIndex: placements.length > 0 ? Math.max(0, Math.min(_focusIndex, placements.length - 1)) : -1

    property var _placements: []
    property var _measuredHeights: ({})
    property real _contentHeight: 0
    property bool _layoutQueued: false
    property int _focusIndex: -1

    signal requestVisible(real y, real h)

    onWidthChanged: schedulePack()
    onColumnsChanged: schedulePack()
    onDescriptorsChanged: {
        _focusIndex = descriptors.length > 0 ? 0 : -1;
        schedulePack();
    }
    onFocusIndexChanged: {
        if (focusIndex >= 0 && focusIndex < placements.length) {
            const p = placements[focusIndex];
            requestVisible(p.y, p.height);
        }
    }
    Component.onCompleted: schedulePack()

    function descriptorKey(entry) {
        return entry.widget.widgetId + ":" + entry.sourceIndex;
    }

    function defaultLayout(widget) {
        const hint = widget.layout ?? {};
        const epigraphLike = widget.widgetId === "epigraph";
        return {
            colSpan: hint.colSpan ?? (epigraphLike ? 12 : 6),
            minHeight: hint.minHeight ?? (epigraphLike ? 112 : 180),
            priority: hint.priority ?? widget.priority ?? 0
        };
    }

    function effectiveSpan(widget) {
        const requested = Math.max(1, Math.min(maxColumns, defaultLayout(widget).colSpan));
        if (columns <= minColumns && requested >= 6)
            return minColumns;
        return Math.max(1, Math.min(columns, requested));
    }

    function sortedEntries() {
        return descriptors.map((widget, sourceIndex) => ({
                    widget,
                    sourceIndex,
                    layout: defaultLayout(widget)
                })).sort((a, b) => {
            const byPriority = a.layout.priority - b.layout.priority;
            return byPriority !== 0 ? byPriority : a.sourceIndex - b.sourceIndex;
        });
    }

    function measuredHeight(entry) {
        const key = descriptorKey(entry);
        const measured = _measuredHeights[key] ?? 0;
        return Math.max(1, measured > 0 ? measured : entry.layout.minHeight);
    }

    function findBestColumn(heights, span) {
        let bestColumn = 0;
        let bestY = Number.POSITIVE_INFINITY;

        // Skyline first-fit: for each legal span, look at the tallest occupied
        // column under it. The topmost candidate wins, ties keep the earlier
        // column, which gives top-left packing and fills holes from mixed cards.
        for (let column = 0; column <= columns - span; column++) {
            let y = 0;
            for (let offset = 0; offset < span; offset++)
                y = Math.max(y, heights[column + offset]);
            if (y < bestY) {
                bestY = y;
                bestColumn = column;
            }
        }

        return {
            column: bestColumn,
            y: bestY === Number.POSITIVE_INFINITY ? 0 : bestY
        };
    }

    function pack() {
        if (width <= 0 || columns <= 0) {
            _placements = [];
            _contentHeight = 0;
            return;
        }

        const heights = Array(columns).fill(0);
        const out = [];
        const ordered = sortedEntries();

        for (let i = 0; i < ordered.length; i++) {
            const entry = ordered[i];
            const span = effectiveSpan(entry.widget);
            const h = measuredHeight(entry);
            const fit = findBestColumn(heights, span);
            const x = fit.column * (columnWidth + gap);
            const y = fit.y === 0 ? 0 : fit.y + gap;
            const w = span * columnWidth + (span - 1) * gap;
            const key = descriptorKey(entry);

            out.push({
                key,
                widget: entry.widget,
                sourceIndex: entry.sourceIndex,
                placementIndex: i,
                column: fit.column,
                colSpan: span,
                x,
                y,
                width: w,
                height: h
            });

            const nextHeight = y + h;
            for (let offset = 0; offset < span; offset++)
                heights[fit.column + offset] = nextHeight;
        }

        _placements = out;
        _contentHeight = Math.max(0, ...heights);
        if (_focusIndex < 0 && out.length > 0)
            _focusIndex = 0;
    }

    function schedulePack() {
        if (_layoutQueued)
            return;
        _layoutQueued = true;
        Qt.callLater(() => {
            _layoutQueued = false;
            pack();
        });
    }

    function setMeasuredHeight(key, height) {
        const rounded = Math.ceil(Math.max(1, height));
        if ((_measuredHeights[key] ?? 0) === rounded)
            return;
        const next = Object.assign({}, _measuredHeights);
        next[key] = rounded;
        _measuredHeights = next;
        schedulePack();
    }

    function setFocusIndex(index) {
        if (placements.length === 0) {
            _focusIndex = -1;
            return;
        }
        _focusIndex = (index + placements.length) % placements.length;
    }

    function focusNext(delta) {
        if (placements.length === 0)
            return;
        setFocusIndex((focusIndex < 0 ? 0 : focusIndex) + delta);
    }

    function centerOf(p) {
        return {
            x: p.x + p.width / 2,
            y: p.y + p.height / 2
        };
    }

    function directionScore(current, candidate, direction) {
        const a = centerOf(current);
        const b = centerOf(candidate);
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        let primary = 0;
        let secondary = 0;

        // Spatial focus search rejects cards outside the requested half-plane,
        // then ranks by primary distance first and cross-axis drift second.
        if (direction === "left") {
            if (dx >= 0)
                return -1;
            primary = -dx;
            secondary = Math.abs(dy);
        } else if (direction === "right") {
            if (dx <= 0)
                return -1;
            primary = dx;
            secondary = Math.abs(dy);
        } else if (direction === "up") {
            if (dy >= 0)
                return -1;
            primary = -dy;
            secondary = Math.abs(dx);
        } else if (direction === "down") {
            if (dy <= 0)
                return -1;
            primary = dy;
            secondary = Math.abs(dx);
        }

        return primary * 10000 + secondary;
    }

    function moveFocus(direction) {
        if (placements.length === 0)
            return;
        if (focusIndex < 0) {
            setFocusIndex(0);
            return;
        }

        const current = placements[focusIndex];
        let best = -1;
        let bestScore = Number.POSITIVE_INFINITY;
        for (let i = 0; i < placements.length; i++) {
            if (i === focusIndex)
                continue;
            const score = directionScore(current, placements[i], direction);
            if (score >= 0 && score < bestScore) {
                bestScore = score;
                best = i;
            }
        }
        if (best >= 0)
            setFocusIndex(best);
    }

    function activateFocused() {
        if (focusIndex < 0)
            return;
        const item = widgetRepeater.itemAt(focusIndex);
        if (item)
            item.activatePrimary();
    }

    function titleFor(widget) {
        const settings = widget.settings ?? {};
        const fallback = ({
                epigraph: "Observatory",
                meters: "Beyonder Vitals",
                weather: "Sky Omens",
                calendar: "Lunar Ledger"
            })[widget.widgetId] ?? widget.widgetId;
        return settings.cardTitle ?? settings.title ?? fallback;
    }

    function subtitleFor(widget) {
        const settings = widget.settings ?? {};
        return settings.cardSubtitle ?? "";
    }

    Repeater {
        id: widgetRepeater
        model: root.placements.length

        DashboardMount {
            grid: root
        }
    }

    component DashboardMount: Item {
        id: mount

        required property var grid
        required property int index
        readonly property var placement: grid.placements[index] ?? ({
                key: "missing:" + index,
                widget: ({
                        widgetId: "missing",
                        services: [],
                        settings: ({}),
                        glance: null
                    }),
                placementIndex: index,
                x: 0,
                y: 0,
                width: 1,
                height: 1
            })

        readonly property var descriptor: placement.widget
        readonly property var requestedServices: descriptor.services ?? []
        readonly property var resolvedServices: grid.serviceResolver ? grid.serviceResolver(requestedServices) : ({})
        readonly property var missingServices: requestedServices.filter(name => resolvedServices[name] === null || resolvedServices[name] === undefined)
        readonly property bool hasMissingServices: missingServices.length > 0
        readonly property bool loadAllowed: (!descriptor.unloadWhenClosed || grid.surfaceActive || grid.surfaceMapped) && !hasMissingServices
        readonly property bool loaderError: content.status === Loader.Error
        readonly property bool loaderBusy: loadAllowed && !content.item && (content.status === Loader.Loading || content.status === Loader.Null)
        readonly property bool loaderEmpty: descriptor.glance === null || descriptor.glance === undefined
        readonly property real contentWidth: Math.max(1, card.width - card._pad * 2)
        readonly property real widgetHeight: content.item ? Math.max(content.item.implicitHeight, content.item.height, content.implicitHeight) : 0
        readonly property real reportedHeight: card.implicitHeight
        readonly property var injectedSettings: {
            const base = descriptor.settings ?? {};
            const out = {};
            for (const key in base)
                out[key] = base[key];
            out.surfaceActive = grid.surfaceActive;
            return out;
        }

        x: placement.x
        y: placement.y
        width: placement.width
        height: reportedHeight
        opacity: revealProgress

        property real revealProgress: 1
        property bool retryPulse: true

        Behavior on x { NumberAnimation { duration: grid.reducedMotion ? 0 : Motion.stateChange.duration; easing.type: grid.reducedMotion ? Easing.Linear : Motion.stateChange.easing } }
        Behavior on y { NumberAnimation { duration: grid.reducedMotion ? 0 : Motion.stateChange.duration; easing.type: grid.reducedMotion ? Easing.Linear : Motion.stateChange.easing } }
        Behavior on revealProgress { NumberAnimation { duration: grid.reducedMotion ? 0 : Motion.surfaceReveal.duration; easing.type: grid.reducedMotion ? Easing.Linear : Motion.surfaceReveal.easing } }

        onReportedHeightChanged: grid.setMeasuredHeight(placement.key, reportedHeight)
        onWidgetHeightChanged: Qt.callLater(() => grid.setMeasuredHeight(placement.key, reportedHeight))
        Component.onCompleted: {
            grid.setMeasuredHeight(placement.key, reportedHeight);
            if (grid.surfaceActive)
                startEntrance();
        }
        onPlacementChanged: grid.setMeasuredHeight(placement.key, reportedHeight)
        onLoadAllowedChanged: Qt.callLater(() => grid.setMeasuredHeight(placement.key, reportedHeight))

        Connections {
            target: grid
            function onSurfaceActiveChanged() {
                mount.injectContent(content.item);
                if (grid.surfaceActive)
                    mount.startEntrance();
                else {
                    entranceTimer.stop();
                    mount.revealProgress = 1;
                }
            }
        }

        function assignIfPossible(item, propertyName, value) {
            if (!item)
                return;
            try {
                item[propertyName] = value;
            } catch (error) {
                if (propertyName !== "theme" && propertyName !== "motion" && propertyName !== "surfaceActive")
                    console.warn("DashboardGrid: failed to inject", propertyName, "into", descriptor.widgetId, "-", error);
            }
        }

        function injectContent(item) {
            assignIfPossible(item, "services", resolvedServices);
            assignIfPossible(item, "settings", injectedSettings);
            assignIfPossible(item, "theme", Theme);
            assignIfPossible(item, "motion", Motion);
            assignIfPossible(item, "surfaceActive", grid.surfaceActive);
        }

        function startEntrance() {
            if (grid.reducedMotion) {
                revealProgress = 1;
                return;
            }
            revealProgress = 0;
            entranceTimer.interval = Math.min(360, placement.placementIndex * 38);
            entranceTimer.restart();
        }

        function retry() {
            retryPulse = false;
            Qt.callLater(() => retryPulse = true);
        }

        function activatePrimary() {
            if (content.item && content.item.primaryAction) {
                content.item.primaryAction();
                return;
            }
            if (descriptor.primaryAction)
                descriptor.primaryAction();
        }

        Timer {
            id: entranceTimer
            repeat: false
            onTriggered: mount.revealProgress = 1
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                grid.setFocusIndex(placement.placementIndex);
                mount.activatePrimary();
            }
        }

        DashboardCard {
            id: card

            width: parent.width
            transform: Translate {
                y: grid.surfaceActive ? (1 - mount.revealProgress) * 12 : 0
            }
            title: grid.titleFor(descriptor)
            subtitle: grid.subtitleFor(descriptor)
            busy: mount.loaderBusy
            empty: mount.loaderEmpty
            error: mount.hasMissingServices || mount.loaderError
            errorText: mount.hasMissingServices ? "The mirror is clouded: missing " + mount.missingServices.join(", ") : "The mirror is clouded."
            retryAction: mount.loaderError ? mount.retry : null
            focusRing: grid.focusIndex === placement.placementIndex

            Loader {
                id: content

                width: parent ? parent.width : mount.contentWidth
                active: mount.retryPulse && mount.loadAllowed && !mount.loaderEmpty
                asynchronous: true
                sourceComponent: descriptor.glance

                onLoaded: {
                    mount.injectContent(item);
                    Qt.callLater(() => grid.setMeasuredHeight(placement.key, mount.reportedHeight));
                }
                onStatusChanged: Qt.callLater(() => grid.setMeasuredHeight(placement.key, mount.reportedHeight))

                Binding {
                    target: content.item
                    property: "width"
                    value: mount.contentWidth
                    when: content.item !== null
                }
            }
        }
    }
}
