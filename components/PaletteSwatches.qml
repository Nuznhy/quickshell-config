pragma ComponentBehavior: Bound
import QtQuick
import "../config"

Row {
    id: root
    required property var colors
    property int swatchWidth: 16
    property int swatchHeight: 10
    spacing: Design.space4
    Repeater {
        model: [root.colors.bg, root.colors.text, root.colors.love, root.colors.gold, root.colors.foam, root.colors.iris]
        Rectangle {
            required property color modelData
            width: root.swatchWidth
            height: root.swatchHeight
            radius: Design.radiusSmall
            color: modelData
            border.width: 1
            border.color: Design.pressed
        }
    }
}
