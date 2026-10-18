import QtQuick
import qs.config

Item {
    id: root
    readonly property var surface: parent.surface
    Rectangle {
        objectName: "widget-hover-background"
        anchors.fill: parent
        radius: Math.min(Design.radiusControl, width / 2, height / 2)
        color: Design.barColor("accent")
        opacity: root.surface.backgroundOpacity
        border.color: Design.barColor("accent")
        gradient: Gradient {
            orientation: Theme.verticalBar ? Gradient.Horizontal : Gradient.Vertical
            GradientStop {
                position: 0
                color: Qt.tint(Design.barColor("accent"), "#80ffffff")
            }
            GradientStop {
                position: 0.48
                color: Design.barColor("accent")
            }
            GradientStop {
                position: 0.5
                color: Qt.tint(Design.barColor("accent"), "#20000000")
            }
            GradientStop {
                position: 1
                color: Design.barColor("accent")
            }
        }
    }
    Item {
        anchors.fill: parent
        opacity: root.surface.lineOpacity
        Rectangle {
            objectName: "widget-leading-line"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: root.surface.sideInset
            width: Theme.verticalBar ? 2 : parent.width
            height: Theme.verticalBar ? parent.height : 2
            color: root.surface.hovered || root.surface.focused ? Design.barColor("accent") : Design.barColor("danger")
        }
        Rectangle {
            objectName: "widget-trailing-line"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: root.surface.sideInset
            width: Theme.verticalBar ? 2 : parent.width
            height: Theme.verticalBar ? parent.height : 2
            color: root.surface.hovered || root.surface.focused ? Design.barColor("accent") : Design.barColor("danger")
        }
    }
    Rectangle {
        objectName: "widget-focus-outline"
        anchors.fill: parent
        anchors.margins: Design.focusWidth / 2
        radius: Design.radiusControl
        color: "transparent"
        border.width: Design.focusWidth
        border.color: Design.barColor("accent")
        visible: root.surface.focused
    }
}
