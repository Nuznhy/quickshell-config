pragma Singleton
import QtQuick

QtObject {
    id: root
    // Used only by the standalone gallery. Never changes saved appearance.
    property var previewPalette: null
    readonly property var palette: previewPalette || Theme
    readonly property string fontFamily: Theme.fontFamily
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"

    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20
    readonly property int space24: 24
    readonly property int space32: 32
    readonly property int controlGap: space8
    readonly property int panelPadding: space12
    readonly property int sectionGap: space16
    readonly property int windowPadding: space20

    readonly property int captionSize: 10
    readonly property int labelSize: 11
    readonly property int bodySize: 12
    readonly property int sectionHeadingSize: 16
    readonly property int panelHeadingSize: 20
    readonly property int pageHeadingSize: 24
    readonly property real bodyLineHeight: 1.35
    readonly property real headingLineHeight: 1.2
    readonly property int iconSmall: 12
    readonly property int iconSize: 16
    readonly property int iconLarge: 20
    readonly property int iconHero: 24
    readonly property int iconDisplay: 32
    readonly property int artworkPlaceholderSize: 60

    readonly property int radiusSmall: 4
    readonly property int radiusControl: 8
    readonly property int radiusCard: 12
    readonly property int borderWidth: 1
    readonly property int focusWidth: 2
    readonly property int controlHeight: 32
    readonly property int compactHeight: 28
    readonly property int selectorHeight: 40
    readonly property int switchWidth: 40
    readonly property int switchHeight: 22
    readonly property int switchThumb: 16
    readonly property int sliderTrack: 6
    readonly property int sliderThumb: 16
    readonly property int durationFast: 120
    readonly property int durationNormal: 160
    readonly property int durationSlow: 300
    readonly property real disabledOpacity: 0.4

    readonly property color background: palette.bg
    readonly property color surface: palette.surface
    readonly property color surfaceRaised: palette.overlay
    readonly property color hover: palette.highlightMed
    readonly property color pressed: palette.highlightHigh || palette.highlightMed
    readonly property color text: palette.text
    readonly property color textSecondary: palette.subtle
    readonly property color textMuted: palette.muted || palette.subtle
    readonly property color border: palette.highlightMed
    readonly property color accent: palette.iris
    readonly property color textOnAccent: readableText(accent)
    readonly property color danger: palette.love
    readonly property color warning: palette.gold || palette.love
    readonly property color success: palette.foam || palette.iris
    readonly property color info: palette.pine || palette.iris

    function textSize(role) {
        switch (role) {
        case "caption": return captionSize;
        case "label": return labelSize;
        case "section": return sectionHeadingSize;
        case "panel": return panelHeadingSize;
        case "page": return pageHeadingSize;
        default: return bodySize;
        }
    }
    function heading(role) { return ["section", "panel", "page"].includes(role); }
    function luminance(value) {
        const c = Qt.tint(value, "transparent");
        function linear(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
    }
    function contrast(a, b) {
        const x = luminance(a), y = luminance(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }
    function readableText(fillColor) {
        if (contrast(background, fillColor) >= 4.5) return background;
        if (contrast(text, fillColor) >= 4.5) return text;
        return contrast("#ffffff", fillColor) > contrast("#000000", fillColor) ? "#ffffff" : "#000000";
    }
    function fill(variant, selected, hovered, down, active, accentColor) {
        const emphasized = selected || variant === "primary" || variant === "destructive";
        const base = emphasized ? (variant === "destructive" ? danger : accentColor)
            : variant === "ghost" ? "transparent" : surfaceRaised;
        if (!active) return base;
        if (down) return emphasized ? Qt.tint(base, Qt.rgba(0, 0, 0, 0.16)) : pressed;
        if (hovered) return emphasized ? Qt.tint(base, Qt.rgba(1, 1, 1, 0.12)) : hover;
        return base;
    }
}
