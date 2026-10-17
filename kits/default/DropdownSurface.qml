import QtQuick
import qs.config

Canvas {
    readonly property var surface: parent.surface
    visible: surface.showStem
    anchors.fill: parent

    property int rawStemWidth: surface.triggerWidth + 16
    property int stemWidth: Math.min(rawStemWidth, width - 60)  // ensure room for notch corners
    property int stemHeight: surface.showStem ? 12 : 0
    property int notchRadius: Math.min(Design.radiusControl, stemHeight)
    property int cardRadius: Design.radiusCard
    readonly property string stemAlignment: surface.stemAlignment
    property color backgroundColor: Design.background

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
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = backgroundColor;

        var sw = stemWidth;
        var sh = stemHeight;
        var nr = notchRadius;
        var w = width;
        var h = height;
        var r = Math.max(0, Math.min(cardRadius, w / 2, (h - sh) / 2));
        var stemRadius = Math.min(r, sw / 2, sh);

        // Calculate stem center based on alignment
        var cx;
        if (stemAlignment === "right") {
            cx = w - sw / 2 - 10;
        } else if (stemAlignment === "left") {
            cx = sw / 2 + 10;
        } else {
            cx = w / 2;
        }

        var stemLeft = cx - sw / 2;
        var stemRight = cx + sw / 2;

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
    }
}
