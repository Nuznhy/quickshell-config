import QtQuick
import qs.kits.default as Default

Default.Surface {
    // A soft inset highlight demonstrates a component override, not just tokens.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(0, surface.radius - 2)
        topLeftRadius: Math.max(0, surface.topLeftRadius - 2)
        topRightRadius: Math.max(0, surface.topRightRadius - 2)
        bottomLeftRadius: Math.max(0, surface.bottomLeftRadius - 2)
        bottomRightRadius: Math.max(0, surface.bottomRightRadius - 2)
        color: "transparent"
        border.width: 1
        border.color: surface.hoverBorder
        opacity: surface.emphasized ? 0.18 : 0
    }
}
