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
    property real compactBreakpoint: 1120
    property real sidebarRatio: 0.46
    property int sidebarMinWidth: 360
    property int sidebarMaxWidth: 560
    property int mainMinWidth: 440

    readonly property bool compact: width < compactBreakpoint
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
            column: hint.column ?? null,
            fullWidth: hint.fullWidth ?? epigraphLike,
            minHeight: hint.minHeight ?? (epigraphLike ? 112 : 180),
            priority: hint.priority ?? widget.priority ?? 0
        };
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

    function isFullWidth(entry) {
        return entry.layout.fullWidth === true || entry.layout.colSpan >= 12;
    }

    function preferredColumn(entry) {
        if (entry.layout.column === "main" || entry.layout.column === "sidebar")
            return entry.layout.column;
        const id = entry.widget.widgetId;
        if (id === "weather" || id === "calendar" || id === "session-lock" || id === "ritualLedger")
            return "sidebar";
        return "main";
    }

    function pushPlacement(out, entry, x, y, w, h, columnName) {
        out.push({
            key: descriptorKey(entry),
            widget: entry.widget,
            sourceIndex: entry.sourceIndex,
            placementIndex: out.length,
            column: columnName,
            colSpan: 1,
            x,
            y,
            width: w,
            height: h
        });

        return y + h;
    }

    function appendFlow(out, entries, x, startY, w, columnName) {
        let y = startY;
        for (let i = 0; i < entries.length; i++) {
            if (i > 0)
                y += gap;
            const entry = entries[i];
            y = pushPlacement(out, entry, x, y, w, measuredHeight(entry), columnName);
        }
        return y;
    }

    function sidebarWidthFor(totalWidth) {
        const maxSidebar = Math.min(sidebarMaxWidth, Math.max(sidebarMinWidth, totalWidth - gap - mainMinWidth));
        return Math.max(sidebarMinWidth, Math.min(maxSidebar, Math.round(totalWidth * sidebarRatio)));
    }

    function pack() {
        if (width <= 0) {
            _placements = [];
            _contentHeight = 0;
            return;
        }

        const out = [];
        const ordered = sortedEntries();

        if (compact) {
            _contentHeight = appendFlow(out, ordered, 0, 0, width, "single");
            _placements = out;
            if (_focusIndex < 0 && out.length > 0)
                _focusIndex = 0;
            return;
        }

        const fullWidth = ordered.filter(entry => isFullWidth(entry));
        const remaining = ordered.filter(entry => !isFullWidth(entry));
        const mainEntries = remaining.filter(entry => preferredColumn(entry) === "main");
        const sidebarEntries = remaining.filter(entry => preferredColumn(entry) === "sidebar");

        const headerBottom = appendFlow(out, fullWidth, 0, 0, width, "full");
        const contentTop = headerBottom > 0 && remaining.length > 0 ? headerBottom + gap : headerBottom;

        if (mainEntries.length === 0 || sidebarEntries.length === 0) {
            _contentHeight = appendFlow(out, remaining, 0, contentTop, width, "single");
            _placements = out;
            if (_focusIndex < 0 && out.length > 0)
                _focusIndex = 0;
            return;
        }

        const sidebarWidth = sidebarWidthFor(width);
        const mainWidth = width - gap - sidebarWidth;
        const sidebarX = mainWidth + gap;
        const mainBottom = appendFlow(out, mainEntries, 0, contentTop, mainWidth, "main");
        const sidebarBottom = appendFlow(out, sidebarEntries, sidebarX, contentTop, sidebarWidth, "sidebar");

        _placements = out;
        _contentHeight = Math.max(mainBottom, sidebarBottom);
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

        Behavior on x {
            NumberAnimation {
                duration: grid.reducedMotion ? 0 : Motion.stateChange.duration
                easing.type: grid.reducedMotion ? Easing.Linear : Motion.stateChange.easing
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: grid.reducedMotion ? 0 : Motion.stateChange.duration
                easing.type: grid.reducedMotion ? Easing.Linear : Motion.stateChange.easing
            }
        }
        Behavior on revealProgress {
            NumberAnimation {
                duration: grid.reducedMotion ? 0 : Motion.surfaceReveal.duration
                easing.type: grid.reducedMotion ? Easing.Linear : Motion.surfaceReveal.easing
            }
        }

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
