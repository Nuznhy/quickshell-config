pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root
    signal backRequested
    spacing: 16
    component Label: Text {
        Layout.fillWidth: true
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    component Card: Pane {
        default property alias items: body.data
        Layout.fillWidth: true
        padding: 16
        background: Rectangle { color: Theme.surface; radius: 12; border.color: Theme.highlightMed }
        contentItem: ColumnLayout { id: body; spacing: 12 }
    }
    RowLayout {
        Layout.fillWidth: true
        NotificationButton {
            text: "‹"
            Layout.preferredWidth: 32
            Accessible.name: "Back to bar layout"
            onClicked: root.backRequested()
        }
        Label { text: "Workspaces"; font.pixelSize: 18; font.bold: true }
        NotificationButton {
            objectName: "workspace-settings-reset"
            text: "Reset"
            enabled: WorkspaceAppearance.ready
            onClicked: WorkspaceAppearance.reset()
        }
    }
    Label {
        text: "Personalize the icons beside each workspace number. Changes save automatically."
        color: Theme.subtle
    }
    Card {
        RowLayout {
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
            font.pixelSize: 11
            color: Theme.subtle
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
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
            font.pixelSize: 11
            color: Theme.subtle
        }
    }
    Card {
        Label { text: "Separator"; font.pixelSize: 14 }
        Label {
            text: "Between the workspace number and its icons. Leave empty for no separator."
            font.pixelSize: 11
            color: Theme.subtle
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
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
        TextField {
            id: separator
            objectName: "workspace-separator-input"
            Layout.fillWidth: true
            implicitHeight: 38
            maximumLength: 16
            text: WorkspaceAppearance.separator
            placeholderText: "Custom separator (up to 8 characters)"
            color: Theme.text
            placeholderTextColor: Theme.subtle
            selectionColor: Theme.iris
            selectedTextColor: Theme.bg
            font.family: Theme.fontFamily
            font.pixelSize: 14
            enabled: WorkspaceAppearance.ready && WorkspaceAppearance.showIcons
            Accessible.name: "Workspace icon separator"
            onTextEdited: WorkspaceAppearance.setOption("separator", text)
            onEditingFinished: text = Qt.binding(() => WorkspaceAppearance.separator)
            background: Rectangle {
                color: Theme.overlay
                radius: 8
                border.color: separator.activeFocus ? Theme.iris : Theme.highlightMed
            }
        }
    }
    Card {
        RowLayout {
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
            font.pixelSize: 11
            color: Theme.subtle
        }
    }
    Label {
        visible: text !== ""
        text: WorkspaceAppearance.errorMessage
        color: Theme.love
    }
}
