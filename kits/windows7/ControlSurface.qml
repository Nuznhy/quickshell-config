import QtQuick
import qs.config

BevelSurface {
    id: root
    readonly property color controlAccent: surface.variant === "destructive" ? Design.danger : surface.accentColor !== undefined ? surface.accentColor : Design.accent
    readonly property bool accented: !!(surface.control.activeFocus || (surface.control.enabled && (surface.emphasized || surface.control.hovered)))
    foreground: surface.control.foreground !== undefined ? surface.control.foreground : surface.emphasized ? Design.textOnAccent : Design.text
    inset: surface.control.down
    gloss: root.lightSurface ? (surface.emphasized ? 0.08 : 0.12) : (surface.emphasized ? 0.12 : 0.2)
    // The reference button has a flat upper face, a short step, and a silver foot.
    topColor: shade(inset ? -gloss : lightSurface ? 0.51 : gloss)
    upperColor: shade(inset ? -gloss * 0.5 : lightSurface ? 0.51 : gloss * 0.55)
    lowerColor: shade(inset ? -gloss * 0.25 : lightSurface ? -0.02 : -gloss * 0.3)
    bottomColor: shade(inset ? gloss * 0.25 : lightSurface ? 0.29 : -gloss * 0.55)
    upperStop: 0.437
    lowerStop: 0.489
    bottomStop: 0.835
    innerEdge: inset ? "#28000000" : lightSurface ? shade(0.76) : "#50ffffff"
    border.color: !root.hasFill ? root.surface.border.color : root.accented ? root.controlAccent : Qt.tint(surface.color, Qt.rgba(0, 0, 0, lightSurface ? 0.45 : 0.4))
}
