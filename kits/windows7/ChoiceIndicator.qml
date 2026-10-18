import QtQuick
import qs.config
import qs.kits.default as Default

Default.Surface {
    id: root
    readonly property bool lightSurface: Design.luminance(Design.surfaceRaised) > 0.5
    readonly property bool highlighted: surface.control.enabled && (surface.control.hovered || surface.control.down)
    readonly property color face: highlighted ? Qt.tint(Design.surfaceRaised, Qt.rgba(Design.accent.r, Design.accent.g, Design.accent.b, 0.12)) : Design.surfaceRaised
    readonly property color markColor: {
        const muted = Qt.tint(Design.textSecondary, Qt.rgba(Design.accent.r, Design.accent.g, Design.accent.b, 0.35));
        return Design.contrast(muted, face) >= 3 ? muted : Design.readableText(face);
    }
    radius: surface.radio ? height / 2 : 0
    topLeftRadius: radius
    topRightRadius: radius
    bottomLeftRadius: radius
    bottomRightRadius: radius
    border.color: surface.control.activeFocus || highlighted ? Design.accent : Qt.tint(face, lightSurface ? "#29000000" : "#60000000")
    gradient: Gradient {
        GradientStop {
            position: 0
            color: Qt.tint(root.face, root.lightSurface ? "#38ffffff" : "#18ffffff")
        }
        GradientStop {
            position: 1
            color: Qt.tint(root.face, root.lightSurface ? "#80ffffff" : "#08000000")
        }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(root.border.width + 1, Math.round(root.width * 0.18))
        radius: root.surface.radio ? height / 2 : 0
        border.width: 1
        border.color: Qt.tint(root.face, root.lightSurface ? "#24000000" : "#40000000")
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.tint(root.face, "#18566b9a")
            }
            GradientStop {
                position: 1
                color: Qt.tint(root.face, root.lightSurface ? "#f0ffffff" : "#20ffffff")
            }
        }
    }
    Canvas {
        id: mark
        anchors.fill: parent
        visible: root.surface.control.checked
        readonly property bool radio: root.surface.radio
        readonly property color color: root.markColor
        onColorChanged: requestPaint()
        onRadioChanged: requestPaint()
        onVisibleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.scale(width / 11, height / 11);
            ctx.beginPath();
            if (radio) {
                ctx.arc(5.5, 5.5, 2.2, 0, Math.PI * 2);
                ctx.fillStyle = color;
                ctx.fill();
            } else {
                ctx.moveTo(3.5, 6);
                ctx.lineTo(5, 8);
                ctx.lineTo(7.5, 3.5);
                ctx.strokeStyle = color;
                ctx.lineWidth = 1.5;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.stroke();
            }
        }
    }
}
