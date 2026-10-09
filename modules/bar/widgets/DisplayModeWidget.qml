import QtQuick
import "../../../config"
import "../../../services"
import "../../../components"

Item {
    id: root
    implicitWidth: Math.max(30, Theme.fontSize + 8)
    implicitHeight: Settings.barHeight
    activeFocusOnTab: true
    readonly property string actionText: DisplayMode.pending ? "Keep TV"
        : DisplayMode.mode === "tv" ? "Switch to Desktop" : "Switch to TV"
    readonly property string description: DisplayMode.errorMessage
        || (DisplayMode.busy ? "Changing display layout…"
        : !DisplayMode.available ? DisplayMode.reason
        : DisplayMode.pending ? "Press Enter within 15 seconds, or click here, to keep TV"
        : DisplayMode.mode === "tv"
            ? "Switch to DP-1 and DP-2; restore workspace placement"
            : "Switch all workspaces and apps to HDMI-A-1")
    Accessible.role: Accessible.Button
    Accessible.name: actionText
    Accessible.description: description
    Accessible.onPressAction: DisplayMode.toggle()
    Keys.onSpacePressed: DisplayMode.toggle()
    Keys.onReturnPressed: DisplayMode.toggle()
    BarHoverIndicator {
        anchors.fill: parent
        hovered: mouse.containsMouse || root.activeFocus
    }
    Text {
        anchors.centerIn: parent
        text: DisplayMode.mode === "tv" ? "󰟴" : "󰍹"
        color: DisplayMode.errorMessage ? Theme.love : !DisplayMode.available ? Theme.subtle
            : DisplayMode.mode === "tv" ? Theme.iris : Theme.text
        opacity: DisplayMode.busy ? 0.5 : 1
        font.family: Theme.fontFamily
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
