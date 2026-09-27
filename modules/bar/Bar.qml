import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../config"
import "widgets"
import "../network"

PanelWindow {
    id: barWindow
    required property var assignedScreen
    screen: assignedScreen
    signal closeAllPopups
    visible: Theme.barEnabled(assignedScreen?.name || "")
    onVisibleChanged: { if (!visible) closeAllPopups(); }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "activewindowv2") {
                barWindow.closeAllPopups();
            }
        }
    }
    Connections {
        target: Theme
        function onBarPositionChanged() { barWindow.closeAllPopups(); }
    }
    anchors {
        top: Theme.barPosition !== "bottom"
        bottom: Theme.barPosition !== "top"
        left: Theme.barPosition !== "right"
        right: Theme.barPosition !== "left"
    }

    implicitHeight: Settings.barHeight
    implicitWidth: Theme.sideBarWidth
    color: "transparent"
    margins {
        top: Theme.verticalBar ? Theme.barSideMargin : Theme.barPosition === "top" ? Theme.barTopMargin : 0
        bottom: Theme.verticalBar ? Theme.barSideMargin : Theme.barPosition === "bottom" ? Theme.barTopMargin : 0
        left: !Theme.verticalBar ? Theme.barSideMargin : Theme.barPosition === "left" ? Theme.barTopMargin : 0
        right: !Theme.verticalBar ? Theme.barSideMargin : Theme.barPosition === "right" ? Theme.barTopMargin : 0
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
            height: Theme.verticalBar ? Settings.barHeight + 12 : Settings.barHeight
            z: 1
        }

        // Behind the controls so their hover, cursor, and button handling wins.
        MouseArea {
            anchors.fill: parent
            onClicked: barWindow.closeAllPopups()
        }

        readonly property real sectionHeight: Math.max(60, (height - Settings.barHeight - 12) / 2 - 24)

        Flickable {
            id: startSection
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: Theme.verticalBar ? 0 : Settings.leftPadding
            anchors.topMargin: Theme.verticalBar ? 12 : 0
            width: Theme.verticalBar ? parent.width : startItems.implicitWidth
            height: Theme.verticalBar ? Math.min(startItems.implicitHeight, parent.sectionHeight) : parent.height
            contentWidth: width
            contentHeight: Theme.verticalBar ? startItems.implicitHeight : height
            interactive: Theme.verticalBar && contentHeight > height
            clip: Theme.verticalBar
            boundsBehavior: Flickable.StopAtBounds
            onMovementStarted: barWindow.closeAllPopups()
            ScrollBar.vertical: ScrollBar { policy: startSection.interactive ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }

            GridLayout {
                id: startItems
                width: Theme.verticalBar ? startSection.width : implicitWidth
                height: Theme.verticalBar ? implicitHeight : startSection.height
                columns: Theme.verticalBar ? 1 : 5
                rowSpacing: 0
                columnSpacing: 0

                WorkspaceBar {
                    id: workspaces
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: Theme.verticalBar ? implicitHeight : Settings.barHeight
                }
                WidgetSpacer { visible: workspaces.visible && workspaces.width > 0 }
                Tray { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer { visible: media.visible }
                MediaWidget { id: media; Layout.alignment: Qt.AlignHCenter }
            }
        }

        Flickable {
            id: endSection
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Theme.verticalBar ? 0 : Settings.rightPadding
            anchors.bottomMargin: Theme.verticalBar ? 12 : 0
            width: Theme.verticalBar ? parent.width : endItems.implicitWidth
            height: Theme.verticalBar ? Math.min(endItems.implicitHeight, parent.sectionHeight) : parent.height
            contentWidth: width
            contentHeight: Theme.verticalBar ? endItems.implicitHeight : height
            contentY: Theme.verticalBar ? Math.max(0, contentHeight - height) : 0
            interactive: Theme.verticalBar && contentHeight > height
            clip: Theme.verticalBar
            boundsBehavior: Flickable.StopAtBounds
            onMovementStarted: barWindow.closeAllPopups()
            ScrollBar.vertical: ScrollBar { policy: endSection.interactive ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }

            GridLayout {
                id: endItems
                width: Theme.verticalBar ? endSection.width : implicitWidth
                height: Theme.verticalBar ? implicitHeight : endSection.height
                columns: Theme.verticalBar ? 1 : 19
                rowSpacing: 0
                columnSpacing: 0

                Cpu { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                Memory { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                Network { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                BluetoothWidget { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                KeyboardLanguage { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                VolumeWidget { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                BrightnessWidget { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                NotificationWidget { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                ThemeWidget { Layout.alignment: Qt.AlignHCenter }
                WidgetSpacer {}
                PowerWidget { Layout.alignment: Qt.AlignHCenter }
            }
        }
    }
}
