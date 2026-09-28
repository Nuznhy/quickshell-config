pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "BarLayoutData.js" as Data

Singleton {
    id: root
    property var state: Data.defaults()
    property bool ready: false
    property string errorMessage: ""
    readonly property var registry: Data.widgets
    signal aboutToChange

    function ids(section) { return state.sections[section] || []; }
    function isEnabled(id) { return !state.disabled.includes(id); }
    function entry(id) { return Data.widget(id); }
    function commit(next) {
        if (!ready || (!errorMessage && JSON.stringify(next) === JSON.stringify(state))) return;
        aboutToChange();
        state = next;
        errorMessage = "";
        saveTimer.restart();
    }
    function move(id, section, index) { commit(Data.move(state, id, section, index)); }
    function setEnabled(id, enabled) { commit(Data.setEnabled(state, id, enabled)); }
    function reset() { commit(Data.defaults()); }
    function save() { file.setText(JSON.stringify(state, null, 2) + "\n"); }

    Timer { id: saveTimer; interval: 250; onTriggered: root.save() }
    FileView {
        id: file
        path: Quickshell.statePath("bar-layout.json")
        printErrors: false
        onLoaded: {
            if (root.ready) return;
            try { root.state = Data.normalize(JSON.parse(text())); }
            catch (error) { root.errorMessage = "Could not read the bar layout. Default layout restored."; }
            root.ready = true;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                root.errorMessage = "Could not read the saved bar layout.";
            root.ready = true;
        }
        onSaved: root.errorMessage = ""
        onSaveFailed: error => root.errorMessage = "Layout applied, but could not save it."
    }
}
