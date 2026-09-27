pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../config"

Singleton {
    id: root
    // Store windows per workspace
    property var workspaceIcons: ({})

    function getWsIcons(wsId) {
        return workspaceIcons[wsId] || "";
    }

    // Process to get window list
    Process {
        id: windowsProc
        property string output: ""
        command: ["sh", "-c", "hyprctl clients -j | jq -r '.[] | select(.workspace.id > 0 and .workspace.id <= 9) | \"\\(.workspace.id):\\(.class)\"'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    windowsProc.output += data.trim() + "\n";
                }
            }
        }
        onRunningChanged: {
            if (running) {
                output = "";
            } else {
                var wsIcons = {};
                var lines = output.trim().split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(':');
                    if (parts.length >= 2) {
                        var wsId = parseInt(parts[0]);
                        var windowClass = parts.slice(1).join(':');
                        if (wsId > 0 && wsId <= 9) {
                            if (!wsIcons[wsId])
                                wsIcons[wsId] = {
                                    icons: [],
                                    seen: {}
                                };
                            var icon = Icons.getWindowIcon(windowClass);
                            if (!wsIcons[wsId].seen[icon]) {
                                wsIcons[wsId].seen[icon] = true;
                                wsIcons[wsId].icons.push(icon);
                            }
                        }
                    }
                }
                var icons = {};
                for (var id in wsIcons)
                    icons[id] = wsIcons[id].icons.slice(0, 3).join("  ");
                root.workspaceIcons = icons;
            }
        }
        Component.onCompleted: running = true
    }

    // Update on Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowsProc.running = true;
        }
    }

    // Backup timer
    Timer {
        interval: Settings.workspaceInterval
        running: true
        repeat: true
        onTriggered: windowsProc.running = true
    }

    property int maxWorkspaceWithWindows: {
        var max = 0;
        var wsList = Hyprland.workspaces.values;
        for (var i = 0; i < wsList.length; i++) {
            var ws = wsList[i];
            if (ws.id > max && ws.id <= 9) {
                max = ws.id;
            }
        }
        return max;
    }

    property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    property int workspacesToShow: Math.max(5, maxWorkspaceWithWindows, activeWorkspaceId)
}
