pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // The only persisted data is this opt-in. The private URL belongs to the keyring.
    property bool enabled: false
    property bool ready: false
    readonly property bool busy: writer.running
    property string message: ""
    property bool failed: false
    property string pendingUrl: ""
    property string operation: ""
    property var result: null
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/ical-calendar.py").toString().replace(/^file:\/\//, ""))
    function save(url) {
        if (busy || !ready) return false;
        pendingUrl = url;
        run("store");
        return true;
    }
    function forget() {
        if (busy || !ready) return;
        run("forget");
    }
    function run(action) {
        operation = action;
        result = null;
        message = "";
        failed = false;
        writer.stdinEnabled = true;
        writer.running = true;
    }
    Process {
        id: writer
        command: ["python3", root.helper, "manage"]
        onStarted: {
            write(JSON.stringify({action: root.operation, url: root.pendingUrl}));
            root.pendingUrl = "";
            stdinEnabled = false;
        }
        stdout: SplitParser {
            onRead: data => {
                try { root.result = JSON.parse(data); }
                catch (error) { root.result = null; }
            }
        }
        stderr: SplitParser { onRead: data => {} }
        onExited: code => {
            root.pendingUrl = "";
            const success = code === 0 && root.result && root.result.ok === true;
            root.failed = !success;
            if (success) {
                root.enabled = root.operation === "store";
                root.message = root.enabled ? "Feed saved securely in your keyring." : "Saved feed removed. Its address remains valid at the provider until you revoke it.";
            } else {
                root.message = (root.result && root.result.error) || "Could not update the feed. Unlock your keyring and try again.";
            }
            root.result = null;
        }
    }
    Timer {
        interval: 90000
        running: writer.running
        onTriggered: {
            root.result = {ok: false, error: "Keyring request timed out. Unlock your keyring and try again."};
            writer.signal(9);
        }
    }
    onEnabledChanged: { if (ready) preferences.setText(JSON.stringify({enabled: enabled})); }
    FileView {
        id: preferences
        path: Quickshell.statePath("calendar-feed.json")
        onLoaded: {
            try { root.enabled = JSON.parse(text()).enabled === true; }
            catch (error) { root.enabled = false; }
            root.ready = true;
        }
        onLoadFailed: root.ready = true
    }
}
