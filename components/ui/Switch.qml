import QtQuick
import QtQuick.Templates as T
import "../../config"

T.Switch {
    id: root
    property bool busy: false
    implicitWidth: Design.switchWidth
    implicitHeight: Design.controlHeight
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Design.disabledOpacity
    Binding { target: root; property: "enabled"; value: false; when: root.busy; restoreMode: Binding.RestoreBindingOrValue }
    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    contentItem: Item {}
    indicator: Rectangle {
        anchors.centerIn: parent
        width: Design.switchWidth
        height: Design.switchHeight
        radius: height / 2
        color: Design.fill("neutral", root.checked, root.hovered, root.down, root.enabled, Design.accent)
        border.width: root.activeFocus ? Design.focusWidth : Design.borderWidth
        border.color: root.activeFocus ? Design.text : root.hovered && root.enabled ? Design.accent : Design.border
        Behavior on color { ColorAnimation { duration: Design.durationFast } }
        Rectangle {
            readonly property real inset: (parent.height - height) / 2
            x: root.checked ? parent.width - width - inset : inset
            y: inset
            width: Design.switchThumb
            height: width
            radius: height / 2
            color: root.checked ? Design.textOnAccent : Design.text
            Behavior on x { NumberAnimation { duration: Design.durationNormal; easing.type: Easing.OutCubic } }
        }
    }
}
