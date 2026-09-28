import QtQuick
import Quickshell
import "../../../config"
import "../../../services"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    popupWidth: 330
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    Item {
        width: 30
        height: parent.height
        SettingsIcon {
            anchors.centerIn: parent
            color: root.dropdownOpen || ShellSettings.opened ? Theme.iris : Theme.text
        }
    }
    popupContent: QuickSettings {
        active: root.dropdownOpen
        onSettingsRequested: {
            root.dropdownOpen = false;
            Qt.callLater(ShellSettings.open);
        }
    }
}
