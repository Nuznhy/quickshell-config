import QtQuick
import QtQuick.Templates as T
import "../../config"

T.ScrollBar {
    id: root
    implicitWidth: horizontal ? Design.controlHeight : Design.space8
    implicitHeight: horizontal ? Design.space8 : Design.controlHeight
    minimumSize: 0.08
    padding: Design.space2
    hoverEnabled: true
    // Templates do not implement a style's visibility policy for us.
    // A full-size thumb means there is no overflow to scroll.
    visible: policy !== T.ScrollBar.AlwaysOff && (policy === T.ScrollBar.AlwaysOn || size < 1)
    contentItem: Rectangle {
        implicitWidth: Design.space4
        implicitHeight: Design.space4
        radius: Design.radiusSmall
        color: root.pressed ? Design.accent : Design.textSecondary
        opacity: root.policy === T.ScrollBar.AlwaysOn || (root.size < 1 && (root.active || root.hovered || root.pressed)) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Design.durationFast } }
    }
}
