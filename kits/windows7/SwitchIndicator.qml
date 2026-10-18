import QtQuick
import qs.config

BevelSurface {
    id: root
    inset: true
    Rectangle {
        id: thumb
        readonly property real inset: (parent.height - height) / 2
        x: root.surface.control.checked ? parent.width - width - inset : inset
        y: inset
        width: Design.switchThumb
        height: width
        radius: height / 2
        color: Design.readableText(root.surface.color)
        border.color: Qt.tint(color, "#60000000")
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.tint(thumb.color, "#70ffffff")
            }
            GradientStop {
                position: 0.48
                color: thumb.color
            }
            GradientStop {
                position: 1
                color: Qt.tint(thumb.color, "#30000000")
            }
        }
        Behavior on x {
            NumberAnimation {
                duration: Design.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }
}
