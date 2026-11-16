import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/weather"
import "../../utils"

// ── SkyController ────────────────────────────────────────────
// Sky conditions (D-046): the one place the runtime decides which of
// "fullMoon" | "rain" | "fog" hold, pushed onto
// ShellState.skyConditions for core/Effects presets and surface copy.
//
//   fullMoon  the local lunar calculation is within `window` days of
//             full (the largest window any fullMoon preset declares,
//             default 1.5); needs no network
//   rain/fog  WeatherState's kind — read only when a preset keys on
//             weather, so themes without one never start the probe;
//             no weather (offline, no curl) simply means neither
//
// Overrides for smoke tests (not persisted):
//   quickshell -c rice ipc call sky setMoon auto|full|none
//   quickshell -c rice ipc call sky setWeather auto|clear|rain|fog|snow
//   quickshell -c rice ipc call sky status

Item {
    id: sky

    property date now: new Date()
    property string moonOverride: "auto"
    property string weatherOverride: "auto"

    readonly property real fullMoonWindow: {
        let w = 0;
        for (const p of Effects.presets)
            if (p.when === "fullMoon")
                w = Math.max(w, typeof p.window === "number" ? p.window : 1.5);
        return w > 0 ? w : 1.5;
    }
    readonly property bool needsWeather: Effects.presets.some(p => p.when === "rain" || p.when === "fog")

    readonly property var moon: Moon.phase(sky.now)
    readonly property real daysFromFull: Math.abs(sky.moon.age - Moon.cycleDays / 2)
    readonly property bool fullMoon: sky.moonOverride === "full" || (sky.moonOverride === "auto" && sky.daysFromFull <= sky.fullMoonWindow)
    readonly property string weather: sky.weatherOverride !== "auto" ? sky.weatherOverride : (sky.needsWeather ? WeatherState.kind : "")

    readonly property var conditions: {
        const out = [];
        if (sky.fullMoon)
            out.push("fullMoon");
        if (sky.weather === "rain" || sky.weather === "fog")
            out.push(sky.weather);
        return out;
    }

    Binding {
        target: ShellState
        property: "skyConditions"
        value: sky.conditions
    }

    // The moon moves slowly; an hourly tick is plenty.
    Timer {
        interval: 3600000
        repeat: true
        running: true
        onTriggered: sky.now = new Date()
    }

    IpcHandler {
        target: "sky"

        function status(): string {
            return JSON.stringify({
                conditions: ShellState.skyConditions,
                moon: sky.moon.name,
                illumination: Math.round(sky.moon.illumination * 100) / 100,
                daysFromFull: Math.round(sky.daysFromFull * 10) / 10,
                fullMoonWindow: sky.fullMoonWindow,
                weather: sky.weather,
                needsWeather: sky.needsWeather,
                moonOverride: sky.moonOverride,
                weatherOverride: sky.weatherOverride,
                activePresets: Effects.activePresets.length
            });
        }
        function setMoon(v: string): void {
            sky.moonOverride = ["full", "none"].includes(v) ? v : "auto";
        }
        function setWeather(v: string): void {
            sky.weatherOverride = ["clear", "rain", "fog", "snow"].includes(v) ? v : "auto";
        }
    }
}
