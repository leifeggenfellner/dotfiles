import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/audio"
import "../../services/brightness"

Item {
    id: controller

    readonly property real volumeStep: 0.05
    readonly property real brightnessStep: 0.10

    function show(kind) {
        ShellState.showOsd(kind);
        if (kind === "brightness")
            BrightnessState.refresh();
    }

    function volumeUp() {
        AudioState.setMuted(false);
        AudioState.setVolume(AudioState.volume + volumeStep);
        show("volume");
    }

    function volumeDown() {
        AudioState.setVolume(AudioState.volume - volumeStep);
        show("volume");
    }

    function toggleMute() {
        AudioState.toggleMuted();
        show("volume");
    }

    function brightnessUp() {
        BrightnessState.step(brightnessStep);
        show("brightness");
    }

    function brightnessDown() {
        BrightnessState.step(-brightnessStep);
        show("brightness");
    }

    IpcHandler {
        target: "osd"

        function status(): string {
            return JSON.stringify({
                visible: ShellState.osdVisible,
                kind: ShellState.osdKind,
                serial: ShellState.osdSerial,
                volume: AudioState.volume,
                muted: AudioState.muted,
                audioAvailable: AudioState.available,
                brightness: BrightnessState.value,
                brightnessAvailable: BrightnessState.available
            });
        }

        function show(kind: string): void {
            controller.show(kind);
        }
        function showVolume(): void {
            controller.show("volume");
        }
        function showBrightness(): void {
            controller.show("brightness");
        }
        function volumeUp(): void {
            controller.volumeUp();
        }
        function volumeDown(): void {
            controller.volumeDown();
        }
        function toggleMute(): void {
            controller.toggleMute();
        }
        function brightnessUp(): void {
            controller.brightnessUp();
        }
        function brightnessDown(): void {
            controller.brightnessDown();
        }
    }
}
