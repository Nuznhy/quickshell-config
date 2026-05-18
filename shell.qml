//@ pragma UseQApplication
// shell.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "components"

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            property var modelData
            screen: modelData
            signal closeAllPopups()

            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    if (event.name === "activewindow" || event.name === "activewindowv2") {
                        barWindow.closeAllPopups()
                    }
                }
            }
            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 42
            color: Theme.bg
            margins {
                top: 0
                bottom: 0
                left: 0
                right: 0
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Left padding
                    Item { width: 34 }

                    // Workspaces
                    WorkspaceBar {
                        Layout.preferredHeight: parent.height
                        Layout.alignment: Qt.AlignLeft
                    }
                    Item { width: 12 } 

                    Tray {}

                    Item {
                        Layout.fillWidth: true
                    }

                    Cpu {
                        
                    }
                    Item { width: 12 } 
                    
                    Memory {
                    }
                    Item { width: 12 } 

                    VolumeWidget {

                    }
                    Item { width: 12 } 

                    KeyboardLanguage {

                    }
                    Item { width: 12 } 

                    PowerWidger {

                    }

                    Item { width: 40 } 
                }
            }

            Clock {
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onClicked: (mouse) => {
                    barWindow.closeAllPopups()
                    mouse.accepted = false
                }
            }
        }
    }
}
