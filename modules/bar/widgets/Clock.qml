pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../config"
import "../../../services"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    implicitWidth: clockLabel.implicitWidth + 24
    implicitHeight: Settings.barHeight
    popupWidth: 352
    sizeToContent: true
    showStem: false

    Text {
        id: clockLabel
        height: parent.height
        text: Theme.verticalBar ? Qt.formatDateTime(Time.date, "hh\nmm") : Time.time
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.dropdownOpen ? Theme.iris : Theme.text
        font.pixelSize: Theme.fontSize - 2
        font.family: Theme.fontFamily
        font.bold: true
    }

    popupContent: CalendarPanel {
        today: Time.date
        active: root.dropdownOpen
        onDismissed: root.dropdownOpen = false
    }
}
