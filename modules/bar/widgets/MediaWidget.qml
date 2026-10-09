import QtQuick
import "../../../components/ui" as UI
import QtQuick.Controls
import Quickshell
import QtQuick.Layouts
import "../../../config"
import "../../../components"
import "../../../services"

DropdownWidget {
    id: root
    property var player: Media.player
    readonly property string title: player?.trackTitle || "Unknown title"
    readonly property string artist: player?.trackArtist || player?.identity || "Unknown artist"
    visible: player !== null
    barWindow: root.QsWindow.window
    Layout.minimumHeight: mediaContent.implicitHeight
    Layout.preferredHeight: mediaContent.implicitHeight
    popupWidth: 350
    sizeToContent: true
    showStem: false
    showHoverIndicator: false
    stemAlignment: "center"
    rightClickEnabled: true
    wheelEnabled: true
    onRightClicked: {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }
    property int wheelRemainder: 0
    onPlayerChanged: wheelRemainder = 0
    onVisibleChanged: {
        if (!visible)
            dropdownOpen = false;
    }
    onWheelScrolled: delta => {
        if (!player || delta === 0)
            return;
        if (wheelRemainder * delta < 0)
            wheelRemainder = 0;
        wheelRemainder += delta;
        if (Math.abs(wheelRemainder) < 120)
            return;
        if (wheelRemainder > 0 && player.canGoPrevious)
            player.previous();
        else if (wheelRemainder < 0 && player.canGoNext)
            player.next();
        wheelRemainder = 0;
    }
    popupContent: MediaDetails {
        player: root.player
        active: root.dropdownOpen
    }

    Item {
        id: mediaContent
        width: Theme.verticalBar ? Theme.sideBarWidth - 16 : 210
        implicitHeight: Theme.verticalBar ? cover.height + 4 + labels.implicitHeight + 4 : Settings.barHeight
        height: implicitHeight
        Rectangle {
            id: cover
            width: 32
            height: 32
            x: Theme.verticalBar ? (parent.width - width) / 2 : 0
            y: Theme.verticalBar ? 0 : (parent.height - height) / 2
            radius: Design.radiusControl
            color: Design.surface
            clip: true
            Image {
                id: artwork
                anchors.fill: parent
                source: root.player?.trackArtUrl || ""
                sourceSize.width: 64
                sourceSize.height: 64
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            UI.Text {
                role: "bar"
                anchors.centerIn: parent
                visible: artwork.status !== Image.Ready
                text: "󰎆"
                color: Design.accent
                font.family: Design.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.0)
            }
        }

        Column {
            id: labels
            x: Theme.verticalBar ? 0 : cover.width + 8
            y: Theme.verticalBar ? cover.height + 4 : (parent.height - implicitHeight) / 2
            width: parent.width - x
            spacing: Design.space2
            UI.Text {
                role: "bar"
                width: parent.width
                text: root.artist
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                horizontalAlignment: Theme.verticalBar ? Text.AlignHCenter : Text.AlignLeft
                color: Design.textSecondary
                font.family: Theme.barFontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.5)
            }
            UI.Text {
                role: "bar"
                width: parent.width
                text: root.title
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                horizontalAlignment: Theme.verticalBar ? Text.AlignHCenter : Text.AlignLeft
                color: Design.text
                font.family: Theme.barFontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.6)
                font.weight: Font.Medium
            }
        }
    }
}
