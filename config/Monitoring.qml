pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool ready: false
    property var modes: ({ "cpu.load": "long", "ram.usage": "long" })
    property string cpuSensor: ""
    property string errorMessage: ""
    function mode(id) { return modes[id] || "off"; }
    function setMode(id, value) {
        if (!ready || !["off", "short", "long"].includes(value)) return;
        const next = Object.assign({}, modes);
        next[id] = value;
        modes = next;
        saveTimer.restart();
    }
    function setCpuSensor(value) {
        if (!ready) return;
        cpuSensor = value;
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 250
        onTriggered: file.setText(JSON.stringify({version: 1, modes: root.modes, cpuSensor: root.cpuSensor}, null, 2) + "\n")
    }
    FileView {
        id: file
        path: Quickshell.statePath("monitoring.json")
        printErrors: false
        onLoaded: {
            if (root.ready) return;
            try {
                const state = JSON.parse(text());
                if (state.version !== 1 || !state.modes || typeof state.modes !== "object" || Array.isArray(state.modes))
                    throw new Error("Invalid monitoring settings");
                const modes = {};
                Object.keys(state.modes).forEach(id => {
                    if (["off", "short", "long"].includes(state.modes[id])) modes[id] = state.modes[id];
                });
                root.modes = modes;
                root.cpuSensor = typeof state.cpuSensor === "string" ? state.cpuSensor : "";
            } catch (error) { root.errorMessage = "Could not read monitoring settings. Defaults restored."; }
            root.ready = true;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) root.errorMessage = "Could not read monitoring settings.";
            root.ready = true;
        }
        onSaved: root.errorMessage = ""
        onSaveFailed: root.errorMessage = "Monitoring settings applied, but could not save them."
    }
}
