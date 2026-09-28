import QtQuick
import QtQuick.Controls
import Quickshell
import "../../../config"
import "../../../services"
import "../../../components"

Item {
    implicitWidth: 30
    implicitHeight: Settings.barHeight
    BarHoverIndicator {
        anchors.fill: parent
        hovered: mouse.containsMouse
        active: ShellSettings.opened
    }
    SettingsIcon {
        anchors.centerIn: parent
        color: ShellSettings.opened ? Theme.iris : Theme.text
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            parent.QsWindow.window?.closeAllPopups();
            ShellSettings.open();
        }
    }
    ToolTip.visible: mouse.containsMouse
    ToolTip.delay: 600
    ToolTip.text: "Settings"
}
