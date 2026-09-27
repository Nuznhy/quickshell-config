import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../config"
import "../../../services"
import "../../../components"

Grid {
    id: workspaceBar
    columns: Theme.verticalBar ? 1 : Math.max(1, workspaceModel.count)
    spacing: 0

    ListModel {
        id: workspaceModel
    }

    function removeWorkspace(wsId) {
        for (let i = 0; i < workspaceModel.count; ++i) {
            if (workspaceModel.get(i).workspaceId === wsId && !workspaceModel.get(i).present) {
                workspaceModel.remove(i);
                return;
            }
        }
    }

    function syncWorkspaces() {
        const ids = Workspaces.occupiedWorkspaceIds;
        for (let i = 0; i < workspaceModel.count; ++i)
            workspaceModel.setProperty(i, "present", ids.includes(workspaceModel.get(i).workspaceId));
        for (const wsId of ids) {
            let index = 0;
            while (index < workspaceModel.count && workspaceModel.get(index).workspaceId < wsId)
                ++index;
            if (index === workspaceModel.count || workspaceModel.get(index).workspaceId !== wsId)
                workspaceModel.insert(index, {
                    workspaceId: wsId,
                    present: true
                });
            else
                workspaceModel.setProperty(index, "present", true);
        }
    }

    Connections {
        target: Workspaces
        function onOccupiedWorkspaceIdsChanged() {
            workspaceBar.syncWorkspaces();
        }
    }
    Component.onCompleted: syncWorkspaces()

    Repeater {
        model: workspaceModel

        Item {
            id: wsSlot
            required property int workspaceId
            required property bool present
            property bool appeared: false
            property bool closing: false
            property real exitWidth: 0
            property real contentWidth: present ? wsContent.implicitWidth + 10 : exitWidth
            property real reveal: appeared && !closing ? 1 : 0
            width: (Theme.verticalBar ? Theme.sideBarWidth - 16 : contentWidth + 3) * reveal
            height: Theme.verticalBar ? (wsContent.implicitHeight + 16) * reveal : Settings.barHeight
            enabled: present
            clip: !Theme.verticalBar

            Component.onCompleted: appeared = true
            onPresentChanged: {
                if (present) {
                    closing = false;
                } else {
                    exitWidth = wsContent.implicitWidth + 10;
                }
            }

            Behavior on contentWidth {
                enabled: wsSlot.appeared && wsSlot.present
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on reveal {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.InOutCubic
                }
            }

            // Let the last icon pop out before sliding the empty workspace away.
            Timer {
                interval: 180
                running: !wsSlot.present
                onTriggered: wsSlot.closing = true
            }
            Timer {
                interval: 440
                running: !wsSlot.present
                onTriggered: workspaceBar.removeWorkspace(wsSlot.workspaceId)
            }

            Rectangle {
                id: wsRect
                width: Theme.verticalBar ? wsSlot.width : wsSlot.contentWidth
                height: parent.height
                x: -12 * (1 - wsSlot.reveal)
                opacity: wsSlot.reveal
                color: Theme.bg

                BarHoverIndicator {
                    anchors.fill: parent
                    hovered: workspaceHover.hovered
                    active: wsRect.isActive
                }

                readonly property int wsId: wsSlot.workspaceId
                property bool isActive: Workspaces.activeWorkspaceId === wsId
                property var windowIcons: Workspaces.getWsIcons(wsId)

                HoverHandler {
                    id: workspaceHover
                }

                // Behind the icon buttons, so each app receives its own click.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsRect.wsId + " })")
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 300
                    }
                }

                Grid {
                    id: wsContent
                    columns: Theme.verticalBar ? 1 : 3
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter
                    width: implicitWidth
                    height: implicitHeight
                    x: Theme.verticalBar ? (parent.width - width) / 2 : 5
                    y: (parent.height - height) / 2
                    spacing: 4

                    // Workspace number
                    Text {
                        text: wsRect.wsId
                        color: wsRect.isActive ? Theme.love : Theme.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }
                    }

                    // Separator dot when there are icons
                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: wsRect.isActive ? Theme.love : Theme.text
                        visible: appIcons.count > 0
                        opacity: 0.6
                    }

                    AnimatedAppIcons {
                        id: appIcons
                        icons: wsRect.windowIcons
                        activeWorkspace: wsRect.isActive
                        visible: count > 0
                    }
                }
            }
        }
    }
}
