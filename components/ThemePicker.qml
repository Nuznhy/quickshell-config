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
                Layout.preferredHeight: 40
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
        label: "Top margin"
        value: Theme.barTopMargin
        onValueEdited: value => Theme.setBarGeometry("barTopMargin", value)
        onEditingFinished: Theme.save()
    }

    AppearanceSlider {
        Layout.fillWidth: true
        label: "Side margins"
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
        Layout.fillWidth: true
        visible: text.length > 0
        text: Theme.errorMessage
        color: Theme.love
        font.family: Theme.fontFamily
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
