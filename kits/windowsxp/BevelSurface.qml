import QtQuick
import qs.config
import qs.kits.default as Default
import qs.kits.windowsxp as XP

Default.Surface {
    id: root
    property bool inset: false
    property real gloss: 0.13
    property color foreground: Design.text
    property bool showRim: true
    readonly property bool hasFill: color.a > 0
    readonly property bool light: Design.luminance(color) > 0.5
    property color topColor: XP.Colors.safeShade(color, inset ? -gloss : gloss, foreground)
    property color bottomColor: XP.Colors.safeShade(color, inset ? gloss * 0.25 : -gloss * 0.45, foreground)
    border.color: surface.border.color.a > 0 ? surface.border.color : hasFill ? XP.Colors.shade(color, light ? -0.38 : 0.35) : "transparent"
    gradient: Gradient {
        GradientStop {
            position: 0
            color: root.topColor
        }
        GradientStop {
            position: 1
            color: root.bottomColor
        }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(1, root.border.width)
        visible: root.showRim && root.hasFill && width > 0 && height > 0
        color: "transparent"
        radius: Math.max(0, root.radius - anchors.margins)
        topLeftRadius: Math.max(0, root.topLeftRadius - anchors.margins)
        topRightRadius: Math.max(0, root.topRightRadius - anchors.margins)
        bottomLeftRadius: Math.max(0, root.bottomLeftRadius - anchors.margins)
        bottomRightRadius: Math.max(0, root.bottomRightRadius - anchors.margins)
        border.width: 1
        border.color: root.inset ? "#24000000" : "#60ffffff"
    }
}
