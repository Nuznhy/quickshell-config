pragma ComponentBehavior: Bound
import QtQuick
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
    ColumnLayout {
        id: content
        x: 0; y: 0
        width: parent.width
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
            }
            NotificationButton {
                text: "Clear all"
                enabled: Notifications.history.length > 0
                onClicked: Notifications.clearHistory()
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 10
            color: Theme.surface
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                Text {
                    Layout.fillWidth: true
                    text: "Do Not Disturb"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
                Switch {
                    id: dndSwitch
                    implicitWidth: 40
                    implicitHeight: 26
                    padding: 0
                    hoverEnabled: true
                    Accessible.name: "Do Not Disturb"
                    checked: Notifications.doNotDisturb
                    onToggled: Notifications.setDoNotDisturb(checked)
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    background: null
                    contentItem: Item {}
                    indicator: Rectangle {
                        width: 40
                        height: 22
                        y: (dndSwitch.height - height) / 2
                        radius: 11
                        color: dndSwitch.checked ? Theme.iris : Theme.highlightMed
                        border.color: dndSwitch.activeFocus || dndSwitch.hovered ? Theme.iris : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Rectangle {
                            x: dndSwitch.checked ? 21 : 3
                            y: 3
                            width: 16
                            height: 16
                            radius: 8
                            color: dndSwitch.checked ? Theme.bg : Theme.text
                            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: Notifications.errorMessage.length > 0
            text: Notifications.errorMessage
            color: Theme.love
            font.family: Theme.fontFamily
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
        Text {
            text: "RECENT  ·  " + Notifications.history.length
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1
        }
        Item {
            Layout.fillWidth: true
            implicitHeight: 140
            visible: Notifications.history.length === 0
            Column {
                anchors.centerIn: parent
                spacing: 10
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂚"
                    color: Theme.iris
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                }
                Text {
                    text: "You're all caught up"
                    color: Theme.subtle
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }
        ScrollView {
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
                spacing: 8
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
