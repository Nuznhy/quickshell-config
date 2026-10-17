pragma ComponentBehavior: Bound
import QtQuick
import qs.components.ui as UI
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components.popup
import qs.modules.bluetooth
import qs.services.bluetooth

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
        UI.Text {
            role: "bar"
            anchors.centerIn: parent
            text: !BluetoothState.enabled ? "󰂲" : BluetoothState.connectedDevices.length > 0 ? "󰂱" : "󰂯"
            color: BluetoothState.connectedDevices.length > 0 ? Design.accent : BluetoothState.enabled ? Design.text : Design.textMuted
            font.family: Design.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.9)
        }
    }
    popupContent: BluetoothCenter {
        active: root.dropdownOpen
        maximumHeight: Math.min(650, (root.barWindow?.screen?.height || 800) - 110)
        onDismissed: root.dropdownOpen = false
    }
}
