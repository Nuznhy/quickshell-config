pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

UI.ColumnLayout {
    id: root
    spacing: Design.space8
    property string detailsId: ""
    readonly property var detailTarget: AppTheming.targets.find(target => target.id === detailsId) || null
    onVisibleChanged: { if (visible) AppTheming.refresh(); }

    component RefreshButton: UI.IconButton {
        text: "󰑐"
    }

    UI.RowLayout {
        Layout.fillWidth: true
        spacing: Design.space12
        UI.Text {
            text: "Application themes"
            font.family: Design.fontFamily
            role: "panel"
            font.bold: true
            color: Design.text
            Layout.fillWidth: true
        }
        RefreshButton {
            Accessible.name: "Refresh application availability"
            enabled: !AppTheming.busy
            onClicked: AppTheming.refresh()
        }
    }
    UI.Text {
        Layout.fillWidth: true
        text: "Let your apps and Hyprland follow the shell’s theme."
        color: Design.textSecondary
        font.family: Design.fontFamily
        role: "label"
        wrapMode: Text.WordWrap
    }
    UI.GridLayout {
        id: grid
        objectName: "app-themes-grid"
        Layout.fillWidth: true
        columns: Math.max(1, Math.floor((width + columnSpacing) / 230))
        uniformCellWidths: true
        uniformCellHeights: true
        readonly property real cellHeight: Math.ceil(Math.max(82, ...children.map(item => item.implicitHeight || 0)))
        columnSpacing: Design.space8
        rowSpacing: Design.space8
        Repeater {
            model: AppTheming.targets
            delegate: UI.Card {
                id: card
                required property var modelData
                objectName: "app-theme-card-" + modelData.id
                readonly property bool applying: AppTheming.isApplying(modelData.id)
                readonly property bool hasDetails: !!modelData.message && modelData.message !== "Applied"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: grid.cellHeight
                Layout.maximumHeight: grid.cellHeight
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                implicitHeight: Math.ceil(Math.max(82, cardContent.implicitHeight + Design.panelPadding * 2))

                border.color: modelData.state === "error" ? Design.danger : Design.border
                UI.ColumnLayout {
                    id: cardContent
                    x: Design.panelPadding; y: Design.panelPadding
                    width: parent.width - Design.panelPadding * 2
                    spacing: Design.space4
                    UI.RowLayout {
                        Layout.fillWidth: true
                        spacing: Design.space8
                        UI.Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: card.modelData.name
                            color: Design.text
                            font.family: Design.fontFamily
                            role: "body"
                            elide: Text.ElideRight
                        }
                        RefreshButton {
                            objectName: "app-theme-retry-" + card.modelData.id
                            visible: card.modelData.state === "error"
                            implicitWidth: 26
                            implicitHeight: Design.compactHeight
                            padding: Design.space2
                            leftPadding: Design.space2
                            rightPadding: Design.space2
                            topPadding: Design.space2
                            bottomPadding: Design.space2
                            Accessible.name: "Retry " + card.modelData.name
                            enabled: !card.applying
                            onClicked: AppTheming.retry(card.modelData.id)
                        }
                        ControlSwitch {
                            objectName: "app-theme-" + card.modelData.id
                            value: card.modelData.enabled
                            enabled: !card.applying && (card.modelData.available || card.modelData.enabled)
                            Accessible.name: card.modelData.id === "hyprland" ? "Override Hyprland appearance" : "Sync " + card.modelData.name + " colors"
                            onChangeRequested: value => AppTheming.setEnabled(card.modelData.id, value)
                        }
                    }
                    UI.Text {
                        Layout.fillWidth: true
                        visible: card.modelData.id === "hyprland" || card.modelData.id === "hyprland-colors"
                        text: card.modelData.id === "hyprland-colors"
                            ? "Follow bar colors for window borders."
                            : "Follow bar rounding, opacity, and margins, with shared spacing and blur."
                        role: "caption"
                        color: Design.textSecondary
                        wrapMode: Text.WordWrap
                    }
                    UI.Button {
                        id: statusButton
                        objectName: "app-theme-details-" + card.modelData.id
                        Layout.fillWidth: true
                        implicitHeight: Math.max(20, contentItem.implicitHeight)
                        padding: 0
                        enabled: card.hasDetails
                        text: card.applying ? "Applying…" : card.modelData.state === "error"
                            ? card.modelData.message || "Theme update failed. No error details were reported."
                            : !card.modelData.available ? "Unavailable" : !card.modelData.enabled ? "Off"
                            : card.modelData.state === "restart" ? "Restart app" : "Synced"
                        Accessible.name: card.modelData.name + ": " + text + (card.hasDetails ? ". Show details" : "")
                        Accessible.description: card.modelData.message || ""
                        onClicked: root.detailsId = root.detailsId === card.modelData.id ? "" : card.modelData.id

                        variant: "ghost"
                        contentItem: UI.RowLayout {
                            spacing: Design.space4
                            Rectangle {
                                implicitWidth: 5; implicitHeight: 5; radius: Design.radiusSmall
                                color: card.modelData.state === "error" ? Design.danger
                                    : card.modelData.enabled ? Design.accent : Design.textSecondary
                            }
                            UI.Text {
                                objectName: "app-theme-status-" + card.modelData.id
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: statusButton.text
                                textFormat: Text.PlainText
                                color: card.modelData.state === "error" ? Design.danger : Design.textSecondary
                                font.family: Design.fontFamily
                                role: "label"
                                wrapMode: card.modelData.state === "error" ? Text.Wrap : Text.NoWrap
                                elide: card.modelData.state === "error" ? Text.ElideNone : Text.ElideRight
                            }
                            UI.Text {
                                visible: card.hasDetails
                                text: root.detailsId === card.modelData.id ? "⌃" : "⌄"
                                color: statusButton.hovered || statusButton.activeFocus ? Design.accent : Design.textSecondary
                                font.family: Design.fontFamily
                                role: "section"
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
        implicitHeight: detailContent.implicitHeight + Design.panelPadding * 2
        radius: Design.radiusCard
        color: Design.surfaceRaised
        UI.ColumnLayout {
            id: detailContent
            x: Design.panelPadding; y: Design.panelPadding
            width: parent.width - Design.panelPadding * 2
            spacing: Design.space8
            UI.RowLayout {
                Layout.fillWidth: true
                UI.Text {
                    Layout.fillWidth: true
                    text: root.detailTarget?.name || ""
                    color: Design.text
                    font.family: Design.fontFamily
                    role: "body"
                    font.bold: true
                }
                UI.IconButton {
                    implicitWidth: 28
                    text: "×"
                    Accessible.name: "Close application theme details"
                    onClicked: root.detailsId = ""
                }
            }
            UI.Text {
                Layout.fillWidth: true
                text: root.detailTarget?.message || ""
                color: root.detailTarget?.state === "error" ? Design.danger : Design.textSecondary
                font.family: Design.fontFamily
                role: "label"
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
            }
        }
    }
    UI.Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: AppTheming.errorMessage
        color: Design.danger
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
    }
}
