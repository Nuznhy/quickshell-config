import QtQuick
import qs.config

BevelSurface {
    id: root
    inset: true
    gloss: 0.035
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Design.space2
        visible: root.surface.control.invalid && root.surface.control.activeFocus
        radius: root.radius + Design.space2
        color: "transparent"
        border.width: Design.borderWidth
        border.color: Design.accent
    }
}
