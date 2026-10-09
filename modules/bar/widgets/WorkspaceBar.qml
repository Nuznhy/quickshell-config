import QtQuick
import "../../../components/ui" as UI
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../config"
import "../../../services"
import "../../../components"

Grid {
    id: workspaceBar
    objectName: "workspace-bar"
    columns: Theme.verticalBar ? 1 : Math.max(1, workspaceModel.count)
    spacing: 0
    WorkspacePreview {
        id: preview
        barWindow: workspaceBar.QsWindow.window
    }

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
            objectName: "workspace-slot-" + workspaceId
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
                color: Design.background

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
                    onHoveredChanged: {
                        if (hovered && wsSlot.present) preview.request(wsRect.wsId, wsRect, appIcons.hoveredAddress);
                        else preview.leave(wsRect.wsId);
                    }
                }

                // Behind the icon buttons, so each app receives its own click.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        preview.close();
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsRect.wsId + " })");
                    }
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
                    spacing: Design.space4

                    // Workspace number
                    UI.Text {
                        role: "bar"
                        text: wsRect.wsId
                        color: wsRect.isActive ? Design.danger : Design.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.barFontFamily
                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }
                    }

                    Item {
                        objectName: "workspace-separator-" + wsRect.wsId
                        readonly property bool dot: WorkspaceAppearance.separator === "·"
                        width: dot ? 3 : Theme.verticalBar
                            ? Math.min(separatorMetrics.advanceWidth, Theme.sideBarWidth - 26) : separatorMetrics.advanceWidth
                        height: dot ? 3 : separatorMetrics.boundingRect.height
                        visible: iconGroup.visible && WorkspaceAppearance.separator !== ""
                        opacity: 0.6
                        TextMetrics {
                            id: separatorMetrics
                            text: WorkspaceAppearance.separator
                            font.family: Design.fontFamily
                            font.pixelSize: Math.min(Theme.fontSize, Design.iconSize)
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: parent.dot
                            radius: Design.radiusSmall
                            color: wsRect.isActive ? Design.danger : Design.text
                        }
                        UI.Text {
                            role: "bar"
                            id: separatorText
                            anchors.fill: parent
                            visible: !parent.dot
                            text: WorkspaceAppearance.separator
                            textFormat: Text.PlainText
                            color: wsRect.isActive ? Design.danger : Design.text
                            font.family: Design.fontFamily
                            font.pixelSize: Math.min(Theme.fontSize, Design.iconSize)
                            fontSizeMode: Text.Fit
                            minimumPixelSize: 8
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    UI.Capsule {
                        id: iconGroup
                        objectName: "workspace-icon-group-" + wsRect.wsId
                        readonly property int inset: WorkspaceAppearance.capsule ? Design.space8 : 0
                        width: appIcons.implicitWidth + inset * 2
                        height: appIcons.implicitHeight + (WorkspaceAppearance.capsule ? Design.space8 : 0)
                        visible: WorkspaceAppearance.showIcons && appIcons.count > 0
                        color: WorkspaceAppearance.capsule ? Design.surface : "transparent"
                        border.width: WorkspaceAppearance.capsule ? 1 : 0
                        border.color: wsRect.isActive ? Design.accent : Design.border
                        radius: Math.min(width, height) / 2
                        AnimatedAppIcons {
                            id: appIcons
                            anchors.centerIn: parent
                            icons: wsRect.windowIcons
                            nerdFontIcons: WorkspaceAppearance.iconStyle === "nerd"
                            activeWorkspace: wsRect.isActive
                            onHoveredAddressChanged: {
                                if (workspaceHover.hovered && wsSlot.present)
                                    preview.request(wsRect.wsId, wsRect, hoveredAddress);
                            }
                            onWindowClicked: preview.close()
                        }
                    }
                }
            }
        }
    }
}
