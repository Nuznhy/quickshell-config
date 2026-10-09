pragma ComponentBehavior: Bound
import QtQuick
import "../../../components/ui" as UI
import QtQuick.Layouts
import Quickshell
import "../../../components"
import "../../../config"
import "../../../services"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    Layout.preferredHeight: Settings.barHeight
    Layout.rightMargin: 0
    popupWidth: 420
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    rightClickEnabled: true
    onRightClicked: Notifications.setDoNotDisturb(!Notifications.doNotDisturb)
    Item {
        width: 30
        height: parent.height
        UI.Text {
            role: "bar"
            anchors.centerIn: parent
            text: Notifications.doNotDisturb ? "󰂛" : "󰂚"
            color: Notifications.doNotDisturb ? Design.accent : Design.text
            font.family: Design.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 1.05)
        }
        Rectangle {
            visible: Notifications.unreadCount > 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Design.space8
            width: 6; height: 6; radius: Design.radiusSmall
            color: Design.danger
        }
    }
    popupContent: NotificationCenter {
        active: root.dropdownOpen
        maximumHeight: Math.min(540, (root.barWindow?.screen?.height || 800) - 120)
        onDismissed: root.dropdownOpen = false
    }
}
