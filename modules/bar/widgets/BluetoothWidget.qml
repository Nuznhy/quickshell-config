pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../config"
import "../../../components"
import "../../../services"

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
        width: 24
        height: parent.height
        Text {
            anchors.centerIn: parent
            text: !BluetoothState.enabled ? "󰂲" : BluetoothState.connectedDevices.length > 0 ? "󰂱" : "󰂯"
            color: BluetoothState.connectedDevices.length > 0 ? Theme.iris : BluetoothState.enabled ? Theme.text : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.9)
        }
    }
    popupContent: BluetoothCenter {
        active: root.dropdownOpen
        maximumHeight: Math.min(650, (root.barWindow?.screen?.height || 800) - 110)
        onDismissed: root.dropdownOpen = false
    }
}
