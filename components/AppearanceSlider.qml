pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root
    required property string label
    required property real value
    property real minimum: 0
    property real maximum: 40
    property real stepSize: 1
    property string suffix: " px"
    signal valueEdited(real value)
    signal editingFinished
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: root.label.toUpperCase()
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 1
        }
        Text {
            text: Math.round(root.value) + root.suffix
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
    Slider {
        id: slider
        Layout.fillWidth: true
        implicitHeight: 26
        from: root.minimum
        to: root.maximum
        stepSize: root.stepSize
        value: root.value
        enabled: Theme.ready
        wheelEnabled: false
        Accessible.name: root.label
        onMoved: root.valueEdited(value)
        onPressedChanged: { if (!pressed && Theme.ready) root.editingFinished(); }
        HoverHandler {
            enabled: slider.enabled
            cursorShape: Qt.PointingHandCursor
        }
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Theme.overlay
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: Theme.iris
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 16
            height: 16
            radius: 8
            color: Theme.text
            border.color: slider.activeFocus ? Theme.iris : Theme.highlightHigh
        }
    }
}
