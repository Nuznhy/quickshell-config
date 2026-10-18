import QtQuick
import qs.config

Item {
    id: root
    readonly property var surface: parent.surface
    readonly property bool horizontal: surface.control.horizontal
    readonly property bool lightSurface: Design.luminance(Design.surfaceRaised) > 0.5
    Rectangle {
        anchors.fill: parent
        color: Qt.tint(Design.surfaceRaised, root.lightSurface ? "#12000000" : "#30000000")
        border.width: 1
        border.color: Qt.tint(Design.surfaceRaised, root.lightSurface ? "#35000000" : "#70000000")
    }
    Rectangle {
        x: root.horizontal && root.surface.control.mirrored ? parent.width - width : 0
        y: root.horizontal ? 0 : root.surface.control.visualPosition * parent.height
        width: root.horizontal ? root.surface.control.position * parent.width : parent.width
        height: root.horizontal ? parent.height : root.surface.control.position * parent.height
        // A hidden thumb still needs a visible value, for example on media progress.
        visible: !root.surface.control.showHandle
        color: root.surface.control.accentColor
    }
    Rectangle {
        x: root.horizontal ? 0 : parent.width - 1
        y: root.horizontal ? parent.height - 1 : 0
        width: root.horizontal ? parent.width : 1
        height: root.horizontal ? 1 : parent.height
        color: root.lightSurface ? "#80ffffff" : "#30ffffff"
    }
}
