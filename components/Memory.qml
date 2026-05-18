import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Text {
    id: memWidget

    property int memUsage: 0

    text: memUsage + "% 󰾆"
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memWidget.memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: memProc.running = true
    }
}
