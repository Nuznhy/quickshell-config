import "." as UI
import QtQuick
import "../../config"

Item {
    id: root
    property int size: Design.iconSize
    property alias text: glyph.text
    property alias color: glyph.color
    property alias font: glyph.font
    implicitWidth: size
    implicitHeight: size

    TextMetrics {
        id: metrics
        font: glyph.font
        text: glyph.text
    }
    UI.Text {
        id: glyph
        // Center visible ink, rather than the font's advance width and line box.
        x: (root.width - metrics.tightBoundingRect.width * scale) / 2
            - metrics.tightBoundingRect.x * scale
        y: (root.height - metrics.tightBoundingRect.height * scale) / 2
            - (metrics.tightBoundingRect.y + baselineOffset) * scale
        scale: Math.min(1, root.width / Math.max(1, metrics.tightBoundingRect.width),
                        root.height / Math.max(1, metrics.tightBoundingRect.height))
        transformOrigin: Item.TopLeft
        font.family: Design.iconFontFamily
        font.pixelSize: root.size
        lineHeight: 1
    }
}
