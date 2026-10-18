import QtQuick
import qs.config
import qs.kits.windows7 as Aero

Canvas {
    id: root
    readonly property var surface: parent.surface
    visible: surface.showStem
    readonly property int stemWidth: Math.max(0, Math.min(surface.triggerWidth + 16, width - 60))
    readonly property int stemHeight: surface.showStem ? 12 : 0
    readonly property int notchRadius: Math.min(cardRadius, stemHeight)
    readonly property int cardRadius: Design.radiusCard
    readonly property string stemAlignment: surface.stemAlignment
    readonly property color backgroundColor: Design.background
    readonly property color edge: Design.border
    readonly property int edgeWidth: Design.borderWidth
    onStemWidthChanged: requestPaint()
    onStemHeightChanged: requestPaint()
    onStemAlignmentChanged: requestPaint()
    onCardRadiusChanged: requestPaint()
    onBackgroundColorChanged: requestPaint()
    onEdgeChanged: requestPaint()
    onEdgeWidthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        Aero.GlassPaint.paint(ctx, width, height, backgroundColor, edge, edgeWidth, 0.55, false, () => Aero.GlassPaint.dropdownPath(ctx, width, height, stemWidth, stemHeight, stemAlignment, cardRadius), 6, stemHeight);
    }
}
