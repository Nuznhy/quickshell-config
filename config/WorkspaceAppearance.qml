pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "WorkspaceAppearanceData.js" as Data

Singleton {
    id: root
    property bool ready: false
    property var state: Data.defaults()
    property string errorMessage: ""
    readonly property bool showIcons: state.showIcons
    readonly property string iconStyle: state.iconStyle
    readonly property string separator: state.separator
    readonly property bool capsule: state.capsule

    function setOption(key, value) {
        if (!ready || !["showIcons", "iconStyle", "separator", "capsule"].includes(key)) return;
        state = Data.normalize(Object.assign({}, state, {[key]: value}));
        saveTimer.restart();
    }
    function reset() {
        if (!ready) return;
        state = Data.defaults();
        saveTimer.restart();
    }
    Timer { id: saveTimer; interval: 250; onTriggered: file.setText(JSON.stringify(root.state, null, 2) + "\n") }
    FileView {
        id: file
        path: Quickshell.statePath("workspace-appearance.json")
        printErrors: false
        onLoaded: {
            if (root.ready) return;
            try { root.state = Data.normalize(JSON.parse(text())); }
            catch (error) { root.errorMessage = "Could not read workspace settings. Defaults restored."; }
            root.ready = true;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) root.errorMessage = "Could not read workspace settings.";
            root.ready = true;
        }
        onSaved: root.errorMessage = ""
        onSaveFailed: root.errorMessage = "Workspace settings applied, but could not save them."
    }
}
