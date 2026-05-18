import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import ".."

RowLayout {
    id: workspaceBar
    spacing: 3

    // Store windows per workspace
    property string ws1Icons: ""
    property string ws2Icons: ""
    property string ws3Icons: ""
    property string ws4Icons: ""
    property string ws5Icons: ""
    property string ws6Icons: ""
    property string ws7Icons: ""
    property string ws8Icons: ""
    property string ws9Icons: ""

    function getWsIcons(wsId) {
        switch(wsId) {
            case 1: return ws1Icons
            case 2: return ws2Icons
            case 3: return ws3Icons
            case 4: return ws4Icons
            case 5: return ws5Icons
            case 6: return ws6Icons
            case 7: return ws7Icons
            case 8: return ws8Icons
            case 9: return ws9Icons
            default: return ""
        }
    }

    // Process to get window list
    Process {
        id: windowsProc
        property string output: ""
        command: ["sh", "-c", "hyprctl clients -j | jq -r '.[] | select(.workspace.id > 0 and .workspace.id <= 9) | \"\\(.workspace.id):\\(.class)\"'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    windowsProc.output += data.trim() + "\n"
                }
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                var wsIcons = {}
                var lines = output.trim().split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(':')
                    if (parts.length >= 2) {
                        var wsId = parseInt(parts[0])
                        var windowClass = parts.slice(1).join(':')
                        if (wsId > 0 && wsId <= 9) {
                            if (!wsIcons[wsId]) wsIcons[wsId] = {icons: [], seen: {}}
                            var icon = Icons.getWindowIcon(windowClass)
                            if (!wsIcons[wsId].seen[icon]) {
                                wsIcons[wsId].seen[icon] = true
                                wsIcons[wsId].icons.push(icon)
                            }
                        }
                    }
                }
                workspaceBar.ws1Icons = wsIcons[1] ? wsIcons[1].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws2Icons = wsIcons[2] ? wsIcons[2].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws3Icons = wsIcons[3] ? wsIcons[3].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws4Icons = wsIcons[4] ? wsIcons[4].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws5Icons = wsIcons[5] ? wsIcons[5].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws6Icons = wsIcons[6] ? wsIcons[6].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws7Icons = wsIcons[7] ? wsIcons[7].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws8Icons = wsIcons[8] ? wsIcons[8].icons.slice(0, 3).join("  ") : ""
                workspaceBar.ws9Icons = wsIcons[9] ? wsIcons[9].icons.slice(0, 3).join("  ") : ""
            }
        }
        Component.onCompleted: running = true
    }

    // Update on Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowsProc.running = true
        }
    }

    // Backup timer
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: windowsProc.running = true
    }

    property int maxWorkspaceWithWindows: {
        var max = 0
        var wsList = Hyprland.workspaces.values
        for (var i = 0; i < wsList.length; i++) {
            var ws = wsList[i]
            if (ws.id > max && ws.id <= 9) {
                max = ws.id
            }
        }
        return max
    }

    property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    property int workspacesToShow: Math.max(5, maxWorkspaceWithWindows, activeWorkspaceId)

    Repeater {
        model: workspaceBar.workspacesToShow

        Rectangle {
            id: wsRect
            Layout.preferredHeight: 42
            Layout.preferredWidth: wsContent.implicitWidth + 10
            Layout.alignment: Qt.AlignVCenter
            color: Theme.bg

            // Top Border
            Rectangle {
                id: topBorder
                visible: isActive || wsMouse.containsMouse
                anchors.top: parent.top
                width: parent.width
                height: 2             
                color: wsMouse.containsMouse ? Theme.iris : Theme.love
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            Rectangle {
                id: bottomBorder
                visible: isActive || wsMouse.containsMouse
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: wsMouse.containsMouse ? Theme.iris : Theme.love
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            property int wsId: index + 1
            property var workspace: Hyprland.workspaces.values.find(ws => ws.id === wsId) ?? null
            property bool isActive: workspaceBar.activeWorkspaceId === wsId
            property bool hasWindows: workspace !== null
            property string windowIconsStr: wsId === 1 ? workspaceBar.ws1Icons :
                                          wsId === 2 ? workspaceBar.ws2Icons :
                                          wsId === 3 ? workspaceBar.ws3Icons :
                                          wsId === 4 ? workspaceBar.ws4Icons :
                                          wsId === 5 ? workspaceBar.ws5Icons :
                                          wsId === 6 ? workspaceBar.ws6Icons :
                                          wsId === 7 ? workspaceBar.ws7Icons :
                                          wsId === 8 ? workspaceBar.ws8Icons :
                                          wsId === 9 ? workspaceBar.ws9Icons : ""

            Behavior on color {
                ColorAnimation { duration: 300 }
            }

            Row {
                id: wsContent
                anchors.centerIn: parent
                spacing: 4

                // Workspace number
                Text {
                    text: wsRect.wsId
                    color: wsRect.isActive ? Theme.love : Theme.text
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color {
                        ColorAnimation { duration: 300 }
                    }
                }

                // Separator dot when there are icons
                Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: wsRect.isActive ? Theme.love : Theme.text
                    visible: wsRect.windowIconsStr.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.6
                }

                // Window icons
                Text {
                    text: wsRect.windowIconsStr
                    color: wsRect.isActive ? Theme.love : Theme.text
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                    visible: wsRect.windowIconsStr.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: wsRect.isActive ? 1.0 : 0.7
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + wsRect.wsId)
            }
        }
    }
}
