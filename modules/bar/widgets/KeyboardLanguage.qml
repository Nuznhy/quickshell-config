import QtQuick
import qs.components.shared
import qs.components.ui as UI
import qs.config
import qs.services.keyboard

Item {
    id: langWidget
    implicitWidth: Theme.verticalBar ? verticalLabel.implicitWidth : content.implicitWidth
    implicitHeight: Theme.verticalBar ? Math.max(Settings.barHeight, verticalLabel.implicitHeight + 8) : Settings.barHeight

    BarHoverIndicator {
        anchors.fill: parent
        hovered: keyboardMouse.containsMouse
    }

    UI.Text {
        id: verticalLabel
        role: "bar"
        anchors.centerIn: parent
        visible: Theme.verticalBar
        text: "󰌌\n" + Keyboard.layoutName.toUpperCase()
        color: Design.text
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
        spacing: Design.space8

        UI.Text {
            id: keyboardIcon
            role: "bar"
            readonly property rect inkBounds: iconMetrics.tightBoundingRect(text)
            width: Theme.fontSize + 12
            y: (content.height - inkBounds.height) / 2 - inkBounds.y - baselineOffset
            text: "󰌌"
            color: Design.text
            font.pixelSize: Theme.fontSize + 8
            font.family: Design.fontFamily
            horizontalAlignment: Text.AlignHCenter
            FontMetrics {
                id: iconMetrics
                font: keyboardIcon.font
            }
        }

        UI.Text {
            id: languageLabel
            role: "bar"
            readonly property rect inkBounds: labelMetrics.tightBoundingRect(text)
            width: implicitWidth
            // Center the visible letters, excluding the font's ascender/descender padding.
            y: (content.height - inkBounds.height) / 2 - inkBounds.y - baselineOffset
            text: Keyboard.layoutName.toUpperCase()
            color: Design.text
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
