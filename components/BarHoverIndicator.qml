import QtQuick
import "../config"

Item {
    id: root
    required property bool hovered
    property bool active: false
    readonly property real sideInset: Theme.verticalBar ? (width - Theme.sideBarWidth + 8) / 2 : 0
    opacity: hovered || active ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: root.sideInset
        width: Theme.verticalBar ? 2 : parent.width
        height: Theme.verticalBar ? parent.height : 2
        color: root.hovered ? Theme.iris : Theme.love
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: root.sideInset
        width: Theme.verticalBar ? 2 : parent.width
        height: Theme.verticalBar ? parent.height : 2
        color: root.hovered ? Theme.iris : Theme.love
    }
}
