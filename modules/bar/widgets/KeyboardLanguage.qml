import QtQuick
import qs.components.shared
import qs.components.ui as UI
import qs.config
import qs.services.keyboard

Item {
    id: langWidget
    implicitWidth: content.implicitWidth
    implicitHeight: Theme.verticalBar ? Math.max(Settings.barHeight, content.implicitHeight + 8) : Settings.barHeight

    BarHoverIndicator {
        anchors.fill: parent
        hovered: keyboardMouse.containsMouse
    }

    IconLabel {
        id: content
        anchors.centerIn: parent
        icon: "󰌌"
        text: Keyboard.layoutName.toUpperCase()
    }

    MouseArea {
        id: keyboardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Keyboard.nextLayout()
    }
}
