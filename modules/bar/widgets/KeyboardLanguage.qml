import QtQuick
import "../../../config"
import "../../../services"
import "../../../components"

Item {
    id: langWidget
    implicitWidth: Theme.verticalBar ? verticalLabel.implicitWidth : content.implicitWidth
    implicitHeight: Theme.verticalBar ? Math.max(Settings.barHeight, verticalLabel.implicitHeight + 8) : Settings.barHeight

    BarHoverIndicator {
        anchors.fill: parent
        hovered: keyboardMouse.containsMouse
    }

    Text {
        id: verticalLabel
        anchors.centerIn: parent
        visible: Theme.verticalBar
        text: "󰌌\n" + Keyboard.layoutName.toUpperCase()
        color: Theme.text
        font.family: Theme.barFontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
    }
    Row {
        id: content
        visible: !Theme.verticalBar
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
            font.family: Theme.barFontFamily
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
