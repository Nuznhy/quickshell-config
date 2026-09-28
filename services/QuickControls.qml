pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int openPanels: 0
    property string hostname: ""
    property string osName: ""
    property string uptime: ""
    property bool available: false
    property bool nightEnabled: false
    property string errorMessage: ""
    property string settingsError: ""
    property bool ready: false
    property int strength: 50
    readonly property int temperature: 6500 - strength * 50
    property string pendingAction: ""
    readonly property bool busy: worker.running
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/quick-controls.py").toString().replace(/^file:\/\//, ""))

    function refresh() { if (!busy && !pendingAction && !applyTimer.running) run("status"); }
    function toggleNightShift() {
        if (!available || !ready) return;
        applyTimer.stop();
        pendingAction = nightEnabled ? "off" : "on";
        flush();
    }
    function setStrength(value) {
        if (!ready || !Number.isFinite(value)) return;
        strength = Math.max(0, Math.min(100, Math.round(value)));
        saveTimer.restart();
        if (available && nightEnabled) {
            if (!pendingAction || pendingAction === "adjust") pendingAction = "adjust";
            // Throttle continuous dragging while retaining the latest value.
            if (!applyTimer.running) applyTimer.start();
        }
    }
    function flush() {
        if (busy || !pendingAction) return;
        const action = pendingAction;
        pendingAction = "";
        run(action);
    }
    function run(action) {
        if (busy) return;
        worker.command = ["python3", helper, action, "--temperature", String(temperature)];
        worker.running = true;
    }
    Timer { id: applyTimer; interval: 150; onTriggered: root.flush(); }
    Timer {
        id: saveTimer
        interval: 250
        onTriggered: settingsFile.setText(JSON.stringify({version: 1, strength: root.strength}) + "\n")
    }
    FileView {
        id: settingsFile
        path: Quickshell.statePath("quick-controls.json")
        printErrors: false
        onLoaded: {
            if (root.ready) return;
            try {
                const state = JSON.parse(text());
                if (state.version !== 1 || !Number.isInteger(state.strength) || state.strength < 0 || state.strength > 100)
                    throw new Error("Invalid Night Shift strength");
                root.strength = state.strength;
            } catch (error) { root.settingsError = "Could not read Night Shift temperature. Using 4000 K."; }
            root.ready = true;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) root.settingsError = "Could not read Night Shift temperature.";
            root.ready = true;
        }
        onSaved: root.settingsError = ""
        onSaveFailed: root.settingsError = "Night Shift temperature applied, but could not save it."
    }
    onOpenPanelsChanged: { if (openPanels > 0) refresh(); }
    Process {
        id: worker
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const state = JSON.parse(text);
                    root.hostname = state.hostname || "";
                    root.osName = state.osName || "";
                    root.uptime = state.uptime || "";
                    root.available = !!state.available;
                    root.nightEnabled = !!state.enabled;
                    root.errorMessage = state.error || "";
                } catch (error) { root.errorMessage = "Could not read quick controls."; }
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0) root.errorMessage = root.errorMessage || "Could not change Night Shift.";
            if (!applyTimer.running) Qt.callLater(root.flush);
        }
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.openPanels > 0
        onTriggered: root.refresh()
    }
}
