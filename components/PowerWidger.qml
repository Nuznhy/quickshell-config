import QtQuick
import QtQuick.Controls
import Quickshell.Io
import ".."

Item {
    width: 30
    height: 30

    // 1. The Icon
    Text {
        anchors.centerIn: parent
        text: ""
        // Ensure you specify your Nerd Font so the icon renders correctly
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.love
    }

    // 3. The Click Handler
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true // Required for the ToolTip to show on hover
        onClicked: {
            logoutCommand.running = true
        }
        
        // Optional: Add visual feedback when pressed
        opacity: pressed ? 0.7 : 1.0 
    }

    // 4. The Execution Process
    Process {
        id: logoutCommand
        // Wrapping in sh -c ensures the tilde (~) expands to your home directory properly
        command: ["sh", "-c", "~/.config/hypr/scripts/logoutlaunch.sh 2"]
    }
}
