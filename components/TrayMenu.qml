import QtQuick
import QtQuick.Controls
import "../config"

Menu {
    id: root

    background: Rectangle {
        implicitWidth: 180
        color: Theme.overlay
        radius: 10
        border.color: Theme.iris
        border.width: 1
    }

    delegate: MenuItem {
        id: itemDelegate
        required property var modelData

        text: modelData.label
        enabled: modelData.enabled
        visible: modelData.visible

        contentItem: Text {
            text: itemDelegate.text
            color: itemDelegate.highlighted ? Theme.bg : Theme.text
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            leftPadding: 10
        }

        background: Rectangle {
            color: itemDelegate.highlighted ? Theme.love : "transparent"
            radius: 6
            anchors.fill: parent
            anchors.margins: 4
        }
    }
}
