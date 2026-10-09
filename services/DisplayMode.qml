pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root
    property bool available: false
    property string mode: "unavailable"
    property bool pending: false
    property string reason: "Checking display layout…"
    property string errorMessage: ""
    property bool requestPending: false
    readonly property bool busy: requestPending || worker.running || mode === "transition"
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/display-mode.py").toString().replace(/^file:\/\//, ""))

    function run(action) {
        if (requestPending || worker.running) return;
        requestPending = true;
        worker.action = action;
        worker.command = ["python3", helper, action];
        worker.running = true;
    }
    function toggle() {
        if (!available || busy) return;
        errorMessage = "";
        run(pending ? "confirm" : "toggle");
    }
    Component.onCompleted: run("status")
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "configreloaded"].includes(event.name))
                refreshTimer.restart();
        }
    }
    Timer { id: refreshTimer; interval: 500; onTriggered: root.run("status") }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: root.run("status") }
    Process {
        id: worker
        property string action: "status"
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text);
                    root.available = !!state.available;
                    root.mode = state.mode || "unavailable";
                    root.pending = !!state.pending;
                    root.reason = state.reason || "";
                    if (state.error || worker.action !== "status") root.errorMessage = state.error || "";
                } catch (error) {
                    root.available = false;
                    root.errorMessage = "Could not read display mode.";
                }
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            root.requestPending = false;
            if (code !== 0) root.errorMessage = "Display mode helper failed.";
        }
    }
}
