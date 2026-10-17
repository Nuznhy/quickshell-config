pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config as ConfigScripts

Singleton {
    id: root
    property var state: ConfigScripts.BarLayoutData.defaults()
    property bool ready: false
    property string errorMessage: ""
    readonly property var registry: ConfigScripts.BarLayoutData.widgets
    signal aboutToChange

    function ids(section) {
        return state.sections[section] || [];
    }
    function isEnabled(id) {
        return !state.disabled.includes(id);
    }
    function entry(id) {
        return ConfigScripts.BarLayoutData.widget(id);
    }
    function commit(next) {
        if (!ready || (!errorMessage && JSON.stringify(next) === JSON.stringify(state)))
            return;
        aboutToChange();
        state = next;
        errorMessage = "";
        saveTimer.restart();
    }
    function move(id, section, index) {
        commit(ConfigScripts.BarLayoutData.move(state, id, section, index));
    }
    function setEnabled(id, enabled) {
        commit(ConfigScripts.BarLayoutData.setEnabled(state, id, enabled));
    }
    function reset() {
        commit(ConfigScripts.BarLayoutData.defaults());
    }
    function save() {
        file.setText(JSON.stringify(state, null, 2) + "\n");
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.save()
    }
    FileView {
        id: file
        path: Quickshell.statePath("bar-layout.json")
        printErrors: false
        onLoaded: {
            if (root.ready)
                return;
            try {
                root.state = ConfigScripts.BarLayoutData.normalize(JSON.parse(text()));
            } catch (error) {
                root.errorMessage = "Could not read the bar layout. Default layout restored.";
            }
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
