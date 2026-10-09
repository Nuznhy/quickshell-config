import QtQuick
import "../../../components/ui" as UI
import QtQuick.Layouts
import Quickshell
import "../../../config"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    Layout.preferredHeight: Settings.barHeight
    Layout.rightMargin: 0
    popupWidth: 390
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    Item {
        width: 24
        height: parent.height
        UI.Text {
            role: "bar"
            anchors.centerIn: parent
            text: "󰃠"
            color: Design.text
            font.family: Design.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.9)
        }
    }
    popupContent: BrightnessCenter {
        active: root.dropdownOpen
        maximumHeight: Math.min(600, (root.barWindow?.screen?.height || 800) - 110)
        onDismissed: root.dropdownOpen = false
    }
}
