pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../../config"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    popupWidth: 340
    sizeToContent: true
    showStem: false
    stemAlignment: "right"

    Text {
        height: parent.height
        width: 30
        text: "󰏘"
        color: root.dropdownOpen ? Theme.iris : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    popupContent: ThemePicker {
        onDismissed: root.dropdownOpen = false
    }
}
