pragma ComponentBehavior: Bound
import QtQuick
import "../../../components/ui" as UI
import Quickshell
import "../../../config"
import "../../../services"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    implicitWidth: clockLabel.implicitWidth + 24
    implicitHeight: Settings.barHeight
    popupWidth: CalendarFeed.enabled ? Math.min(720, (root.barWindow?.screen?.width || 1920) - 32) : 352
    sizeToContent: true
    showStem: false

    UI.Text {
        role: "bar"
        id: clockLabel
        height: parent.height
        text: Theme.verticalBar ? Qt.formatDateTime(Time.date, "hh\nmm") : Time.time
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.dropdownOpen ? Design.accent : Design.text
        font.pixelSize: Theme.fontSize - 2
        font.family: Theme.barFontFamily
        font.bold: true
    }

    popupContent: CalendarPanel {
        today: Time.date
        active: root.dropdownOpen
        onDismissed: root.dropdownOpen = false
    }
}
