pragma ComponentBehavior: Bound
import QtQuick
import "../../components/ui" as UI
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../components"
import "../../services"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    Layout.preferredHeight: Settings.barHeight
    Layout.rightMargin: 0
    popupWidth: 430
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    Item {
        width: 30
        height: parent.height
        UI.Icon {
            anchors.centerIn: parent
            size: Design.iconLarge
            text: NetworkState.icon
            color: NetworkState.vpnActive ? Design.accent : NetworkState.connected ? Design.text : Design.textMuted
        }
    }
    popupContent: NetworkCenter {
        active: root.dropdownOpen
        maximumHeight: Math.min(650, (root.barWindow?.screen?.height || 800) - 110)
        onDismissed: root.dropdownOpen = false
    }
}
