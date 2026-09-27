pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var displays: []
    property string errorMessage: ""
    property string statusError: ""
    property int openPanels: 0
    property var pending: ({})
    property bool refreshAgain: false
    readonly property bool loading: statusProc.running
    readonly property bool changing: actionProc.running || Object.keys(pending).length > 0
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/brightness.py").toString().replace(/^file:\/\//, ""))
    onOpenPanelsChanged: { if (openPanels > 0) refresh(); }

    Component {
        id: displayEntry
        QtObject {
            property string deviceId
            property string name
            property string connection
            property bool supported
            property real value
            property string error
        }
    }
    function applySnapshot(snapshot) {
        const previous = displays;
        const next = snapshot.map(data => {
            const entry = previous.find(item => item.deviceId === data.id) || displayEntry.createObject(root);
            entry.deviceId = data.id;
            entry.name = data.name;
            entry.connection = data.connection;
            entry.supported = data.supported;
            entry.error = data.error || "";
            entry.value = Object.prototype.hasOwnProperty.call(pending, data.id) ? pending[data.id] : data.value;
            return entry;
        });
        if (previous.length !== next.length || previous.some((entry, i) => entry !== next[i])) displays = next;
        previous.forEach(entry => { if (!next.includes(entry)) entry.destroy(); });
    }

    function refresh() {
        if (statusProc.running || changing) { refreshAgain = true; return; }
        refreshAgain = false;
        statusProc.running = true;
    }
    function setBrightness(id, value) {
        if (!displays.some(display => display.deviceId === id && display.supported)) return;
        value = Math.max(0, Math.min(100, Math.round(value)));
        const next = Object.assign({}, pending);
        next[id] = value;
        pending = next;
        // Keep every screen's slider at the requested level while writes settle.
        displays.find(display => display.deviceId === id).value = value;
        errorMessage = "";
        writeNext();
    }
    function writeNext() {
        if (actionProc.running || statusProc.running) return;
        const ids = Object.keys(pending);
        if (!ids.length) { refresh(); return; }
        const id = ids[0];
        const next = Object.assign({}, pending);
        actionProc.command = ["python3", helper, "set", id, String(next[id])];
        delete next[id];
        pending = next;
        actionProc.running = true;
    }
    Process {
        id: statusProc
        command: ["python3", root.helper]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    root.statusError = result.error || "";
                    if (result.displays) root.applySnapshot(result.displays);
                } catch (error) { root.statusError = "Could not read monitor brightness."; }
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0) root.statusError = root.statusError || "Brightness discovery failed.";
            if (Object.keys(root.pending).length) Qt.callLater(root.writeNext);
            else if (root.refreshAgain) Qt.callLater(root.refresh);
        }
    }
    Process {
        id: actionProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { const result = JSON.parse(text); if (result.error) root.errorMessage = result.error; }
                catch (error) { root.errorMessage = "Could not change monitor brightness."; }
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0 && !root.errorMessage) root.errorMessage = "Brightness adjustment failed. Check device permissions.";
            Qt.callLater(root.writeNext);
        }
    }
    Timer {
        interval: 15000
        repeat: true
        running: root.openPanels > 0
        onTriggered: root.refresh()
    }
}
