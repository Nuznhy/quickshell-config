pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

UI.ColumnLayout {
    id: root
    property bool active: false
    property bool busy: false
    property string errorMessage: ""
    property string confirmation: ""
    signal actionRequested(string action)
    spacing: Design.space12
    onActiveChanged: confirmation = ""
    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space8
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
                accentColor: modelData.action === "shutdown" ? Design.danger : Design.accent
                Accessible.name: modelData.label
                contentItem: UI.Text {
                    text: button.modelData.icon
                    color: button.accent ? button.foreground : button.modelData.action === "shutdown" ? Design.danger : Design.text
                    font.family: Design.fontFamily
                    role: "page"
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
    UI.RowLayout {
        visible: root.confirmation.length > 0
        Layout.fillWidth: true
        NotificationButton { text: "Cancel"; Layout.fillWidth: true; enabled: !root.busy; onClicked: root.confirmation = "" }
        NotificationButton {
            text: root.confirmation === "reboot" ? "Reboot" : "Shut down"
            Layout.fillWidth: true
            enabled: !root.busy
            accent: true
            accentColor: root.confirmation === "shutdown" ? Design.danger : Design.accent
            onClicked: root.actionRequested(root.confirmation)
        }
    }
    UI.Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.errorMessage
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Design.danger
        font.family: Design.fontFamily
        role: "label"
    }
}
