import QtQuick
import qs.config

Canvas {
    id: root
    readonly property var surface: parent.surface
    visible: surface.showStem
    anchors.fill: parent

    property int rawStemWidth: surface.triggerWidth + 16
    property int stemWidth: Math.max(0, Math.min(rawStemWidth, width - 60))  // ensure room for notch corners
    property int stemHeight: surface.showStem ? 12 : 0
    property int notchRadius: Math.min(Design.radiusControl, stemHeight)
    property int cardRadius: Design.radiusCard
    readonly property string stemAlignment: surface.stemAlignment
    property color backgroundColor: Design.background

    readonly property color edge: Design.accent
    readonly property int edgeWidth: Design.borderWidth
    onEdgeChanged: requestPaint()
    onEdgeWidthChanged: requestPaint()
    onStemWidthChanged: requestPaint()
    onStemAlignmentChanged: requestPaint()
    onStemHeightChanged: requestPaint()
    onNotchRadiusChanged: requestPaint()
    onCardRadiusChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onBackgroundColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = backgroundColor;

        const sw = stemWidth;
        const sh = stemHeight;
        const nr = notchRadius;
        const w = width;
        const h = height;
        const r = Math.max(0, Math.min(cardRadius, w / 2, (h - sh) / 2));
        const stemRadius = Math.min(r, sw / 2, sh);

        // Calculate stem center based on alignment
        let cx;
        if (stemAlignment === "right") {
            cx = w - sw / 2 - 10;
        } else if (stemAlignment === "left") {
            cx = sw / 2 + 10;
        } else {
            cx = w / 2;
        }

        const stemLeft = cx - sw / 2;
        const stemRight = cx + sw / 2;

        ctx.beginPath();
        ctx.moveTo(stemLeft + stemRadius, 0);
        ctx.lineTo(stemRight - stemRadius, 0);
        ctx.arcTo(stemRight, 0, stemRight, stemRadius, stemRadius);
        ctx.lineTo(stemRight, sh - nr);
        ctx.arcTo(stemRight, sh, stemRight + nr, sh, nr);
        ctx.lineTo(w - r, sh);
        ctx.arcTo(w, sh, w, sh + r, r);
        ctx.lineTo(w, h - r);
        ctx.arcTo(w, h, w - r, h, r);
        ctx.lineTo(r, h);
        ctx.arcTo(0, h, 0, h - r, r);
        ctx.lineTo(0, sh + r);
        ctx.arcTo(0, sh, r, sh, r);
        ctx.lineTo(stemLeft - nr, sh);
        ctx.arcTo(stemLeft, sh, stemLeft, sh - nr, nr);
        ctx.lineTo(stemLeft, stemRadius);
        ctx.arcTo(stemLeft, 0, stemLeft + stemRadius, 0, stemRadius);
        ctx.closePath();
        ctx.fill();
        ctx.save();
        ctx.clip();
        ctx.strokeStyle = edge;
        ctx.lineWidth = edgeWidth * 2;
        ctx.stroke();
        ctx.restore();
    }
}
