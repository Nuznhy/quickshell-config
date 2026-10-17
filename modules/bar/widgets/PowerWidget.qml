import QtQuick
import qs.components.ui as UI
import Quickshell
import Quickshell.Io
import qs.config
import qs.components.popup
import qs.modules.power

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    popupWidth: 290
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    property string errorMessage: ""
    UI.Icon {
        width: 30
        height: Settings.barHeight
        size: Theme.fontSize
        text: ""
        color: Design.danger
    }
    popupContent: PowerMenu {
        active: root.dropdownOpen
        busy: action.running
        errorMessage: root.errorMessage
        onActionRequested: requested => {
            if (action.running) return;
            root.errorMessage = "";
            root.dropdownOpen = false;
            action.command = ["python3", Quickshell.shellPath("scripts/power/power-action.py"), requested];
            action.running = true;
        }
    }
    Process {
        id: action
        stdout: StdioCollector {}
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (code !== 0) {
                root.errorMessage = errors.text.trim() || "Power action failed.";
                root.dropdownOpen = true;
            }
        }
    }
}
