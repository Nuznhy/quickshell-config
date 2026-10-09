pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

UI.RowLayout {
    id: root
    required property int level
    required property bool muted
    property bool microphone: false
    property int maximum: microphone ? 100 : 150
    signal volumeRequested(real value)
    signal muteRequested
    spacing: Design.space8

    AudioSlider {
        id: slider
        Layout.fillWidth: true
        level: root.level
        muted: root.muted
        maximum: root.maximum
        Accessible.name: root.microphone ? "Microphone volume" : "Output volume"
        onVolumeRequested: value => root.volumeRequested(value)
    }

    UI.Text {
        Layout.preferredWidth: 42
        text: root.enabled ? Math.round(slider.value) + "%" : "—"
        color: Design.textSecondary
        font.family: Design.fontFamily
        role: "body"
        horizontalAlignment: Text.AlignRight
    }

    UI.Button {
        highlighted: root.muted
        id: muteButton
        Layout.preferredWidth: 34
        Layout.preferredHeight: 32
        Accessible.name: (root.muted ? "Unmute " : "Mute ") + (root.microphone ? "microphone" : "output")
        onClicked: root.muteRequested()

        contentItem: UI.Text {
            text: root.microphone ? (root.muted ? "󰍭" : "󰍬") : (root.muted ? "󰖁" : "󰕾")
            font.family: Design.fontFamily
            font.pixelSize: Design.iconLarge
            color: root.muted ? Design.textOnAccent : (root.enabled ? Design.text : Design.textMuted)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

    }
}
