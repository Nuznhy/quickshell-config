import QtQuick
import qs.config
import qs.kits.default as Default

Default.Surface {
    id: root
    property bool inset: false
    property real gloss: lightSurface ? 0.12 : 0.18
    property color foreground: "transparent"
    property color topColor: shade(inset ? -gloss : gloss)
    property color upperColor: shade(inset ? -gloss * 0.5 : gloss * 0.55)
    property color lowerColor: shade(inset ? -gloss * 0.25 : -gloss * 0.3)
    property color bottomColor: shade(inset ? gloss * 0.25 : -gloss * 0.55)
    property real upperStop: 0.48
    property real lowerStop: 0.5
    property real bottomStop: 1
    property color innerEdge: inset ? "#20000000" : lightSurface ? "#28ffffff" : "#50ffffff"
    readonly property bool hasFill: surface.color.a > 0
    readonly property bool lightSurface: Design.luminance(surface.color) > 0.5
    readonly property color edge: surface.border.color.a > 0 ? surface.border.color : Qt.tint(surface.color, Qt.rgba(0, 0, 0, lightSurface ? 0.24 : 0.4))
    border.color: hasFill ? edge : surface.border.color
    gradient: Gradient {
        GradientStop {
            position: 0
            color: root.topColor
        }
        GradientStop {
            position: root.upperStop
            color: root.upperColor
        }
        GradientStop {
            position: root.lowerStop
            color: root.lowerColor
        }
        GradientStop {
            position: root.bottomStop
            color: root.bottomColor
        }
    }

    function shade(amount) {
        // Limit gloss where the selected palette has little contrast to spare.
        const minimum = Math.min(4.6, Design.contrast(foreground, surface.color));
        for (let attempt = 0; attempt < 8; ++attempt) {
            const channel = amount > 0 ? 1 : 0;
            const value = Qt.tint(surface.color, Qt.rgba(channel, channel, channel, Math.abs(amount)));
            if (foreground.a === 0 || Design.contrast(foreground, value) >= minimum)
                return Qt.rgba(value.r, value.g, value.b, surface.color.a);
            amount *= 0.5;
        }
        return surface.color;
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(1, root.border.width)
        visible: root.hasFill
        color: "transparent"
        radius: Math.max(0, root.radius - anchors.margins)
        topLeftRadius: Math.max(0, root.topLeftRadius - anchors.margins)
        topRightRadius: Math.max(0, root.topRightRadius - anchors.margins)
        bottomLeftRadius: Math.max(0, root.bottomLeftRadius - anchors.margins)
        bottomRightRadius: Math.max(0, root.bottomRightRadius - anchors.margins)
        border.width: 1
        border.color: root.innerEdge
    }
}
