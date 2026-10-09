import QtQuick
import "../config"

Item {
    id: root
    property color color: Theme.text
    property int iconSize: Theme.fontSize
    property string glyph: Theme.settingsIcon
    property url source: Theme.settingsIconSource
    implicitWidth: iconSize
    implicitHeight: iconSize
    Image {
        id: customImage
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }
    TextMetrics {
        id: metrics
        font: glyphText.font
        text: glyphText.text
    }
    Text {
        id: glyphText
        // Center the visible ink, accounting for font bearings and baseline.
        x: (root.width - metrics.tightBoundingRect.width * scale) / 2
            - metrics.tightBoundingRect.x * scale
        y: (root.height - metrics.tightBoundingRect.height * scale) / 2
            - (metrics.tightBoundingRect.y + baselineOffset) * scale
        scale: Math.min(1, root.width / Math.max(1, metrics.tightBoundingRect.width),
                        root.height / Math.max(1, metrics.tightBoundingRect.height))
        transformOrigin: Item.TopLeft
        visible: customImage.status !== Image.Ready
        text: root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: root.iconSize
        color: root.color
    }
}
