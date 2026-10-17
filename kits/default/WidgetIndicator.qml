import QtQuick
import qs.config

Item {
    id: visual
    readonly property var root: parent.surface
    Rectangle {
        objectName: "widget-hover-background"
        anchors.fill: parent
        radius: Math.min(Design.radiusControl, width / 2, height / 2)
        color: Design.accent
        opacity: root.backgroundOpacity
    }
    Item {
        anchors.fill: parent
        opacity: root.lineOpacity
        Rectangle {
            objectName: "widget-leading-line"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: root.sideInset
            width: Theme.verticalBar ? 2 : parent.width
            height: Theme.verticalBar ? parent.height : 2
            color: root.hovered || root.focused ? Design.accent : Design.danger
        }
        Rectangle {
            objectName: "widget-trailing-line"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: root.sideInset
            width: Theme.verticalBar ? 2 : parent.width
            height: Theme.verticalBar ? parent.height : 2
            color: root.hovered || root.focused ? Design.accent : Design.danger
        }
    }
    Rectangle {
        objectName: "widget-focus-outline"
        anchors.fill: parent
        anchors.margins: Design.focusWidth / 2
        radius: Design.radiusControl
        color: "transparent"
        border.width: Design.focusWidth
        border.color: Design.accent
        visible: root.focused
    }
}
