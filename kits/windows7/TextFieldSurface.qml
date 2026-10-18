import QtQuick
import qs.config

BevelSurface {
    id: root
    inset: true
    gloss: lightSurface ? 0.025 : 0.04
    foreground: Design.text
    // Keep invalid status and keyboard focus independently visible.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Design.space2
        visible: root.surface.control.invalid && root.surface.control.activeFocus
        color: "transparent"
        radius: root.radius + Design.space2
        border.width: Design.borderWidth
        border.color: Design.accent
    }
}
