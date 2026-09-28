import QtQuick
import QtQuick.Controls
import "../../../config"
import "../../../components"

Item {
    id: root
    implicitWidth: Math.max(30, Theme.fontSize + 8)
    implicitHeight: Settings.barHeight
    enabled: Theme.ready
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: Theme.isDark ? "Switch to light mode" : "Switch to dark mode"
    function toggle() { Theme.selectMode(Theme.isDark ? "light" : "dark"); }
    Accessible.onPressAction: toggle()
    Keys.onSpacePressed: toggle()
    Keys.onReturnPressed: toggle()
    BarHoverIndicator {
        anchors.fill: parent
        hovered: mouse.containsMouse || root.activeFocus
    }
    Text {
        anchors.centerIn: parent
        text: Theme.isDark ? "󰖔" : "󰖙"
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
    }
}
