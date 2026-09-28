pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root
    property var batteries: []
    property int openPanels: 0
    property string errorMessage: ""
    property string message: ""
    readonly property bool changing: action.running
    readonly property bool present: batteries.length > 0
    readonly property bool charging: batteries.some(b => b.status === "Charging")
    readonly property real percent: {
        const known = batteries.filter(b => b.percent !== null);
        if (!known.length) return -1;
        if (known.every(b => b.unit === "Wh" && b.full > 0))
            return known.reduce((sum, b) => sum + b.percent * b.full, 0) / known.reduce((sum, b) => sum + b.full, 0);
        return known.reduce((sum, b) => sum + b.percent, 0) / known.length;
    }
    readonly property string icon: charging ? "󰂄" : percent < 0 ? "󰂑" : percent <= 15 ? "󰁺" : percent <= 35 ? "󰁼" : percent <= 60 ? "󰁿" : percent <= 85 ? "󰂁" : "󰁹"
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/battery.py").toString().replace(/^file:\/\//, ""))
    function refresh() { if (!status.running && !changing) status.running = true; }
    function setLimit(id, value) {
        if (changing) return;
        errorMessage = "";
        message = "";
        action.command = ["python3", helper, "set", id, String(Math.round(value))];
        action.running = true;
    }
    function accept(text, mutation) {
        try {
            const data = JSON.parse(text);
            if (JSON.stringify(batteries) !== JSON.stringify(data.batteries || [])) batteries = data.batteries || [];
            if (mutation) {
                errorMessage = data.error || "";
                message = data.message || "";
            }
        } catch (error) { errorMessage = "Could not read battery information."; }
    }
    onOpenPanelsChanged: { if (openPanels > 0) refresh(); }
    Component.onCompleted: refresh()
    Process {
        id: status
        command: ["python3", root.helper]
        stdout: StdioCollector { onStreamFinished: { if (!root.changing) root.accept(text, false); } }
        stderr: StdioCollector {}
    }
    Process {
        id: action
        stdout: StdioCollector { onStreamFinished: root.accept(text, true) }
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0) root.errorMessage = root.errorMessage || "Could not apply the battery charge limit.";
            Qt.callLater(root.refresh);
        }
    }
    Timer {
        interval: root.openPanels > 0 ? 10000 : 30000
        running: root.openPanels > 0 || (BarLayout.ready && BarLayout.isEnabled("battery"))
        repeat: true
        onTriggered: root.refresh()
    }
}
