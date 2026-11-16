pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../utils"

// ── WeatherState — REAL/FALLBACK ─────────────────────────────
// Weather and calendar-adjacent sky state for dashboard widgets.
// Current conditions refresh on demand and hourly when curl/network
// are available; lunar data is local and always valid.
//
// Source: a pinned location (rice.weather.location, exported by the
// rice-shell launcher as RICE_WEATHER_{NAME,LAT,LON}) uses MET Norway's
// locationforecast for that point; otherwise wttr.in guesses from the
// IP address. MET has no feels-like value, so it is a wind chill.

Item {
    id: weather

    readonly property bool mock: false
    property bool available: false
    property bool busy: false
    property string error: ""

    property date now: new Date()
    property string location: ""
    property string condition: ""
    property real temperatureC: -999
    property real feelsLikeC: -999
    property int humidity: -1
    property real windKph: -1
    // Coarse sky kind from wttr.in's WWO weather code: "rain" (incl.
    // drizzle, showers, thunder), "fog" (mist, fog), "snow" (incl.
    // sleet), "clear" otherwise; "" while unavailable.
    property string kind: ""

    readonly property string pinnedName: Quickshell.env("RICE_WEATHER_NAME") ?? ""
    readonly property real pinnedLat: _envNumber("RICE_WEATHER_LAT")
    readonly property real pinnedLon: _envNumber("RICE_WEATHER_LON")
    readonly property bool pinned: Number.isFinite(pinnedLat) && Number.isFinite(pinnedLon)

    function _envNumber(name) {
        const v = Quickshell.env(name);
        return typeof v === "string" && v.length > 0 ? Number(v) : NaN;
    }

    readonly property var moonPhase: Moon.phase(now)
    readonly property string moonName: moonPhase.name
    readonly property real moonIllumination: moonPhase.illumination
    readonly property string moonIcon: moonPhase.icon

    function refresh() {
        now = new Date();
        if (probe.running)
            return;
        busy = true;
        error = "";
        probe.running = true;
    }

    function _num(value, fallback) {
        const n = Number(value);
        return Number.isFinite(n) ? n : fallback;
    }

    function _kind(code) {
        if ([143, 248, 260].includes(code))
            return "fog";
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377, 392, 395].includes(code))
            return "snow";
        if ([176, 200, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359, 386, 389].includes(code))
            return "rain";
        return "clear";
    }

    // MET symbol_code ("lightrainshowers_day") → coarse kind, same
    // buckets as _kind (sleet counts as snow, thunder as rain).
    function _metKind(symbol) {
        if (symbol.startsWith("fog"))
            return "fog";
        if (symbol.includes("snow") || symbol.includes("sleet"))
            return "snow";
        if (symbol.includes("rain") || symbol.includes("thunder"))
            return "rain";
        return "clear";
    }

    function _metCondition(symbol) {
        const names = {
            clearsky: "Clear sky",
            fair: "Fair",
            partlycloudy: "Partly cloudy",
            cloudy: "Cloudy",
            fog: "Fog"
        };
        if (names[symbol])
            return names[symbol];
        // MET's legend spells some codes "lightssleet…".
        const words = symbol.replace("ssleet", "sleet").replace("andthunder", " and thunder").replace(/^(light|heavy)/, "$1 ").replace(/(rain|sleet|snow)showers/, "$1 showers");
        return words.charAt(0).toUpperCase() + words.slice(1);
    }

    // Environment Canada wind chill; plain temperature where it does
    // not apply (above 10 °C or under 4.8 km/h).
    function _feelsLike(t, kph) {
        if (t > 10 || kph < 4.8)
            return t;
        const v = Math.pow(kph, 0.16);
        return 13.12 + 0.6215 * t - 11.37 * v + 0.3965 * t * v;
    }

    function _parseMet(text) {
        const series = JSON.parse(text).properties?.timeseries ?? [];
        if (series.length === 0)
            throw new Error("missing timeseries");
        const data = series[0].data;
        const now = data.instant.details;
        const symbol = String((data.next_1_hours ?? data.next_6_hours ?? {}).summary?.symbol_code ?? "cloudy").replace(/_(day|night|polartwilight)$/, "");
        location = pinnedName;
        condition = _metCondition(symbol);
        temperatureC = _num(now.air_temperature, -999);
        windKph = _num(now.wind_speed, -1) * 3.6;
        feelsLikeC = temperatureC > -999 && windKph >= 0 ? _feelsLike(temperatureC, windKph) : temperatureC;
        humidity = Math.round(_num(now.relative_humidity, -1));
        kind = _metKind(symbol);
        available = true;
    }

    function _parse(text) {
        if (pinned)
            return _parseMet(text);
        const doc = JSON.parse(text);
        const current = doc.current_condition && doc.current_condition.length > 0 ? doc.current_condition[0] : null;
        if (!current)
            throw new Error("missing current condition");
        const area = doc.nearest_area && doc.nearest_area.length > 0 ? doc.nearest_area[0] : null;
        const names = area && area.areaName && area.areaName.length > 0 ? area.areaName[0].value : "";
        const country = area && area.country && area.country.length > 0 ? area.country[0].value : "";
        location = names && country ? names + ", " + country : names;
        condition = current.weatherDesc && current.weatherDesc.length > 0 ? current.weatherDesc[0].value : "";
        temperatureC = _num(current.temp_C, -999);
        feelsLikeC = _num(current.FeelsLikeC, -999);
        humidity = Math.round(_num(current.humidity, -1));
        windKph = _num(current.windspeedKmph, -1);
        kind = _kind(Math.round(_num(current.weatherCode, 113)));
        available = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 3600000
        repeat: true
        running: true
        onTriggered: weather.refresh()
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: weather.now = new Date()
    }

    Process {
        id: probe
        // MET's terms require an identifying User-Agent.
        command: weather.pinned
            ? ["sh", "-c", "command -v curl >/dev/null 2>&1 || exit 127; curl -fsS --max-time 6 -A 'rice-dotfiles/1.0 github.com/leifeggenfellner/dotfiles' \"$1\"", "sh",
                "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=" + weather.pinnedLat.toFixed(4) + "&lon=" + weather.pinnedLon.toFixed(4)]
            : ["sh", "-c", "command -v curl >/dev/null 2>&1 || exit 127; curl -fsS --max-time 4 'https://wttr.in/?format=j1'"]
        stdout: StdioCollector {
            id: stdout
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: stderr
            waitForEnd: true
        }
        onExited: (code, status) => {
            weather.busy = false;
            weather.now = new Date();
            if (code !== 0) {
                weather.available = false;
                weather.kind = "";
                weather.error = code === 127 ? "curl is not installed" : (stderr.text.trim() || "weather refresh failed (exit " + code + ")");
                return;
            }
            try {
                weather._parse(stdout.text);
                weather.error = "";
            } catch (e) {
                weather.available = false;
                weather.kind = "";
                weather.error = "weather parse failed";
                console.warn("WeatherState:", e);
            }
        }
    }
}
