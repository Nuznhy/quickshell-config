import QtQuick
import Quickshell
import qs.config
import qs.services.settings
import qs.components.popup
import qs.modules.quicksettings
import qs.modules.appearance

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
            color: root.dropdownOpen || ShellSettings.opened ? Design.accent : Design.text
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
