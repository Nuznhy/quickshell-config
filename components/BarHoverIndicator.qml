import QtQuick
import "../config"

Item {
    id: root
    required property bool hovered
    property bool active: false
    property bool focused: false
    readonly property real sideInset: Theme.verticalBar ? (width - Theme.sideBarWidth + 8) / 2 : 0
    opacity: hovered || active || focused ? (enabled ? 1 : Design.disabledOpacity) : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Design.durationSlow }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: root.sideInset
        width: Theme.verticalBar ? 2 : parent.width
        height: Theme.verticalBar ? parent.height : 2
        color: root.hovered || root.focused ? Design.accent : Design.danger
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: root.sideInset
        width: Theme.verticalBar ? 2 : parent.width
        height: Theme.verticalBar ? parent.height : 2
        color: root.hovered || root.focused ? Design.accent : Design.danger
    }
}
