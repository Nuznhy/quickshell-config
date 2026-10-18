import QtQuick
import qs.config
import qs.kits.windowsxp as XP

BevelSurface {
    id: root
    color: surface.control.checked ? Design.accent : Design.background
    inset: true
    radius: Design.radiusControl
    topLeftRadius: radius
    topRightRadius: radius
    bottomLeftRadius: radius
    bottomRightRadius: radius
    border.color: surface.control.activeFocus || surface.control.hovered ? Design.accent : Design.border
    Rectangle {
        id: thumb
        readonly property real inset: (parent.height - height) / 2
        x: root.surface.control.checked ? parent.width - width - inset : inset
        y: inset
        width: Design.switchThumb
        height: width
        radius: Design.radiusSmall
        border.color: XP.Colors.shade(Design.surfaceRaised, -0.4)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: XP.Colors.shade(Design.surfaceRaised, 0.5)
            }
            GradientStop {
                position: 1
                color: XP.Colors.shade(Design.surfaceRaised, -0.08)
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
