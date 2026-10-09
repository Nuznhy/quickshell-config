pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Layouts
import Quickshell.Widgets
import "../config"
import "../services"

UI.Card {
    id: root
    required property var entry
    property bool toast: false
    implicitHeight: content.implicitHeight + Design.panelPadding * 2

    border.color: entry.urgency === 2 ? Design.danger : Design.border
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
    UI.ColumnLayout {
        id: content
        x: Design.panelPadding; y: Design.panelPadding
        width: parent.width - Design.panelPadding * 2
        spacing: Design.space8
        UI.RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8
            IconImage {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: Notifications.iconSource(root.entry.icon, root.entry.desktopEntry, root.entry.appName)
            }
            UI.Text {
                Layout.fillWidth: true
                text: root.entry.appName
                textFormat: Text.PlainText
                color: Design.textSecondary
                font.family: Design.fontFamily
                role: "label"
                elide: Text.ElideRight
            }
            Rectangle {
                visible: !root.entry.read && !root.toast
                implicitWidth: 6; implicitHeight: 6; radius: Design.radiusSmall
                color: Design.accent
            }
            UI.Text {
                text: Qt.formatDateTime(new Date(root.entry.timestamp), "d MMM, hh:mm")
                color: Design.textMuted
                font.family: Design.fontFamily
                role: "caption"
            }
            UI.IconButton {
                text: "×"
                implicitWidth: 24
                implicitHeight: Design.compactHeight
                leftPadding: 0; rightPadding: 0
                Accessible.name: root.toast ? "Dismiss notification" : "Remove from history"
                onClicked: root.dismissed()
            }
        }
        UI.Text {
            Layout.fillWidth: true
            text: root.entry.summary
            textFormat: Text.PlainText
            color: Design.text
            font.family: Design.fontFamily
            role: "body"
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: root.toast ? 2 : 8
            elide: Text.ElideRight
        }
        UI.Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.entry.body
            textFormat: Text.PlainText
            color: Design.textSecondary
            font.family: Design.fontFamily
            role: "body"
            wrapMode: Text.Wrap
            maximumLineCount: root.toast ? 4 : 100
            elide: Text.ElideRight
        }
        Flow {
            Layout.fillWidth: true
            visible: root.entry.actions.length > 0
            spacing: Design.space4
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
