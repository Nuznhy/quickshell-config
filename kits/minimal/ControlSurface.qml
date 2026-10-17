import QtQuick
import qs.kits.default as Default

Default.Surface {
    // Underline neutral controls; keep keyboard and hover outlines untouched.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        visible: !surface.emphasized && surface.border.color.a === 0
        color: surface.accentColor
        opacity: 0.35
    }
}
