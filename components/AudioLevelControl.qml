pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

RowLayout {
    id: root
    required property int level
    required property bool muted
    property bool microphone: false
    property int maximum: microphone ? 100 : 150
    signal volumeRequested(real value)
    signal muteRequested
    spacing: 8

    AudioSlider {
        id: slider
        Layout.fillWidth: true
        level: root.level
        muted: root.muted
        maximum: root.maximum
        Accessible.name: root.microphone ? "Microphone volume" : "Output volume"
        onVolumeRequested: value => root.volumeRequested(value)
    }

    Text {
        Layout.preferredWidth: 42
        text: root.enabled ? Math.round(slider.value) + "%" : "—"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
    }

    Button {
        id: muteButton
        Layout.preferredWidth: 34
        Layout.preferredHeight: 32
        hoverEnabled: true
        Accessible.name: (root.muted ? "Unmute " : "Mute ") + (root.microphone ? "microphone" : "output")
        onClicked: root.muteRequested()
        ToolTip.visible: hovered
        ToolTip.delay: 500
        ToolTip.text: Accessible.name
        HoverHandler {
            enabled: muteButton.enabled
            cursorShape: Qt.PointingHandCursor
        }
        contentItem: Text {
            text: root.microphone ? (root.muted ? "󰍭" : "󰍬") : (root.muted ? "󰖁" : "󰕾")
            font.family: Theme.fontFamily
            font.pixelSize: 21
            color: root.muted ? Theme.bg : (root.enabled ? Theme.text : Theme.muted)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 7
            color: root.muted ? Theme.iris : (muteButton.hovered ? Theme.highlightMed : Theme.surface)
            border.color: muteButton.activeFocus ? Theme.text : (root.muted ? Theme.iris : Theme.highlightMed)
        }
    }
}
