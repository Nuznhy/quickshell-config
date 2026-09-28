import QtQuick
import "../config"

Canvas {
    id: root
    property var points: []
    property real maximum: 100
    property real endTime: points.length ? points[points.length - 1].time : Date.now()
    property color lineColor: Theme.iris
    property color gridColor: Theme.highlightMed
    onPointsChanged: requestPaint()
    onMaximumChanged: requestPaint()
    onEndTimeChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onGridColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = gridColor;
        ctx.lineWidth = 1;
        for (let row = 0; row < 3; row++) {
            const y = 2 + row * (height - 4) / 2;
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
        }
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.beginPath();
        let previous = null;
        for (const point of points) {
            if (point.value === null || !Number.isFinite(point.value)) { previous = null; continue; }
            const x = width * (point.time - (endTime - 600000)) / 600000;
            const y = height - 2 - Math.max(0, Math.min(1, point.value / Math.max(1, maximum))) * (height - 4);
            if (!previous || point.time - previous.time > 6000) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
            previous = point;
        }
        ctx.stroke();
    }
}
