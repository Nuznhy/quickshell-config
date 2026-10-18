import QtQuick
import qs.config
import qs.kits.windowsxp as XP

BevelSurface {
    id: root
    readonly property bool menu: surface.controlKind === "menuItem"
    readonly property bool select: surface.controlKind === "select"
    readonly property bool hot: surface.control.enabled && surface.control.hovered
    readonly property color accent: surface.variant === "destructive" ? Design.danger : surface.accentColor
    foreground: Design.readableText(color)
    inset: !menu && (select || surface.control.down)
    gloss: menu ? 0 : select ? 0.025 : 0.14
    showRim: false
    border.color: !hasFill && !surface.control.activeFocus ? "transparent" : menu ? (surface.control.activeFocus ? accent : "transparent") : surface.control.activeFocus || surface.emphasized || hot ? accent : select ? Design.border : XP.Colors.shade(accent, light ? -0.4 : 0.25)
    // Menus are flat, even when highlighted; no inner bevel in that slot.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(1, root.border.width)
        visible: !root.menu && root.hasFill
        color: "transparent"
        radius: Math.max(0, root.radius - anchors.margins)
        topLeftRadius: Math.max(0, root.topLeftRadius - anchors.margins)
        topRightRadius: Math.max(0, root.topRightRadius - anchors.margins)
        bottomLeftRadius: Math.max(0, root.bottomLeftRadius - anchors.margins)
        bottomRightRadius: Math.max(0, root.bottomRightRadius - anchors.margins)
        border.width: root.hot || root.surface.emphasized ? 2 : 1
        border.color: root.surface.control.down ? "#30000000" : root.hot ? XP.Colors.shade(Design.warning, 0.5) : root.surface.emphasized ? XP.Colors.shade(root.accent, 0.5) : "#80ffffff"
    }
    Rectangle {
        id: selectButton
        visible: root.select
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Math.max(2, root.border.width)
        width: Design.space24
        radius: Design.radiusSmall
        bottomRightRadius: Math.max(0, root.bottomRightRadius - anchors.margins)
        color: Qt.tint(root.color, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.hot ? 0.25 : 0.14))
        border.color: root.accent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: XP.Colors.safeShade(selectButton.color, 0.25, root.foreground)
            }
            GradientStop {
                position: 1
                color: XP.Colors.safeShade(selectButton.color, -0.06, root.foreground)
            }
        }
    }
}
