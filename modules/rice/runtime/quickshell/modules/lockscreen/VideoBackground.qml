import QtQuick
import QtMultimedia
import "../../core"

Item {
    id: root

    property real time: 0
    property real parallaxX: 0
    property real parallaxY: 0
    property bool running: true

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
    }

    MediaPlayer {
        id: player

        source: Config.videoPath
        videoOutput: output
        audioOutput: AudioOutput {
            muted: true
        }
        loops: MediaPlayer.Infinite
        autoPlay: root.running && Config.videoPath.length > 0

        onPlaybackStateChanged: {
            if (root.running && Config.videoPath.length > 0 && playbackState !== MediaPlayer.PlayingState)
                play();
        }
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        anchors.margins: -Math.max(Math.abs(root.parallaxX), Math.abs(root.parallaxY)) - 28
        fillMode: VideoOutput.PreserveAspectCrop
        opacity: player.mediaStatus === MediaPlayer.NoMedia ? 0 : 1
        x: -root.parallaxX * 0.28
        y: -root.parallaxY * 0.22
        scale: 1.035

        Behavior on opacity {
            NumberAnimation {
                duration: 900
                easing.type: Easing.OutCubic
            }
        }
    }

    ImageBackground {
        anchors.fill: parent
        visible: output.opacity < 0.98
        opacity: 1 - output.opacity
        time: root.time
        parallaxX: root.parallaxX
        parallaxY: root.parallaxY
        running: root.running
    }

    Connections {
        target: root
        function onRunningChanged() {
            if (root.running)
                player.play();
            else
                player.pause();
        }
    }
}
