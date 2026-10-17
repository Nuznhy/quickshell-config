import QtQuick
import qs.config

Surface {
    Rectangle {
        readonly property real inset: (parent.height - height) / 2
        x: surface.control.checked ? parent.width - width - inset : inset
        y: inset
        width: Design.switchThumb
        height: width
        radius: height / 2
        color: surface.control.checked ? Design.textOnAccent : Design.text
        Behavior on x { NumberAnimation { duration: Design.durationNormal; easing.type: Easing.OutCubic } }
    }
}
