pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

UI.ColumnLayout {
    id: root
    spacing: Design.space16
    focus: true
    signal dismissed
    Keys.onEscapePressed: dismissed()

    component Label: UI.Text {
        Layout.fillWidth: true
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        wrapMode: Text.WordWrap
    }
    component Section: UI.Pane {
        id: section
        property string title: ""
        property string description: ""
        default property alias items: sectionBody.data
        Layout.fillWidth: true
        padding: Design.panelPadding
        background: UI.Card {
            border.color: Design.border
        }
        contentItem: UI.ColumnLayout {
            id: sectionBody
            spacing: Design.space12
            Label {
                visible: section.title !== ""
                text: section.title
                role: "section"
                font.bold: true
            }
            Label {
                visible: section.description !== ""
                text: section.description
                color: Design.textSecondary
                role: "label"
                Layout.topMargin: -8
            }
        }
    }
    component Choice: UI.Button {
        highlighted: selected
        id: choice
        property bool selected: false
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.minimumWidth: 0
        implicitHeight: Design.controlHeight
        padding: Design.space8
        topInset: 0
        bottomInset: 0
        enabled: Theme.ready
        Accessible.checkable: true
        Accessible.checked: selected

    }

    UI.RowLayout {
        Layout.fillWidth: true
        Label {
            text: "Make it yours"
            role: "panel"
            font.bold: true
        }
        Label {
            Layout.fillWidth: false
            text: Theme.errorMessage ? "Could not save" : Theme.ready ? "Changes save automatically" : "Loading…"
            color: Theme.errorMessage ? Design.danger : Design.textSecondary
            role: "caption"
        }
    }

    Section {
        title: "Colors"
        description: "Choose a palette and a light or dark look."
        UI.GridLayout {
            Layout.fillWidth: true
            columns: width >= 560 ? 2 : 1
            columnSpacing: Design.space20
            rowSpacing: Design.space12
            ThemeDropdown {
                Layout.fillWidth: true
                Layout.preferredWidth: 3
                Layout.minimumWidth: 0
            }
            UI.ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.minimumWidth: 0
                spacing: Design.space8
                Label { text: "Color mode"; color: Design.textSecondary; role: "label" }
                UI.RowLayout {
                    Layout.fillWidth: true
                    spacing: Design.space4
                    Choice {
                        text: "Dark"
                        selected: Theme.mode === "dark"
                        onClicked: Theme.selectMode("dark")
                    }
                    Choice {
                        text: "Light"
                        selected: Theme.mode === "light"
                        onClicked: Theme.selectMode("light")
                    }
                }
            }
        }
    }

    Section {
        title: "Bar style"
        description: "Position, transparency, and space around your bar."
        Rectangle {
            id: preview
            objectName: "appearance-bar-preview"
            Layout.fillWidth: true
            implicitHeight: 104
            radius: Design.radiusCard
            color: Design.background
            border.color: Design.border
            clip: true
            readonly property bool vertical: Theme.verticalBar
            readonly property real edge: 8 + Theme.barTopMargin * 0.35
            readonly property real ends: 8 + Theme.barSideMargin * 0.35
            UI.Text {
                anchors.centerIn: parent
                text: "Bar preview"
                color: Design.textSecondary
                font.family: Design.fontFamily
                role: "caption"
            }
            Rectangle {
                id: sampleBar
                x: preview.vertical ? (Theme.barPosition === "left" ? preview.edge : preview.width - width - preview.edge) : preview.ends
                y: preview.vertical ? preview.ends : (Theme.barPosition === "top" ? preview.edge : preview.height - height - preview.edge)
                width: preview.vertical ? 30 : preview.width - preview.ends * 2
                height: preview.vertical ? preview.height - preview.ends * 2 : 30
                color: Qt.rgba(Design.surfaceRaised.r, Design.surfaceRaised.g, Design.surfaceRaised.b, Theme.barOpacity)
                radius: Math.min(Theme.barRadius, 15)
                border.color: Qt.rgba(Design.accent.r, Design.accent.g, Design.accent.b, 0.4)
                Row {
                    visible: !preview.vertical
                    anchors.left: parent.left
                    anchors.leftMargin: Design.space8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Design.space4
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: index === 0 ? 18 : 6
                            height: 6
                            radius: Design.radiusSmall
                            color: index === 0 ? Design.accent : Design.textSecondary
                        }
                    }
                }
                UI.Text {
                    role: "bar"
                    anchors.centerIn: parent
                    text: preview.vertical ? "12\n34" : "12:34"
                    color: Design.text
                    font.family: Theme.barFontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.6)
                    horizontalAlignment: Text.AlignHCenter
                }
                SettingsIcon {
                    visible: !preview.vertical
                    anchors.right: parent.right
                    anchors.rightMargin: Design.space8
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 14
                    color: Design.accent
                }
            }
        }
        UI.RowLayout {
            Layout.fillWidth: true
            spacing: Design.space4
            Repeater {
                model: ["top", "left", "bottom", "right"]
                Choice {
                    required property string modelData
                    objectName: "appearance-position-" + modelData
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    Accessible.name: "Bar position: " + text
                    selected: Theme.barPosition === modelData
                    onClicked: Theme.setBarPosition(modelData)
                }
            }
        }
        UI.GridLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 680
            columns: width >= 480 ? 2 : 1
            columnSpacing: Design.space24
            rowSpacing: Design.space12
            AppearanceSlider {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                label: "Opacity"
                minimum: 20
                maximum: 100
                suffix: "%"
                value: Theme.barOpacity * 100
                onValueEdited: value => Theme.setBarOpacity(value / 100)
                onEditingFinished: Theme.save()
            }
            AppearanceSlider {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                label: "Corner rounding"
                maximum: Theme.maximumBarRadius
                value: Theme.barRadius
                onValueEdited: value => Theme.setBarGeometry("barRadius", value)
                onEditingFinished: Theme.save()
            }
            AppearanceSlider {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                label: "Space from screen edge"
                value: Theme.barTopMargin
                onValueEdited: value => Theme.setBarGeometry("barTopMargin", value)
                onEditingFinished: Theme.save()
            }
            AppearanceSlider {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                label: "Space at bar ends"
                value: Theme.barSideMargin
                onValueEdited: value => Theme.setBarGeometry("barSideMargin", value)
                onEditingFinished: Theme.save()
            }
        }
    }

    Section {
        title: "Text & icon"
        description: "Choose a font, adjust the text size, and pick your settings button."
        BarFontPicker { Layout.fillWidth: true }
        AppearanceSlider {
            Layout.fillWidth: true
            Layout.maximumWidth: 340
            label: "Bar text size"
            minimum: 12
            maximum: 28
            value: Theme.fontSize
            onValueEdited: value => Theme.setFontSize(value)
            onEditingFinished: Theme.save()
        }
        SettingsIconEditor { Layout.fillWidth: true }
    }

    Section {
        title: "Displays"
        description: "Choose where the bar appears. At least one display stays enabled."
        UI.GridLayout {
            Layout.fillWidth: true
            columns: width >= 560 ? 2 : 1
            columnSpacing: Design.space12
            rowSpacing: Design.space8
            Repeater {
                model: Theme.connectedScreens
                delegate: Rectangle {
                    id: monitorCard
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    implicitHeight: 48
                    color: Design.surfaceRaised
                    radius: Design.radiusControl
                    UI.RowLayout {
                        anchors.fill: parent
                        anchors.margins: Design.panelPadding
                        Label {
                            Layout.minimumWidth: 0
                            text: monitorCard.modelData.name
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                        }
                        ControlSwitch {
                            value: Theme.barEnabled(monitorCard.modelData.name)
                            enabled: Theme.ready && (!value || Theme.enabledBarScreens.length > 1)
                            Accessible.name: "Show bar on " + monitorCard.modelData.name
                            onChangeRequested: value => Theme.setBarEnabled(monitorCard.modelData.name, value)
                        }
                    }
                }
            }
        }
    }

    Section {
        ApplicationThemes { Layout.fillWidth: true }
    }

    Label {
        visible: text.length > 0
        text: Theme.errorMessage
        color: Design.danger
        role: "label"
    }
}
