pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int openPanels: 0
    property var details: ({})
    property string errorMessage: ""
    property int updateCount: -1
    property string updateError: ""
    property double checkedAt: 0
    property double attemptedAt: 0
    readonly property bool checkingUpdates: updateProcess.running
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/system-info.py").toString().replace(/^file:\/\//, ""))
    function refresh() {
        if (!infoProcess.running) infoProcess.running = true;
        if (Date.now() - attemptedAt > 1800000) checkUpdates();
    }
    function checkUpdates() {
        if (checkingUpdates) return;
        attemptedAt = Date.now();
        updateError = "";
        updateProcess.running = true;
    }
    onOpenPanelsChanged: { if (openPanels > 0) refresh(); }
    Process {
        id: infoProcess
        command: ["python3", root.helper]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.details = JSON.parse(text); root.errorMessage = root.details.error || ""; }
                catch (error) { root.errorMessage = "Could not read system information."; }
            }
        }
        stderr: StdioCollector {}
    }
    Process {
        id: updateProcess
        command: ["python3", root.helper, "updates"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.updateError = data.error || "";
                    if (Number.isInteger(data.count)) {
                        root.updateCount = data.count;
                        root.checkedAt = Date.now();
                    }
                } catch (error) { root.updateError = "Could not read pending updates."; }
            }
        }
        stderr: StdioCollector {}
        onExited: code => { if (code !== 0) root.updateError = root.updateError || "Could not check repository updates."; }
    }
    Timer { interval: 30000; repeat: true; running: root.openPanels > 0; onTriggered: root.refresh(); }
}
