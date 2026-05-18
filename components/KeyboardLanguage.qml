import QtQuick
import Quickshell.Io
import ".."

Text {
    id: langWidget

    // State properties
    property string layoutName: "en" 
    property string kbName: "keychron--keychron-link--keyboard"

    // Waybar "format", "align", and "justify" equivalents
    text: "  " + layoutName
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    
    // Rosé Pine Styling
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily

    // Click to change language
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            switchProc.running = true
            // Refresh the text slightly after Hyprland switches it
            refreshTimer.start() 
        }
    }

    // 1. Process to SWITCH the layout
    Process {
        id: switchProc
        command: ["hyprctl", "switchxkblayout", langWidget.kbName, "next"]
    }

    // 2. Process to FETCH the current layout
    Process {
        id: fetchProc
        // Uses jq to find your specific keyboard and grab its active keymap
        command: [
            "sh", "-c", 
            "hyprctl devices -j | jq -r '.keyboards[] | select(.name == \"" + langWidget.kbName + "\") | .active_keymap'"
        ]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                let keymap = data.toLowerCase()
                
                // Waybar "format-en" and "format-uk" logic
                if (keymap.includes("ukrainian") || keymap.includes("uk")) {
                    langWidget.layoutName = "ua"
                } else if (keymap.includes("english") || keymap.includes("us")) {
                    langWidget.layoutName = "en"
                } else {
                    // Fallback just in case
                    langWidget.layoutName = data.substring(0, 2) 
                }
            }
        }
        Component.onCompleted: running = true
    }

    // 3. Polling Timer (Checks for layout changes made via keyboard shortcuts)
    Timer {
        interval: 50// Checks every 1 second
        running: true
        repeat: true
        onTriggered: fetchProc.running = true
    }

    // 4. Quick Refresh Timer (For instant UI updates when clicking the widget)
    Timer {
        id: refreshTimer
        interval: 50 // Wait 50ms for Hyprland to process the switch
        repeat: false
        onTriggered: fetchProc.running = true
    }
}
