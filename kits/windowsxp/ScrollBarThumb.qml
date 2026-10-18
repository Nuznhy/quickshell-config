import QtQuick
import qs.config
import qs.kits.windowsxp as XP

BevelSurface {
    id: root
    color: Qt.tint(Design.surfaceRaised, Qt.rgba(Design.accent.r, Design.accent.g, Design.accent.b, surface.control.pressed ? 0.4 : surface.control.hovered ? 0.28 : 0.16))
    inset: surface.control.pressed
    border.color: Design.accent
    Rectangle {
        anchors.centerIn: parent
        width: root.surface.control.horizontal ? 1 : Math.max(0, parent.width - 4)
        height: root.surface.control.horizontal ? Math.max(0, parent.height - 4) : 1
        color: XP.Colors.shade(root.color, -0.35)
    }
}
