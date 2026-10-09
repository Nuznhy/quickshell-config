pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root
    spacing: 16
    focus: true
    signal dismissed
    Keys.onEscapePressed: dismissed()

    component Label: Text {
        Layout.fillWidth: true
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }
    component Section: Pane {
        id: section
        property string title: ""
        property string description: ""
        default property alias items: sectionBody.data
        Layout.fillWidth: true
        padding: 16
        background: Rectangle {
            color: Theme.surface
            radius: 14
            border.color: Theme.highlightMed
        }
        contentItem: ColumnLayout {
            id: sectionBody
            spacing: 14
            Label {
                visible: section.title !== ""
                text: section.title
                font.pixelSize: 16
                font.bold: true
            }
            Label {
                visible: section.description !== ""
                text: section.description
                color: Theme.subtle
                font.pixelSize: 11
                Layout.topMargin: -8
            }
        }
    }
    component Choice: Button {
        id: choice
        property bool selected: false
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.minimumWidth: 0
        implicitHeight: 36
        padding: 8
        topInset: 0
        bottomInset: 0
        enabled: Theme.ready
        hoverEnabled: true
        Accessible.checkable: true
        Accessible.checked: selected
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        background: Rectangle {
            radius: 8
            color: choice.selected ? Theme.iris : choice.hovered ? Theme.highlightMed : Theme.overlay
            border.color: choice.activeFocus ? Theme.text : "transparent"
        }
        contentItem: Text {
            text: choice.text
            color: choice.selected ? Theme.bg : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Label {
            text: "Make it yours"
            font.pixelSize: 22
            font.bold: true
        }
        Label {
            Layout.fillWidth: false
            text: Theme.errorMessage ? "Could not save" : Theme.ready ? "Changes save automatically" : "Loading…"
            color: Theme.errorMessage ? Theme.love : Theme.subtle
            font.pixelSize: 10
        }
    }

    Section {
        title: "Colors"
        description: "Choose a palette and a light or dark look."
        GridLayout {
            Layout.fillWidth: true
            columns: width >= 560 ? 2 : 1
            columnSpacing: 20
            rowSpacing: 12
            ThemeDropdown {
                Layout.fillWidth: true
                Layout.preferredWidth: 3
                Layout.minimumWidth: 0
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.minimumWidth: 0
                spacing: 8
                Label { text: "Color mode"; color: Theme.subtle; font.pixelSize: 11 }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
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
            radius: 10
            color: Theme.bg
            border.color: Theme.highlightMed
            clip: true
            readonly property bool vertical: Theme.verticalBar
            readonly property real edge: 8 + Theme.barTopMargin * 0.35
            readonly property real ends: 8 + Theme.barSideMargin * 0.35
            Text {
                anchors.centerIn: parent
                text: "Bar preview"
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            Rectangle {
                id: sampleBar
                x: preview.vertical ? (Theme.barPosition === "left" ? preview.edge : preview.width - width - preview.edge) : preview.ends
                y: preview.vertical ? preview.ends : (Theme.barPosition === "top" ? preview.edge : preview.height - height - preview.edge)
                width: preview.vertical ? 30 : preview.width - preview.ends * 2
                height: preview.vertical ? preview.height - preview.ends * 2 : 30
                color: Qt.rgba(Theme.overlay.r, Theme.overlay.g, Theme.overlay.b, Theme.barOpacity)
                radius: Math.min(Theme.barRadius, 15)
                border.color: Qt.rgba(Theme.iris.r, Theme.iris.g, Theme.iris.b, 0.4)
                Row {
                    visible: !preview.vertical
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            width: index === 0 ? 18 : 6
                            height: 6
                            radius: 3
                            color: index === 0 ? Theme.iris : Theme.subtle
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: preview.vertical ? "12\n34" : "12:34"
                    color: Theme.text
                    font.family: Theme.barFontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.6)
                    horizontalAlignment: Text.AlignHCenter
                }
                SettingsIcon {
                    visible: !preview.vertical
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 14
                    color: Theme.iris
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
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
        GridLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 680
            columns: width >= 480 ? 2 : 1
            columnSpacing: 24
            rowSpacing: 12
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
        GridLayout {
            Layout.fillWidth: true
            columns: width >= 560 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 8
            Repeater {
                model: Theme.connectedScreens
                delegate: Rectangle {
                    id: monitorCard
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    implicitHeight: 48
                    color: Theme.overlay
                    radius: 8
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
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
        color: Theme.love
        font.pixelSize: 11
    }
}
