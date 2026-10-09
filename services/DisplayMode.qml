pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root
    property bool available: false
    property bool mirrored: false
    property string reason: "Checking connected displays…"
    property string errorMessage: ""
    property string laptop: ""
    property var outputs: []
    property bool requestPending: false
    readonly property bool busy: requestPending || worker.running
    readonly property bool changing: busy && worker.action !== "status"
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/display-mode.py").toString().replace(/^file:\/\//, ""))

    function run(action) {
        if (busy) return;
        requestPending = true;
        worker.action = action;
        worker.command = ["python3", helper, action];
        worker.running = true;
    }
    function toggle() {
        if (!available || busy) return;
        errorMessage = "";
        run("toggle");
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
                    root.mirrored = !!state.mirrored;
                    root.reason = state.reason || "";
                    root.laptop = state.laptop || "";
                    root.outputs = state.outputs || [];
                    if (state.error || worker.action === "toggle") root.errorMessage = state.error || "";
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
