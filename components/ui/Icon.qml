import qs.components.ui as UI
import QtQuick
import QtQuick.Window
import qs.config
import qs.config as ConfigScripts

Item {
    id: root
    property int size: Design.iconSize
    property string name: ""
    property string text: ConfigScripts.IconNames.glyph(name)
    property bool useKitIcons: true
    property url source: useKitIcons ? UiKit.iconSource(name || ConfigScripts.IconNames.name(text), size * Screen.devicePixelRatio) : ""
    property alias color: glyph.color
    property alias font: glyph.font
    readonly property bool imageReady: artwork.status === Image.Ready
    implicitWidth: size
    implicitHeight: size

    Image {
        id: artwork
        objectName: "kit-icon-image"
        anchors.centerIn: parent
        width: Math.min(root.size, root.width, root.height)
        height: width
        source: root.source
        fillMode: Image.PreserveAspectFit
        visible: root.imageReady
    }
    TextMetrics {
        id: metrics
        font: glyph.font
        text: glyph.text
    }
    UI.Text {
        id: glyph
        objectName: "kit-icon-glyph"
        text: root.text || ConfigScripts.IconNames.glyph(root.name)
        visible: !root.imageReady
        // Center visible ink, rather than the font's advance width and line box.
        x: (root.width - metrics.tightBoundingRect.width * scale) / 2 - metrics.tightBoundingRect.x * scale
        y: (root.height - metrics.tightBoundingRect.height * scale) / 2 - (metrics.tightBoundingRect.y + baselineOffset) * scale
        scale: Math.min(1, root.width / Math.max(1, metrics.tightBoundingRect.width), root.height / Math.max(1, metrics.tightBoundingRect.height))
        transformOrigin: Item.TopLeft
        font.family: Design.iconFontFamily
        font.pixelSize: root.size
        lineHeight: 1
    }
}
