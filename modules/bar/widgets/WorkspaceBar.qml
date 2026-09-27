import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../config"
import "../../../services"

RowLayout {
    id: workspaceBar
    spacing: 3

    Repeater {
        model: Workspaces.workspacesToShow

        Rectangle {
            id: wsRect
            Layout.preferredHeight: Settings.barHeight
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
                    NumberAnimation {
                        duration: 300
                    }
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
                    NumberAnimation {
                        duration: 300
                    }
                }
            }

            property int wsId: index + 1
            property var workspace: Hyprland.workspaces.values.find(ws => ws.id === wsId) ?? null
            property bool isActive: Workspaces.activeWorkspaceId === wsId
            property bool hasWindows: workspace !== null
            property string windowIconsStr: Workspaces.getWsIcons(wsId)

            Behavior on color {
                ColorAnimation {
                    duration: 300
                }
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
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsRect.wsId + " })")
            }
        }
    }
}
