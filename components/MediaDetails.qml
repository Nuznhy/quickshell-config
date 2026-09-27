import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root
    property var player: null
    property bool active: false
    property int clockTick: 0
    onActiveChanged: { if (!active) timeline.cancelSeek(); }
    readonly property real position: { clockTick; return player?.positionSupported ? Math.max(0, player.position) : 0; }
    readonly property real duration: player?.lengthSupported ? Math.max(0, player.length) : 0
    spacing: 12
    function timeLabel(seconds) {
        const total = Math.floor(seconds);
        return Math.floor(total / 60) + ":" + String(total % 60).padStart(2, "0");
    }
    Timer {
        interval: 1000
        running: root.active && (root.player?.isPlaying ?? false)
        repeat: true
        onTriggered: root.clockTick++
    }
    component Label: Text {
        Layout.fillWidth: true
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
    }
    component TransportButton: NotificationButton {
        id: control
        property string actionName
        Layout.fillWidth: true
        implicitHeight: 36
        Accessible.name: actionName
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: actionName
        contentItem: Text {
            text: control.text
            color: control.accent ? Theme.bg : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 22
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Label {
        text: root.player?.identity || "Media"
        color: Theme.subtle
        font.pixelSize: 10
    }
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 160
        Layout.preferredHeight: 160
        radius: 12
        color: Theme.surface
        Image {
            id: cover
            anchors.fill: parent
            source: root.player?.trackArtUrl || ""
            sourceSize.width: 320
            sourceSize.height: 320
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
        }
        Text {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: "󰎆"
            color: Theme.iris
            font.family: Theme.fontFamily
            font.pixelSize: 60
        }
    }
    Label { text: root.player?.trackArtist || "Unknown artist"; color: Theme.subtle }
    Label { text: root.player?.trackTitle || "Unknown title"; font.pixelSize: 15; font.bold: true }
    Label { text: root.player?.trackAlbum || ""; visible: text.length > 0; color: Theme.muted; font.pixelSize: 10 }
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.duration > 0 && (root.player?.positionSupported ?? false)
        spacing: 5
        MediaSeekSlider {
            id: timeline
            Layout.fillWidth: true
            mediaPosition: root.position
            duration: root.duration
            trackKey: (root.player?.dbusName || "") + ":" + (root.player?.uniqueId ?? "")
            enabled: (root.player?.canSeek ?? false) && root.duration > 0
            onSeekRequested: seconds => {
                if (root.player?.canSeek && root.player.positionSupported) root.player.position = seconds;
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: root.timeLabel(timeline.pressed ? timeline.value : root.position); horizontalAlignment: Text.AlignLeft; font.pixelSize: 10; color: Theme.subtle }
            Label { text: root.timeLabel(root.duration); horizontalAlignment: Text.AlignRight; font.pixelSize: 10; color: Theme.subtle }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        TransportButton {
            text: "󰒮"
            actionName: "Previous track"
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }
        TransportButton {
            text: root.player?.isPlaying ? "󰏤" : "󰐊"
            actionName: root.player?.isPlaying ? "Pause" : "Play"
            accent: true
            enabled: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }
        TransportButton {
            text: "󰒭"
            actionName: "Next track"
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }
}
