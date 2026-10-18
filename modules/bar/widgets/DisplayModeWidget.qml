import QtQuick
import qs.components.shared
import qs.components.ui as UI
import qs.config
import qs.services.display

Item {
    id: root
    implicitWidth: Math.max(30, Theme.fontSize + 8)
    implicitHeight: Settings.barHeight
    activeFocusOnTab: true
    readonly property string actionText: DisplayMode.mirrored ? "Restore configured monitor layout" : "Duplicate laptop screen"
    readonly property string description: DisplayMode.changing ? "Changing displays…" : DisplayMode.errorMessage || (!DisplayMode.available ? DisplayMode.reason : actionText + "\n" + DisplayMode.laptop + " → " + DisplayMode.outputs.join(", ") + (DisplayMode.mirrored ? "" : "\nAutomatic resolution"))
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
    UI.Icon {
        objectName: "display-status-icon"
        anchors.centerIn: parent
        text: DisplayMode.mirrored ? "󰍺" : "󰍹"
        color: DisplayMode.errorMessage ? Design.barColor("danger") : !DisplayMode.available ? Design.barColor("textSecondary") : DisplayMode.mirrored ? Design.barColor("accent") : Design.barColor("text")
        size: Theme.fontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: DisplayMode.available && !DisplayMode.busy ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: DisplayMode.toggle()
    }
}
