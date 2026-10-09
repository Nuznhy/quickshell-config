import QtQuick
import "../../../components/ui" as UI
import QtQuick.Layouts
import Quickshell
import "../../../config"
import "../../../services"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    visible: BatteryState.present
    implicitWidth: cells.implicitWidth
    implicitHeight: Theme.verticalBar ? cells.implicitHeight : Settings.barHeight
    Layout.preferredHeight: implicitHeight
    popupWidth: 360
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    // Allow the authentication agent to receive focus while applying a limit.
    focusGrabEnabled: !BatteryState.changing
    popupDismissEnabled: !BatteryState.changing
    onVisibleChanged: { if (!visible) dropdownOpen = false; }
    UI.GridLayout {
        id: cells
        anchors.verticalCenter: parent.verticalCenter
        columns: Theme.verticalBar ? 1 : 2
        rowSpacing: Design.space4
        columnSpacing: Design.space4
        UI.Text {
            role: "bar"
            Layout.alignment: Qt.AlignCenter
            text: BatteryState.icon
            color: BatteryState.percent >= 0 && BatteryState.percent <= 15 && !BatteryState.charging ? Design.danger : Design.text
            font.family: Design.fontFamily
            font.pixelSize: Theme.fontSize
        }
        UI.Text {
            role: "bar"
            Layout.alignment: Qt.AlignCenter
            text: BatteryState.percent < 0 ? "—" : Math.round(BatteryState.percent) + "%"
            color: Design.text
            font.family: Theme.barFontFamily
            font.pixelSize: Theme.verticalBar ? Math.min(12, Theme.fontSize) : Theme.fontSize
        }
    }
    popupContent: BatteryCenter {
        active: root.dropdownOpen
        maximumHeight: Math.max(100, Math.min(600, (root.barWindow?.screen?.height || 800) - 110))
        onDismissed: root.dropdownOpen = false
    }
}
