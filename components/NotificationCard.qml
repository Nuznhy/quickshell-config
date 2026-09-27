pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../config"
import "../services"

Rectangle {
    id: root
    required property var entry
    property bool toast: false
    implicitHeight: content.implicitHeight + 24
    radius: 12
    color: Theme.surface
    border.color: entry.urgency === 2 ? Theme.love : Theme.highlightMed
    signal dismissed

    HoverHandler {
        onHoveredChanged: {
            const watcher = Notifications.watchers[root.entry.key];
            if (root.toast && watcher) watcher.hovered = hovered;
        }
    }
    Component.onDestruction: {
        const watcher = Notifications.watchers[entry.key];
        if (toast && watcher) watcher.hovered = false;
    }
    ColumnLayout {
        id: content
        x: 12; y: 12
        width: parent.width - 24
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconImage {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: Notifications.iconSource(root.entry.icon, root.entry.desktopEntry, root.entry.appName)
            }
            Text {
                Layout.fillWidth: true
                text: root.entry.appName
                textFormat: Text.PlainText
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Rectangle {
                visible: !root.entry.read && !root.toast
                implicitWidth: 6; implicitHeight: 6; radius: 3
                color: Theme.iris
            }
            Text {
                text: Qt.formatDateTime(new Date(root.entry.timestamp), "d MMM, hh:mm")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            NotificationButton {
                text: "×"
                implicitWidth: 24
                implicitHeight: 24
                leftPadding: 0; rightPadding: 0
                Accessible.name: root.toast ? "Dismiss notification" : "Remove from history"
                onClicked: root.dismissed()
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.entry.summary
            textFormat: Text.PlainText
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: root.toast ? 2 : 8
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.entry.body
            textFormat: Text.PlainText
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: root.toast ? 4 : 100
            elide: Text.ElideRight
        }
        Flow {
            Layout.fillWidth: true
            visible: root.entry.actions.length > 0
            spacing: 6
            Repeater {
                model: root.entry.actions
                NotificationButton {
                    required property var modelData
                    text: modelData.identifier === "default" ? "Open" : modelData.text
                    width: Math.min(implicitWidth, content.width)
                    onClicked: Notifications.invoke(root.entry.key, modelData.identifier)
                }
            }
        }
    }
}
