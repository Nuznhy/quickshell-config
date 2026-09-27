pragma ComponentBehavior: Bound
import QtQuick
import "../config"

Row {
    id: root
    required property var colors
    property int swatchWidth: 16
    property int swatchHeight: 10
    spacing: 4
    Repeater {
        model: [root.colors.bg, root.colors.text, root.colors.love, root.colors.gold, root.colors.foam, root.colors.iris]
        Rectangle {
            required property color modelData
            width: root.swatchWidth
            height: root.swatchHeight
            radius: 3
            color: modelData
            border.width: 1
            border.color: Theme.highlightHigh
        }
    }
}
