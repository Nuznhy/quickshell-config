pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root
    spacing: 12
    focus: true
    signal dismissed
    Keys.onEscapePressed: dismissed()

    Text {
        text: "Appearance"
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 19
        font.bold: true
    }

    Text {
        text: "Choose your shell’s colors"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: ["dark", "light"]
            Button {
                id: modeButton
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: 0
                Layout.minimumHeight: 40
                Layout.preferredHeight: 40
                Layout.maximumHeight: 40
                topInset: 0
                bottomInset: 0
                leftInset: 0
                rightInset: 0
                enabled: Theme.ready
                hoverEnabled: true
                HoverHandler {
                    enabled: modeButton.enabled
                    cursorShape: Qt.PointingHandCursor
                }
                text: modelData === "dark" ? "☾  Dark" : "☀  Light"
                checkable: true
                checked: Theme.mode === modelData
                onClicked: Theme.selectMode(modelData)
                background: Rectangle {
                    radius: 10
                    color: modeButton.checked || modeButton.hovered ? Theme.overlay : Theme.surface
                    border.width: modeButton.checked || modeButton.activeFocus ? 2 : 1
                    border.color: modeButton.checked || modeButton.activeFocus ? Theme.iris : Theme.highlightMed
                }
                contentItem: Text {
                    text: modeButton.text
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Text {
        text: "COLOR PALETTE"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.letterSpacing: 1.5
        Layout.topMargin: 4
    }

    ThemeDropdown {
        Layout.fillWidth: true
    }

    AppearanceSlider {
        Layout.fillWidth: true
        label: "Bar font size"
        minimum: 12
        maximum: 28
        value: Theme.fontSize
        onValueEdited: value => Theme.setFontSize(value)
        onEditingFinished: Theme.save()
    }

    SettingsIconEditor { Layout.fillWidth: true }

    Text {
        text: "BAR POSITION"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.letterSpacing: 1.5
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: ["top", "left", "bottom", "right"]
            NotificationButton {
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                accent: Theme.barPosition === modelData
                enabled: Theme.ready
                onClicked: Theme.setBarPosition(modelData)
            }
        }
    }

    AppearanceSlider {
        Layout.fillWidth: true
        label: "Bar opacity"
        minimum: 20
        maximum: 100
        suffix: "%"
        value: Theme.barOpacity * 100
        onValueEdited: value => Theme.setBarOpacity(value / 100)
        onEditingFinished: Theme.save()
    }

    AppearanceSlider {
        Layout.fillWidth: true
        label: "Edge margin"
        value: Theme.barTopMargin
        onValueEdited: value => Theme.setBarGeometry("barTopMargin", value)
        onEditingFinished: Theme.save()
    }

    AppearanceSlider {
        Layout.fillWidth: true
        label: "End margins"
        value: Theme.barSideMargin
        onValueEdited: value => Theme.setBarGeometry("barSideMargin", value)
        onEditingFinished: Theme.save()
    }

    AppearanceSlider {
        Layout.fillWidth: true
        label: "Corner rounding"
        maximum: Theme.maximumBarRadius
        value: Theme.barRadius
        onValueEdited: value => Theme.setBarGeometry("barRadius", value)
        onEditingFinished: Theme.save()
    }

    Text {
        text: "MONITOR BARS"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.letterSpacing: 1.5
        Layout.topMargin: 4
    }

    Repeater {
        model: Theme.connectedScreens
        delegate: Rectangle {
            id: monitorCard
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 50
            color: Theme.surface
            radius: 10
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                Text {
                    Layout.fillWidth: true
                    text: monitorCard.modelData.name
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
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

    Text {
        Layout.fillWidth: true
        text: "Keep one bar enabled to access these settings."
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
        wrapMode: Text.WordWrap
    }

    ApplicationThemes { Layout.fillWidth: true }

    Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: Theme.errorMessage
        color: Theme.love
        font.family: Theme.fontFamily
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
