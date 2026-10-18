import QtQuick
import qs.config

Canvas {
    id: root
    readonly property var surface: parent.surface
    readonly property bool horizontal: surface.control.horizontal
    readonly property bool lightSurface: Design.luminance(Design.surfaceRaised) > 0.5
    readonly property bool highlighted: surface.control.enabled && (surface.control.hovered || surface.control.pressed)
    readonly property color neutralFace: lightSurface ? Design.surfaceRaised : Qt.tint(Design.surfaceRaised, "#30ffffff")
    readonly property color face: highlighted ? Qt.tint(neutralFace, Qt.rgba(surface.control.accentColor.r, surface.control.accentColor.g, surface.control.accentColor.b, 0.2)) : neutralFace
    readonly property color edge: surface.control.activeFocus || highlighted ? surface.control.accentColor : Qt.tint(face, lightSurface ? "#6b000000" : "#50ffffff")
    readonly property real edgeWidth: surface.border.width
    onHorizontalChanged: requestPaint()
    onFaceChanged: requestPaint()
    onEdgeChanged: requestPaint()
    onEdgeWidthChanged: requestPaint()
    onLightSurfaceChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.translate(width / 2, height / 2);
        if (!horizontal)
            ctx.rotate(-Math.PI / 2);
        const w = horizontal ? width : height;
        const h = horizontal ? height : width;
        ctx.translate(-w / 2, -h / 2);
        const left = w * 0.25;
        const right = w * 0.75;
        const top = edgeWidth / 2;
        const shoulder = h * 0.72;
        const tip = h - edgeWidth / 2;
        ctx.beginPath();
        ctx.moveTo(left + 1, top);
        ctx.lineTo(right - 1, top);
        ctx.arcTo(right, top, right, top + 1, 1);
        ctx.lineTo(right, shoulder);
        ctx.lineTo(w / 2, tip);
        ctx.lineTo(left, shoulder);
        ctx.lineTo(left, top + 1);
        ctx.arcTo(left, top, left + 1, top, 1);
        ctx.closePath();
        const gradient = ctx.createLinearGradient(0, top, 0, tip);
        gradient.addColorStop(0, Qt.tint(face, lightSurface ? "#f0ffffff" : "#40ffffff"));
        gradient.addColorStop(0.76, Qt.tint(face, "#04000000"));
        ctx.fillStyle = gradient;
        ctx.fill();
        ctx.save();
        ctx.clip();
        ctx.strokeStyle = lightSurface ? "#ddffffff" : "#50ffffff";
        ctx.lineWidth = edgeWidth + 3;
        ctx.stroke();
        ctx.restore();
        ctx.strokeStyle = edge;
        ctx.lineWidth = edgeWidth;
        ctx.stroke();
    }
}
