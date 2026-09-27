pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../config"

Singleton {
    id: root
    property string layoutName: "en"
    property string kbName: ""
    property int eventRevision: 0

    function setLayout(name) {
        const layout = name.toLowerCase();
        if (layout.includes("ukrainian")) layoutName = "ua";
        else if (layout.includes("english")) layoutName = "en";
        else layoutName = name.substring(0, 2);
    }

    function handleLayoutEvent(data) {
        const separator = data.indexOf(",");
        if (separator < 1) return;
        const keyboard = data.substring(0, separator);
        const layout = data.substring(separator + 1);
        if (!layout || (Settings.keyboardName && keyboard !== Settings.keyboardName)) return;
        eventRevision++;
        kbName = keyboard;
        setLayout(layout);
    }

    function applyDevices(devices) {
        const keyboards = devices.keyboards || [];
        const preferred = Settings.keyboardName || kbName;
        const keyboard = keyboards.find(kb => kb.name === preferred)
            || keyboards.find(kb => kb.main)
            || keyboards[0];
        if (!keyboard) {
            kbName = "";
            layoutName = "--";
            return;
        }
        kbName = keyboard.name;
        setLayout(keyboard.active_keymap || "--");
    }

    function refresh() {
        if (fetchProc.running) return;
        fetchProc.revision = eventRevision;
        fetchProc.running = true;
    }

    function nextLayout() {
        if (kbName && !switchProc.running) switchProc.running = true;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") root.handleLayoutEvent(event.data);
        }
    }

    Process {
        id: switchProc
        command: ["hyprctl", "switchxkblayout", root.kbName, "next"]
        onExited: root.refresh()
    }

    Process {
        id: fetchProc
        property int revision: 0
        command: ["hyprctl", "devices", "-j"]
        Component.onCompleted: root.refresh()
        stdout: StdioCollector {
            onStreamFinished: {
                // A snapshot started before an event must not overwrite the newer layout.
                if (fetchProc.revision !== root.eventRevision) return;
                try {
                    root.applyDevices(JSON.parse(text));
                } catch (error) {
                    console.warn("Could not read keyboard layouts:", error);
                }
            }
        }
    }

    Timer {
        interval: Settings.keyboardInterval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
