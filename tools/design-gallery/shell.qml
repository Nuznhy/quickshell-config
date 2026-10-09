import QtQuick
import Quickshell
import "../../config"

ShellRoot {
    FloatingWindow {
        title: "Quickshell design system"
        visible: true
        implicitWidth: 960
        implicitHeight: 820
        minimumSize: Qt.size(640, 480)
        color: Design.background
        Gallery { anchors.fill: parent }
    }
}
