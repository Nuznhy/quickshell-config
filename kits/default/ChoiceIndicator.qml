import QtQuick
import qs.config
import qs.components.ui as UI

Surface {
    UI.Text {
        anchors.centerIn: parent
        text: surface.radio ? "●" : "✓"
        visible: surface.control.checked
        color: Design.textOnAccent
        font.pixelSize: Design.captionSize
        lineHeight: 1
    }
}
