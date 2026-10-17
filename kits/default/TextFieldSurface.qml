import QtQuick
import qs.config

Surface {
    // Invalid status and keyboard focus remain independently visible.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Design.space2
        visible: surface.control.invalid && surface.control.activeFocus
        color: "transparent"
        radius: Design.radiusControl + Design.space2
        border.width: Design.borderWidth
        border.color: Design.accent
    }
}
