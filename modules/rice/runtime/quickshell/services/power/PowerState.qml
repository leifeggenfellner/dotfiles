pragma Singleton
import QtQuick
import Quickshell.Services.UPower

// ── PowerState — REAL ─────────────────────────────────────────
// Native UPower binding (D-008 tier 1): no sysfs polling, no
// powerprofilesctl. Power-profile control can join later if a
// widget needs it.
//
//   state: available, mock, batteryPercent [0..1], charging,
//          onBattery

Item {
    id: power

    readonly property bool mock: false
    readonly property var device: UPower.displayDevice
    readonly property bool available: device !== null && (device.isLaptopBattery ?? false)

    // UPower reports 0..1 here; guard in case a backend reports 0..100.
    readonly property real batteryPercent: {
        if (!available)
            return 0;
        const p = device.percentage;
        return p > 1 ? p / 100 : p;
    }

    readonly property bool onBattery: UPower.onBattery
    readonly property bool charging: available && !UPower.onBattery
}
