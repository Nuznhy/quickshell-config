import QtQuick
import "../../../components/ui" as UI
import "../../../config"
import "../../../services"
import "../../../components"

Item {
    id: root
    implicitWidth: Math.max(30, Theme.fontSize + 8)
    implicitHeight: Settings.barHeight
    activeFocusOnTab: true
    readonly property string actionText: DisplayMode.mirrored
        ? "Restore configured monitor layout" : "Duplicate laptop screen"
    readonly property string description: DisplayMode.busy ? "Checking / changing displays…"
        : DisplayMode.errorMessage || (!DisplayMode.available ? DisplayMode.reason
        : actionText + "\n" + DisplayMode.laptop + " → " + DisplayMode.outputs.join(", ")
            + (DisplayMode.mirrored ? "" : "\nAutomatic resolution"))
    Accessible.role: Accessible.Button
    Accessible.name: actionText
    Accessible.description: description
    Accessible.onPressAction: DisplayMode.toggle()
    Keys.onSpacePressed: DisplayMode.toggle()
    Keys.onReturnPressed: DisplayMode.toggle()
    BarHoverIndicator {
        anchors.fill: parent
        hovered: mouse.containsMouse
        focused: root.activeFocus
    }
    UI.Text {
        role: "bar"
        anchors.centerIn: parent
        text: DisplayMode.mirrored ? "󰍺" : "󰍹"
        color: DisplayMode.errorMessage ? Design.danger : !DisplayMode.available ? Design.textSecondary
            : DisplayMode.mirrored ? Design.accent : Design.text
        opacity: DisplayMode.busy ? 0.5 : 1
        font.family: Design.fontFamily
        font.pixelSize: Theme.fontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: DisplayMode.available && !DisplayMode.busy ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: DisplayMode.toggle()
    }
}
