pragma Singleton
import QtQuick
import Quickshell
import "../../core"

QtObject {
    id: config

    property string backgroundMode: _env("RICE_LOCK_MODE", "image")
    property string videoPath: _url(_env("RICE_LOCK_VIDEO", ""))
    property string imagePath: _url(_env("RICE_LOCK_IMAGE", ""))
    property int blurStrength: _intEnv("RICE_LOCK_BLUR", 18)
    property int particleCount: _intEnv("RICE_LOCK_PARTICLES", 96)
    property real particleOpacity: _realEnv("RICE_LOCK_PARTICLE_OPACITY", 0.54)
    property real fogOpacity: _realEnv("RICE_LOCK_FOG_OPACITY", 0.28)
    property bool enableParallax: _boolEnv("RICE_LOCK_PARALLAX", true)
    property bool enableShaders: _boolEnv("RICE_LOCK_SHADERS", true)
    property bool enableBloom: _boolEnv("RICE_LOCK_BLOOM", true)
    property int fpsLimit: Math.max(24, Math.min(120, _intEnv("RICE_LOCK_FPS", 60)))
    property color accentColor: _colorEnv("RICE_LOCK_ACCENT", Theme.colors.accent.secondary)
    property string font: _env("RICE_LOCK_FONT", Theme.typography.families.display)
    property string clockFormat: _env("RICE_LOCK_CLOCK_FORMAT", "HH:mm")
    property string pamService: _env("RICE_LOCK_PAM_SERVICE", "login")

    function _env(name, fallback) {
        const value = Quickshell.env(name);
        return value && String(value).length > 0 ? String(value) : fallback;
    }

    function _url(value) {
        if (!value || value.length === 0)
            return "";
        if (value.startsWith("file://"))
            return value;
        return value.startsWith("/") ? "file://" + value : value;
    }

    function _intEnv(name, fallback) {
        const parsed = parseInt(_env(name, ""), 10);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function _realEnv(name, fallback) {
        const parsed = parseFloat(_env(name, ""));
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function _boolEnv(name, fallback) {
        const value = _env(name, "").toLowerCase();
        if (["1", "true", "yes", "on"].indexOf(value) >= 0)
            return true;
        if (["0", "false", "no", "off"].indexOf(value) >= 0)
            return false;
        return fallback;
    }

    function _colorEnv(name, fallback) {
        const value = _env(name, "");
        return value.length > 0 ? value : fallback;
    }
}
