import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../config"
import "widgets"

PanelWindow {
    id: barWindow
    signal closeAllPopups

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "activewindowv2") {
                barWindow.closeAllPopups();
            }
        }
    }
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Settings.barHeight
    color: "transparent"
    margins {
        top: Theme.barTopMargin
        bottom: 0
        left: Theme.barSideMargin
        right: Theme.barSideMargin
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.barRadius
        opacity: Theme.barOpacity
        // Fade the completed bar once, including overlapping backgrounds and text.
        layer.enabled: opacity < 1

        Clock {
            anchors.centerIn: parent
            z: 1
        }

        // Behind the controls so their hover, cursor, and button handling wins.
        MouseArea {
            anchors.fill: parent
            onClicked: barWindow.closeAllPopups()
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left padding
            Item {
                Layout.preferredWidth: Settings.leftPadding
            }

            // Workspaces
            WorkspaceBar {
                Layout.preferredHeight: parent.height
                Layout.alignment: Qt.AlignLeft
            }
            Item {
                Layout.preferredWidth: Settings.widgetSpacing
            }

            Tray {}

            Item {
                Layout.fillWidth: true
            }

            Cpu {}
            Item {
                Layout.preferredWidth: Settings.widgetSpacing
            }

            Memory {}
            Item {
                Layout.preferredWidth: Settings.widgetSpacing
            }

            VolumeWidget {}
            Item {
                Layout.preferredWidth: Settings.widgetSpacing
            }

            KeyboardLanguage {}
            Item {
                Layout.preferredWidth: Settings.widgetSpacing
            }

            ThemeWidget {}
            Item {
                Layout.preferredWidth: Settings.widgetSpacing
            }

            PowerWidget {}

            Item {
                Layout.preferredWidth: Settings.rightPadding
            }
        }
    }

}
