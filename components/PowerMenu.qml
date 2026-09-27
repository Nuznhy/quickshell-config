pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root
    property bool active: false
    property bool busy: false
    property string errorMessage: ""
    property string confirmation: ""
    signal actionRequested(string action)
    spacing: 12
    onActiveChanged: confirmation = ""
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: [
                {action: "lock", label: "Lock", icon: "󰌾"},
                {action: "sleep", label: "Sleep", icon: "󰒲"},
                {action: "reboot", label: "Reboot", icon: "󰜉"},
                {action: "shutdown", label: "Shut down", icon: "󰐥"}
            ]
            NotificationButton {
                id: button
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 44
                enabled: !root.busy
                accent: root.confirmation === modelData.action
                accentColor: modelData.action === "shutdown" ? Theme.love : Theme.iris
                Accessible.name: modelData.label
                contentItem: Text {
                    text: button.modelData.icon
                    color: button.accent ? Theme.bg : button.modelData.action === "shutdown" ? Theme.love : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (modelData.action === "reboot" || modelData.action === "shutdown") root.confirmation = modelData.action;
                    else root.actionRequested(modelData.action);
                }
            }
        }
    }
    RowLayout {
        visible: root.confirmation.length > 0
        Layout.fillWidth: true
        NotificationButton { text: "Cancel"; Layout.fillWidth: true; enabled: !root.busy; onClicked: root.confirmation = "" }
        NotificationButton {
            text: root.confirmation === "reboot" ? "Reboot" : "Shut down"
            Layout.fillWidth: true
            enabled: !root.busy
            accent: true
            accentColor: root.confirmation === "shutdown" ? Theme.love : Theme.iris
            onClicked: root.actionRequested(root.confirmation)
        }
    }
    Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.errorMessage
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Theme.love
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
}
