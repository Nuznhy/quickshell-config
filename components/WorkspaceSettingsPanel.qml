pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

UI.ColumnLayout {
    id: root
    signal backRequested
    spacing: Design.space16
    component Label: UI.Text {
        Layout.fillWidth: true
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    component Card: UI.Pane {
        default property alias items: body.data
        Layout.fillWidth: true
        padding: Design.panelPadding
        background: UI.Card { border.color: Design.border }
        contentItem: UI.ColumnLayout { id: body; spacing: Design.space12 }
    }
    UI.RowLayout {
        Layout.fillWidth: true
        UI.IconButton {
            text: "‹"
            Layout.preferredWidth: 32
            Accessible.name: "Back to bar layout"
            onClicked: root.backRequested()
        }
        Label { text: "Workspaces"; role: "panel"; font.bold: true }
        NotificationButton {
            objectName: "workspace-settings-reset"
            text: "Reset"
            enabled: WorkspaceAppearance.ready
            onClicked: WorkspaceAppearance.reset()
        }
    }
    Label {
        text: "Personalize the icons beside each workspace number. Changes save automatically."
        color: Design.textSecondary
    }
    Card {
        UI.RowLayout {
            Layout.fillWidth: true
            Label { text: "Show app icons" }
            ControlSwitch {
                objectName: "workspace-show-icons"
                value: WorkspaceAppearance.showIcons
                enabled: WorkspaceAppearance.ready
                Accessible.name: "Show app icons in workspaces"
                onChangeRequested: value => WorkspaceAppearance.setOption("showIcons", value)
            }
        }
        Label {
            text: "Each icon represents a window. Click it to focus that window."
            role: "label"
            color: Design.textSecondary
        }
        UI.RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8
            Repeater {
                model: [{id: "app", label: "App icons"}, {id: "nerd", label: "Nerd Font icons"}]
                NotificationButton {
                    required property var modelData
                    objectName: "workspace-icon-style-" + modelData.id
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: modelData.label
                    accent: WorkspaceAppearance.iconStyle === modelData.id
                    enabled: WorkspaceAppearance.ready && WorkspaceAppearance.showIcons
                    Accessible.checkable: true
                    Accessible.checked: accent
                    onClicked: WorkspaceAppearance.setOption("iconStyle", modelData.id)
                }
            }
        }
        Label {
            text: "Nerd Font icons use matching app symbols, with a generic icon for unknown apps."
            role: "label"
            color: Design.textSecondary
        }
    }
    Card {
        Label { text: "Separator"; role: "section" }
        Label {
            text: "Between the workspace number and its icons. Leave empty for no separator."
            role: "label"
            color: Design.textSecondary
        }
        UI.RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8
            Repeater {
                model: [{label: "None", value: ""}, {label: "Dot", value: "·"}, {label: "Line", value: "|"}, {label: "Slash", value: "/"}]
                NotificationButton {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: modelData.label
                    accent: WorkspaceAppearance.separator === modelData.value
                    enabled: WorkspaceAppearance.ready && WorkspaceAppearance.showIcons
                    onClicked: WorkspaceAppearance.setOption("separator", modelData.value)
                }
            }
        }
        UI.TextField {
            id: separator
            objectName: "workspace-separator-input"
            Layout.fillWidth: true
            maximumLength: 16
            text: WorkspaceAppearance.separator
            placeholderText: "Custom separator (up to 8 characters)"
            enabled: WorkspaceAppearance.ready && WorkspaceAppearance.showIcons
            Accessible.name: "Workspace icon separator"
            onTextEdited: WorkspaceAppearance.setOption("separator", text)
            onEditingFinished: text = Qt.binding(() => WorkspaceAppearance.separator)

        }
    }
    Card {
        UI.RowLayout {
            Layout.fillWidth: true
            Label { text: "Icon capsule" }
            ControlSwitch {
                objectName: "workspace-icon-capsule"
                value: WorkspaceAppearance.capsule
                enabled: WorkspaceAppearance.ready && WorkspaceAppearance.showIcons
                Accessible.name: "Draw a capsule around workspace app icons"
                onChangeRequested: value => WorkspaceAppearance.setOption("capsule", value)
            }
        }
        Label {
            text: "Group app icons inside a rounded background."
            role: "label"
            color: Design.textSecondary
        }
    }
    Label {
        visible: text !== ""
        text: WorkspaceAppearance.errorMessage
        color: Design.danger
    }
}
