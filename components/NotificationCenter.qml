pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

FocusScope {
    id: root
    property bool active: false
    property int maximumHeight: 540
    implicitHeight: content.implicitHeight
    signal dismissed
    onActiveChanged: {
        Notifications.openPanels += active ? 1 : -1;
        if (active) {
            Notifications.markRead();
            Notifications.hidePopups();
            forceActiveFocus();
        }
    }
    Component.onDestruction: { if (active) Notifications.openPanels--; }
    Keys.onEscapePressed: dismissed()
    Connections {
        target: Notifications
        function onOpenRequested() { if (root.active) root.dismissed(); }
    }
    UI.ColumnLayout {
        id: content
        x: 0; y: 0
        width: parent.width
        spacing: Design.space12
        UI.RowLayout {
            Layout.fillWidth: true
            UI.Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Design.text
                font.family: Design.fontFamily
                role: "panel"
                font.bold: true
            }
            NotificationButton {
                text: "Clear all"
                enabled: Notifications.history.length > 0
                onClicked: Notifications.clearHistory()
            }
        }
        UI.Card {
            Layout.fillWidth: true
            implicitHeight: 46

            UI.RowLayout {
                anchors.fill: parent
                anchors.margins: Design.panelPadding
                UI.Text {
                    Layout.fillWidth: true
                    text: "Do Not Disturb"
                    color: Design.text
                    font.family: Design.fontFamily
                    role: "body"
                }
                ControlSwitch {
                    Accessible.name: "Do Not Disturb"
                    value: Notifications.doNotDisturb
                    onChangeRequested: value => Notifications.setDoNotDisturb(value)
                }
            }
        }
        UI.Text {
            Layout.fillWidth: true
            visible: Notifications.errorMessage.length > 0
            text: Notifications.errorMessage
            color: Design.danger
            font.family: Design.fontFamily
            role: "label"
            wrapMode: Text.Wrap
        }
        UI.Text {
            text: "RECENT  ·  " + Notifications.history.length
            color: Design.textMuted
            font.family: Design.fontFamily
            role: "caption"
            font.letterSpacing: 1
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 140
            visible: Notifications.history.length === 0
            Column {
                anchors.centerIn: parent
                spacing: Design.space8
                UI.Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂚"
                    color: Design.accent
                    font.family: Design.fontFamily
                    font.pixelSize: Design.iconDisplay
                }
                UI.Text {
                    text: "You're all caught up"
                    color: Design.textSecondary
                    font.family: Design.fontFamily
                    role: "body"
                }
            }
        }
        UI.ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(cards.implicitHeight, Math.max(120, root.maximumHeight - 172))
            visible: Notifications.history.length > 0
            contentWidth: availableWidth
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            Column {
                id: cards
                width: scroll.availableWidth
                spacing: Design.space8
                Repeater {
                    model: Notifications.history
                    NotificationCard {
                        required property var modelData
                        width: cards.width
                        entry: modelData
                        onDismissed: Notifications.remove(entry.key)
                    }
                }
            }
        }
    }
}
