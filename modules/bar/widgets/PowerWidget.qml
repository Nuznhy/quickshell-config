import QtQuick
import "../../../components/ui" as UI
import Quickshell
import Quickshell.Io
import "../../../config"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    popupWidth: 290
    sizeToContent: true
    showStem: false
    stemAlignment: "right"
    property string errorMessage: ""
    UI.Text {
        role: "bar"
        width: 30
        height: Settings.barHeight
        text: ""
        font.family: Design.fontFamily
        font.pixelSize: Theme.fontSize
        color: Design.danger
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    popupContent: PowerMenu {
        active: root.dropdownOpen
        busy: action.running
        errorMessage: root.errorMessage
        onActionRequested: requested => {
            if (action.running) return;
            root.errorMessage = "";
            root.dropdownOpen = false;
            action.command = ["python3", decodeURIComponent(Qt.resolvedUrl("../../../scripts/power-action.py").toString().replace(/^file:\/\//, "")), requested];
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
