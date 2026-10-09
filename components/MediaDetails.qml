import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

UI.ColumnLayout {
    id: root
    property var player: null
    property bool active: false
    property int clockTick: 0
    onActiveChanged: { if (!active) timeline.cancelSeek(); }
    readonly property real position: { clockTick; return player?.positionSupported ? Math.max(0, player.position) : 0; }
    readonly property real duration: player?.lengthSupported ? Math.max(0, player.length) : 0
    spacing: Design.space12
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
    component Label: UI.Text {
        Layout.fillWidth: true
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
    }
    component TransportButton: NotificationButton {
        font.family: Design.iconFontFamily
        font.pixelSize: Design.iconLarge
        id: control
        property string actionName
        Layout.fillWidth: true
        implicitHeight: Design.controlHeight
        Accessible.name: actionName

    }
    Label {
        text: root.player?.identity || "Media"
        color: Design.textSecondary
        role: "caption"
    }
    UI.Card {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 160
        Layout.preferredHeight: 160

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
        UI.Text {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: "󰎆"
            color: Design.accent
            font.family: Design.fontFamily
            font.pixelSize: Design.artworkPlaceholderSize
        }
    }
    Label { text: root.player?.trackArtist || "Unknown artist"; color: Design.textSecondary }
    Label { text: root.player?.trackTitle || "Unknown title"; role: "section"; font.bold: true }
    Label { text: root.player?.trackAlbum || ""; visible: text.length > 0; color: Design.textMuted; role: "caption" }
    UI.ColumnLayout {
        Layout.fillWidth: true
        visible: root.duration > 0 && (root.player?.positionSupported ?? false)
        spacing: Design.space4
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
        UI.RowLayout {
            Layout.fillWidth: true
            Label { text: root.timeLabel(timeline.pressed ? timeline.value : root.position); horizontalAlignment: Text.AlignLeft; role: "caption"; color: Design.textSecondary }
            Label { text: root.timeLabel(root.duration); horizontalAlignment: Text.AlignRight; role: "caption"; color: Design.textSecondary }
        }
    }
    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space8
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
