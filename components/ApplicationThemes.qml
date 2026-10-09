pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

ColumnLayout {
    id: root
    spacing: 10
    property string detailsId: ""
    readonly property var detailTarget: AppTheming.targets.find(target => target.id === detailsId) || null
    onVisibleChanged: { if (visible) AppTheming.refresh(); }

    component RefreshButton: NotificationButton {
        id: control
        implicitWidth: 36
        implicitHeight: 36
        padding: 7
        leftPadding: 7
        rightPadding: 7
        topPadding: 7
        bottomPadding: 7
        background: Rectangle {
            radius: 10
            color: control.down ? Theme.highlightMed : control.hovered ? Theme.overlay : Theme.surface
            border.color: control.hovered || control.activeFocus ? Theme.iris : Theme.highlightMed
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
        contentItem: Text {
            text: "󰑐"
            color: Theme.iris
            font.family: Theme.fontFamily
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Text {
            text: "Application themes"
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: Theme.text
            Layout.fillWidth: true
        }
        RefreshButton {
            Accessible.name: "Refresh application availability"
            enabled: !AppTheming.busy
            onClicked: AppTheming.refresh()
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Let your apps follow the shell’s colors."
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
    GridLayout {
        id: grid
        objectName: "app-themes-grid"
        Layout.fillWidth: true
        columns: Math.max(1, Math.floor((width + columnSpacing) / 230))
        columnSpacing: 10
        rowSpacing: 10
        Repeater {
            model: AppTheming.targets
            delegate: Rectangle {
                id: card
                required property var modelData
                objectName: "app-theme-card-" + modelData.id
                readonly property bool applying: AppTheming.isApplying(modelData.id)
                readonly property bool hasDetails: !!modelData.message && modelData.message !== "Applied"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignTop
                implicitHeight: Math.max(82, cardContent.implicitHeight + 24)
                radius: 10
                color: Theme.surface
                border.color: modelData.state === "error" ? Theme.love : Theme.highlightMed
                ColumnLayout {
                    id: cardContent
                    x: 12; y: 12
                    width: parent.width - 24
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: card.modelData.name
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        RefreshButton {
                            objectName: "app-theme-retry-" + card.modelData.id
                            visible: card.modelData.state === "error"
                            implicitWidth: 26
                            implicitHeight: 26
                            padding: 3
                            leftPadding: 3
                            rightPadding: 3
                            topPadding: 3
                            bottomPadding: 3
                            Accessible.name: "Retry " + card.modelData.name
                            enabled: !card.applying
                            onClicked: AppTheming.retry(card.modelData.id)
                        }
                        ControlSwitch {
                            objectName: "app-theme-" + card.modelData.id
                            value: card.modelData.enabled
                            enabled: !card.applying && (card.modelData.available || card.modelData.enabled)
                            Accessible.name: "Sync " + card.modelData.name + " colors"
                            onChangeRequested: value => AppTheming.setEnabled(card.modelData.id, value)
                        }
                    }
                    Button {
                        id: statusButton
                        objectName: "app-theme-details-" + card.modelData.id
                        Layout.fillWidth: true
                        implicitHeight: Math.max(20, contentItem.implicitHeight)
                        padding: 0
                        hoverEnabled: true
                        enabled: card.hasDetails
                        text: card.applying ? "Applying…" : card.modelData.state === "error"
                            ? card.modelData.message || "Theme update failed. No error details were reported."
                            : !card.modelData.available ? "Unavailable" : !card.modelData.enabled ? "Off"
                            : card.modelData.state === "restart" ? "Restart app" : "Synced"
                        Accessible.name: card.modelData.name + ": " + text + (card.hasDetails ? ". Show details" : "")
                        Accessible.description: card.modelData.message || ""
                        onClicked: root.detailsId = root.detailsId === card.modelData.id ? "" : card.modelData.id
                        HoverHandler { cursorShape: card.hasDetails ? Qt.PointingHandCursor : Qt.ArrowCursor }
                        background: null
                        contentItem: RowLayout {
                            spacing: 6
                            Rectangle {
                                implicitWidth: 5; implicitHeight: 5; radius: 3
                                color: card.modelData.state === "error" ? Theme.love
                                    : card.modelData.enabled ? Theme.iris : Theme.subtle
                            }
                            Text {
                                objectName: "app-theme-status-" + card.modelData.id
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: statusButton.text
                                textFormat: Text.PlainText
                                color: card.modelData.state === "error" ? Theme.love : Theme.subtle
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                wrapMode: card.modelData.state === "error" ? Text.Wrap : Text.NoWrap
                                elide: card.modelData.state === "error" ? Text.ElideNone : Text.ElideRight
                            }
                            Text {
                                visible: card.hasDetails
                                text: root.detailsId === card.modelData.id ? "⌃" : "⌄"
                                color: statusButton.hovered || statusButton.activeFocus ? Theme.iris : Theme.subtle
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        objectName: "app-theme-details-panel"
        Layout.fillWidth: true
        visible: !!root.detailTarget?.message
        implicitHeight: detailContent.implicitHeight + 24
        radius: 10
        color: Theme.overlay
        ColumnLayout {
            id: detailContent
            x: 12; y: 12
            width: parent.width - 24
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: root.detailTarget?.name || ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                }
                NotificationButton {
                    implicitWidth: 28
                    text: "×"
                    Accessible.name: "Close application theme details"
                    onClicked: root.detailsId = ""
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.detailTarget?.message || ""
                color: root.detailTarget?.state === "error" ? Theme.love : Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: AppTheming.errorMessage
        color: Theme.love
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
    }
}
