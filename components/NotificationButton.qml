import QtQuick
import QtQuick.Controls
import "../config"

Button {
    id: root
    property bool accent: false
    property color accentColor: Theme.iris
    hoverEnabled: true
    implicitHeight: 30
    leftPadding: 10
    rightPadding: 10
    topPadding: 4
    bottomPadding: 4
    opacity: enabled ? 1 : 0.4
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    background: Rectangle {
        radius: 8
        color: root.accent ? root.accentColor : root.hovered ? Theme.highlightMed : Theme.overlay
        border.color: root.activeFocus ? Theme.iris : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    contentItem: Text {
        text: root.text
        textFormat: Text.PlainText
        color: root.accent ? Theme.bg : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 11
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
