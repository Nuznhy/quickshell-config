import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Text {
    id: cpuWidget

    property int cpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    text: cpuUsage + "% 󰍛"
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait

                if (cpuWidget.lastCpuTotal > 0) {
                    var totalDiff = total - cpuWidget.lastCpuTotal
                    var idleDiff = idleTime - cpuWidget.lastCpuIdle
                    if (totalDiff > 0) {
                        cpuWidget.cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                cpuWidget.lastCpuTotal = total
                cpuWidget.lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: cpuProc.running = true
    }
}
