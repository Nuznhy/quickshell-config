import QtQuick
import qs.config
import qs.kits.windows7 as Aero

Canvas {
    id: root
    readonly property var surface: parent.surface
    property real glassOpacity: 0.55
    property real frameInset: 0
    property bool horizontal: false
    readonly property color baseColor: surface.color
    readonly property color edge: {
        const shade = Qt.tint(baseColor, "#70000000");
        return surface.border.color.a > 0 ? surface.border.color : Qt.rgba(shade.r, shade.g, shade.b, baseColor.a);
    }
    readonly property real edgeWidth: surface.border.width
    readonly property var corners: [surface.topLeftRadius, surface.topRightRadius, surface.bottomLeftRadius, surface.bottomRightRadius]
    onBaseColorChanged: requestPaint()
    onEdgeChanged: requestPaint()
    onEdgeWidthChanged: requestPaint()
    onCornersChanged: requestPaint()
    onGlassOpacityChanged: requestPaint()
    onFrameInsetChanged: requestPaint()
    onHorizontalChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        Aero.GlassPaint.paint(ctx, width, height, baseColor, edge, edgeWidth, glassOpacity, horizontal, () => Aero.GlassPaint.roundedPath(ctx, width, height, corners), frameInset, 0);
    }
}
