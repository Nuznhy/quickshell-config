import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../config"

PanelWindow {
    id: barRoot
    required property var assignedScreen
    screen: assignedScreen
    signal closeAllPopups
    visible: Theme.barEnabled(assignedScreen?.name || "")
    onVisibleChanged: { if (!visible) closeAllPopups(); }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // Focus grabs handle outside clicks. An activewindow event can also
            // be the popup itself taking focus, so dismiss on workspace changes
            // explicitly instead of immediately closing a newly opened popup.
            if (event.name === "workspace" || event.name === "workspacev2"
                    || event.name === "activespecial" || event.name === "activespecialv2"
                    || event.name === "focusedmon") {
                barRoot.closeAllPopups();
            }
        }
    }
    Connections {
        target: BarLayout
        function onAboutToChange() { barRoot.closeAllPopups(); }
    }
    Connections {
        target: Theme
        function onBarPositionChanged() { barRoot.closeAllPopups(); }
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
        color: Design.background
        radius: Theme.barRadius
        opacity: Theme.barOpacity
        // Fade the completed bar once, including overlapping backgrounds and text.
        layer.enabled: opacity < 1

        id: background
        readonly property real edgeStart: Theme.verticalBar ? 12 : Settings.leftPadding
        readonly property real edgeEnd: Theme.verticalBar ? 12 : Settings.rightPadding
        readonly property real axisLength: Theme.verticalBar ? height : width
        readonly property real centerLength: Math.min(centerSection.naturalLength, Math.max(0, axisLength / 3))
        readonly property real halfSpace: Math.max(0, (axisLength - centerLength) / 2
            - (centerLength > 0 ? Settings.widgetSpacing : 0))

        MouseArea {
            anchors.fill: parent
            onClicked: barRoot.closeAllPopups()
        }

        BarSection {
            id: startSection
            section: "start"
            barWindow: barRoot
            x: Theme.verticalBar ? 0 : background.edgeStart
            y: Theme.verticalBar ? background.edgeStart : 0
            width: Theme.verticalBar ? parent.width : Math.min(naturalLength, Math.max(0, background.halfSpace - background.edgeStart))
            height: Theme.verticalBar ? Math.min(naturalLength, Math.max(0, background.halfSpace - background.edgeStart)) : parent.height
        }
        BarSection {
            id: centerSection
            section: "center"
            barWindow: barRoot
            width: Theme.verticalBar ? parent.width : background.centerLength
            height: Theme.verticalBar ? background.centerLength : parent.height
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
        }
        BarSection {
            id: endSection
            section: "end"
            barWindow: barRoot
            alignEnd: true
            width: Theme.verticalBar ? parent.width : Math.min(naturalLength, Math.max(0, background.halfSpace - background.edgeEnd))
            height: Theme.verticalBar ? Math.min(naturalLength, Math.max(0, background.halfSpace - background.edgeEnd)) : parent.height
            x: Theme.verticalBar ? 0 : parent.width - width - background.edgeEnd
            y: Theme.verticalBar ? parent.height - height - background.edgeEnd : 0
        }
    }
}
