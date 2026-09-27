import QtQuick
import "../../../config"
import "../../../services"

Item {
    id: langWidget
    implicitWidth: content.implicitWidth + 8
    implicitHeight: Settings.barHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 6
        color: Theme.overlay
        visible: keyboardMouse.containsMouse
    }

    Row {
        id: content
        anchors.centerIn: parent
        height: parent.height
        spacing: 8

        Text {
            id: keyboardIcon
            readonly property rect inkBounds: iconMetrics.tightBoundingRect(text)
            width: Theme.fontSize + 12
            y: (content.height - inkBounds.height) / 2 - inkBounds.y - baselineOffset
            text: "󰌌"
            color: Theme.text
            font.pixelSize: Theme.fontSize + 8
            font.family: Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            FontMetrics {
                id: iconMetrics
                font: keyboardIcon.font
            }
        }

        Text {
            id: languageLabel
            readonly property rect inkBounds: labelMetrics.tightBoundingRect(text)
            width: implicitWidth
            // Center the visible letters, excluding the font's ascender/descender padding.
            y: (content.height - inkBounds.height) / 2 - inkBounds.y - baselineOffset
            text: Keyboard.layoutName.toUpperCase()
            color: Theme.text
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            FontMetrics {
                id: labelMetrics
                font: languageLabel.font
            }
        }
    }

    MouseArea {
        id: keyboardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Keyboard.nextLayout()
    }
}
