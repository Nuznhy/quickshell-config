pragma Singleton
import QtQuick

QtObject {
    id: root
    // Used only by the standalone gallery. Never changes saved appearance.
    property var previewPalette: null
    property string previewMode: ""
    readonly property var palette: UiKit.resolvePalette(previewPalette || Theme, previewMode || Theme.mode || "dark")
    readonly property string fontFamily: UiKit.active.fontFamily || Theme.fontFamily
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"

    readonly property int space2: UiKit.tokens.space2
    readonly property int space4: UiKit.tokens.space4
    readonly property int space8: UiKit.tokens.space8
    readonly property int space12: UiKit.tokens.space12
    readonly property int space16: UiKit.tokens.space16
    readonly property int space20: UiKit.tokens.space20
    readonly property int space24: UiKit.tokens.space24
    readonly property int space32: UiKit.tokens.space32
    readonly property int controlGap: UiKit.tokens.controlGap
    readonly property int panelPadding: UiKit.tokens.panelPadding
    readonly property int sectionGap: UiKit.tokens.sectionGap
    readonly property int windowPadding: UiKit.tokens.windowPadding

    readonly property int captionSize: UiKit.tokens.captionSize
    readonly property int labelSize: UiKit.tokens.labelSize
    readonly property int bodySize: UiKit.tokens.bodySize
    readonly property int sectionHeadingSize: UiKit.tokens.sectionHeadingSize
    readonly property int panelHeadingSize: UiKit.tokens.panelHeadingSize
    readonly property int pageHeadingSize: UiKit.tokens.pageHeadingSize
    readonly property real bodyLineHeight: UiKit.tokens.bodyLineHeight
    readonly property real headingLineHeight: UiKit.tokens.headingLineHeight
    readonly property int iconSmall: UiKit.tokens.iconSmall
    readonly property int iconSize: UiKit.tokens.iconSize
    readonly property int iconLarge: UiKit.tokens.iconLarge
    readonly property int iconHero: UiKit.tokens.iconHero
    readonly property int iconDisplay: UiKit.tokens.iconDisplay
    readonly property int artworkPlaceholderSize: UiKit.tokens.artworkPlaceholderSize

    readonly property int radiusSmall: UiKit.tokens.radiusSmall
    readonly property int radiusControl: UiKit.tokens.radiusControl
    readonly property int radiusCard: UiKit.tokens.radiusCard
    readonly property int borderWidth: UiKit.tokens.borderWidth
    readonly property int focusWidth: UiKit.tokens.focusWidth
    readonly property int controlHeight: UiKit.tokens.controlHeight
    readonly property int compactHeight: UiKit.tokens.compactHeight
    readonly property int selectorHeight: UiKit.tokens.selectorHeight
    readonly property int switchWidth: UiKit.tokens.switchWidth
    readonly property int switchHeight: UiKit.tokens.switchHeight
    readonly property int switchThumb: UiKit.tokens.switchThumb
    readonly property int sliderTrack: UiKit.tokens.sliderTrack
    readonly property int sliderThumb: UiKit.tokens.sliderThumb
    readonly property int durationFast: UiKit.tokens.durationFast
    readonly property int durationNormal: UiKit.tokens.durationNormal
    readonly property int durationSlow: UiKit.tokens.durationSlow
    readonly property real disabledOpacity: UiKit.tokens.disabledOpacity

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
        case "caption":
            return captionSize;
        case "label":
            return labelSize;
        case "section":
            return sectionHeadingSize;
        case "panel":
            return panelHeadingSize;
        case "page":
            return pageHeadingSize;
        default:
            return bodySize;
        }
    }
    function heading(role) {
        return ["section", "panel", "page"].includes(role);
    }
    function luminance(value) {
        const c = Qt.tint(value, "transparent");
        function linear(v) {
            return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        }
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
    }
    function contrast(a, b) {
        const x = luminance(a), y = luminance(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }
    function readableText(fillColor) {
        if (contrast(background, fillColor) >= 4.5)
            return background;
        if (contrast(text, fillColor) >= 4.5)
            return text;
        return contrast("#ffffff", fillColor) > contrast("#000000", fillColor) ? "#ffffff" : "#000000";
    }
    function fill(variant, selected, hovered, down, active, accentColor) {
        const emphasized = selected || variant === "primary" || variant === "destructive";
        const base = emphasized ? (variant === "destructive" ? danger : accentColor) : variant === "ghost" ? "transparent" : surfaceRaised;
        let fill = base;
        if (active && down)
            fill = emphasized ? Qt.tint(base, Qt.rgba(0, 0, 0, 0.16)) : pressed;
        else if (active && hovered)
            fill = emphasized ? Qt.tint(base, Qt.rgba(1, 1, 1, 0.12)) : hover;
        return UiKit.active.controlFill ? UiKit.active.controlFill({
            fill: fill,
            variant: variant,
            selected: selected,
            hovered: hovered,
            down: down,
            enabled: active,
            accent: accentColor
        }) : fill;
    }
}
