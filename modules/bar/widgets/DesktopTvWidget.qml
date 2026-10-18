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
    readonly property string actionText: DesktopTv.pending ? "Keep TV" : DesktopTv.mode === "tv" ? "Switch to Desktop" : "Switch to TV"
    readonly property string description: DesktopTv.errorMessage || (DesktopTv.changing ? "Changing display layout…" : !DesktopTv.available ? DesktopTv.reason : DesktopTv.pending ? "Press Enter within 15 seconds, or click here, to keep TV" : DesktopTv.mode === "tv" ? "Switch to DP-1 and DP-2; restore workspace placement" : "Switch all workspaces and apps to HDMI-A-1")
    Accessible.role: Accessible.Button
    Accessible.name: actionText
    Accessible.description: description
    Accessible.onPressAction: DesktopTv.toggle()
    Keys.onSpacePressed: DesktopTv.toggle()
    Keys.onReturnPressed: DesktopTv.toggle()
    BarHoverIndicator {
        anchors.fill: parent
        hovered: mouse.containsMouse
        focused: root.activeFocus
    }
    UI.Icon {
        objectName: "display-status-icon"
        anchors.centerIn: parent
        text: DesktopTv.mode === "tv" ? "󰟴" : "󰍹"
        color: DesktopTv.errorMessage ? Design.barColor("danger") : !DesktopTv.available ? Design.barColor("textSecondary") : DesktopTv.mode === "tv" ? Design.barColor("accent") : Design.barColor("text")
        size: Theme.fontSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: DesktopTv.available && !DesktopTv.busy ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: DesktopTv.toggle()
    }
}
