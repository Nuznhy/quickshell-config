pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root
    property var targets: []
    property bool ready: false
    property bool syncPending: false
    property bool discoverPending: false
    property var pending: ({})
    property var request: ({})
    property string errorMessage: ""
    readonly property bool busy: worker.running
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/app-themes.py").toString().replace(/^file:\/\//, ""))

    function refresh() {
        discoverPending = true;
        pump();
    }
    function setEnabled(id, enabled) {
        const next = Object.assign({}, pending);
        next[id] = { action: "set", target: id, enabled: enabled };
        pending = next;
        pump();
    }
    function retry(id) {
        const next = Object.assign({}, pending);
        next[id] = { action: "retry", target: id };
        pending = next;
        pump();
    }
    function scheduleSync() {
        syncPending = true;
        debounce.restart();
    }
    function isApplying(id) {
        return Object.prototype.hasOwnProperty.call(pending, id)
            || (busy && (request.target === id || (request.action === "sync" && targets.some(t => t.id === id && t.enabled))));
    }
    function pump() {
        if (busy || !Theme.ready) return;
        let next;
        const ids = Object.keys(pending);
        if (ids.length) {
            next = pending[ids[0]];
            const remaining = Object.assign({}, pending);
            delete remaining[ids[0]];
            pending = remaining;
        } else if (syncPending && !debounce.running) {
            syncPending = false;
            next = { action: "sync" };
        } else if (discoverPending || !ready) {
            discoverPending = false;
            next = { action: "discover" };
        } else return;
        request = Object.assign({}, next, { palette: Theme.palette, mode: Theme.mode, lockScreen: Theme.lockScreen });
        errorMessage = "";
        worker.running = true;
    }
    Component.onCompleted: refresh()
    Connections {
        target: Theme
        function onReadyChanged() { if (Theme.ready) root.refresh(); }
        function onPaletteChanged() { if (root.ready) root.scheduleSync(); }
        function onLockScreenChanged() {
            // A queued toggle will read the latest options when it starts. Never
            // replace that toggle with a retry; also catch edits during enabling.
            if (!root.ready || root.pending.hyprlock?.action === "set") return;
            if (root.targets.some(t => t.id === "hyprlock" && t.enabled)
                    || (root.busy && root.request.target === "hyprlock" && root.request.enabled === true))
                root.retry("hyprlock");
        }
    }
    Timer { id: debounce; interval: 250; onTriggered: root.pump() }
    Process {
        id: worker
        command: ["python3", root.helper, "--state", Quickshell.statePath("app-themes")]
        stdinEnabled: true
        onStarted: {
            write(JSON.stringify(root.request));
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = JSON.parse(text);
                    root.errorMessage = response.error || "";
                    if (response.targets) {
                        root.targets = response.targets;
                        if (!root.ready) {
                            root.ready = true;
                            root.scheduleSync();
                        }
                    }
                } catch (error) { root.errorMessage = "Could not read application theme status."; }
            }
        }
        stderr: StdioCollector { id: errors }
        onExited: code => {
            stdinEnabled = true;
            if (code !== 0 && !root.errorMessage)
                root.errorMessage = errors.text.trim() || "Application theming failed.";
            // A broken recovery file must not cause an endless startup retry.
            if (code !== 0 && !root.ready) root.ready = true;
            Qt.callLater(root.pump);
        }
    }
}
