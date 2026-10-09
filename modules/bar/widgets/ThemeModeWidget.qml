import QtQuick
import "../../../components/ui" as UI
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
        hovered: mouse.containsMouse
        focused: root.activeFocus
    }
    UI.Text {
        role: "bar"
        anchors.centerIn: parent
        text: Theme.isDark ? "󰖔" : "󰖙"
        color: Design.text
        font.family: Design.fontFamily
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
