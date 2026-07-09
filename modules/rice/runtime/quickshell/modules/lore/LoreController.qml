import Quickshell
import Quickshell.Io
import QtQuick
import "../../core"

// ── LoreController ──────────────────────────────────────────
// Experimental world events (D-030). All hooks default off and are
// enabled only by theme settings under widgets.worldEvents.settings.

Item {
    id: lore

    readonly property var settings: Theme.widgetConfig("worldEvents").settings ?? ({})
    readonly property var launcherSettings: Theme.widgetConfig("launcher").settings ?? ({})
    readonly property var calendarSettings: Theme.widgetConfig("calendar").settings ?? ({})
    readonly property var incantations: (launcherSettings.incantations ?? ({}))
    readonly property var calendarSecret: calendarSettings.secret ?? ({})
    readonly property var hourBell: settings.hourBell ?? ({})
    readonly property var dailyFogSurge: settings.dailyFogSurge ?? ({})

    property string _lastHourKey: ""
    property string _lastDailySurgeKey: ""

    Component.onCompleted: _lastHourKey = hourKey(clock.date)

    function isEnabled(block) {
        return block.enabled === true;
    }

    function numberSetting(block, key, fallback) {
        const value = block[key];
        return typeof value === "number" ? value : fallback;
    }

    function hourKey(date) {
        return Qt.formatDateTime(date, "yyyy-MM-dd-HH");
    }

    function dayKey(date) {
        return Qt.formatDate(date, "yyyy-MM-dd");
    }

    function triggerBlock(block, kind, fallbackText, fallbackSurge) {
        Sound.play(block.sound ?? "");
        ShellState.triggerFlavorEvent(block.text ?? fallbackText, block.event ?? kind, block.surge ?? fallbackSurge);
    }

    function tick(date) {
        const currentHourKey = hourKey(date);
        if (currentHourKey !== _lastHourKey) {
            _lastHourKey = currentHourKey;
            if (isEnabled(hourBell))
                triggerBlock(hourBell, "hourBell", "The hour turns.", false);
        }

        if (!isEnabled(dailyFogSurge))
            return;

        const targetHour = numberSetting(dailyFogSurge, "hour", 6);
        const targetMinute = numberSetting(dailyFogSurge, "minute", 0);
        const currentDayKey = dayKey(date);
        if (date.getHours() === targetHour && date.getMinutes() === targetMinute && _lastDailySurgeKey !== currentDayKey) {
            _lastDailySurgeKey = currentDayKey;
            triggerBlock(dailyFogSurge, "dailyFogSurge", "The fog stirs for the day.", true);
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: lore.tick(date)
    }

    IpcHandler {
        target: "lore"

        function status(): string {
            return JSON.stringify({
                hourBell: lore.isEnabled(lore.hourBell),
                dailyFogSurge: lore.isEnabled(lore.dailyFogSurge),
                incantations: lore.isEnabled(lore.incantations),
                calendarSecret: lore.isEnabled(lore.calendarSecret),
                lastHour: lore._lastHourKey,
                lastDailySurge: lore._lastDailySurgeKey,
                flavorEventSerial: ShellState.flavorEventSerial,
                fogSurgeSerial: ShellState.fogSurgeSerial
            });
        }

        function trigger(eventName: string): void {
            if (eventName === "hourBell")
                lore.triggerBlock(lore.hourBell, "hourBell", "The hour turns.", false);
            else if (eventName === "dailyFogSurge")
                lore.triggerBlock(lore.dailyFogSurge, "dailyFogSurge", "The fog stirs for the day.", true);
            else if (eventName === "calendarSecret")
                lore.triggerBlock(lore.calendarSecret, "calendarSecret", "The calendar has another page.", true);
            else if (eventName === "fogSurge")
                ShellState.triggerFogSurge();
        }
    }
}
