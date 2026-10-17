import QtQuick
import Quickshell
import qs.tools.gallery
import qs.config

ShellRoot {
    FloatingWindow {
        title: "Quickshell design system"
        visible: true
        implicitWidth: 960
        implicitHeight: 820
        minimumSize: Qt.size(640, 480)
        color: Design.background
        Gallery {
            anchors.fill: parent
        }
    }
}
