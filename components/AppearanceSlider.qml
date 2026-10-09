pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

UI.ColumnLayout {
    id: root
    required property string label
    required property real value
    property real minimum: 0
    property real maximum: 40
    property real stepSize: 1
    property string suffix: " px"
    signal valueEdited(real value)
    signal editingFinished
    spacing: Design.space4

    UI.RowLayout {
        Layout.fillWidth: true
        UI.FieldLabel {
            Layout.fillWidth: true
            text: root.label
            color: Design.textSecondary
            font.family: Design.fontFamily
            role: "label"
            wrapMode: Text.WordWrap
        }
        UI.Text {
            text: Math.round(root.value) + root.suffix
            color: Design.text
            font.family: Design.fontFamily
            role: "body"
        }
    }
    UI.Slider {
        id: slider
        Layout.fillWidth: true
        from: root.minimum
        to: root.maximum
        stepSize: root.stepSize
        value: root.value
        enabled: Theme.ready
        wheelEnabled: false
        Accessible.name: root.label
        onMoved: root.valueEdited(value)
        onPressedChanged: { if (!pressed && Theme.ready) root.editingFinished(); }
    }
}
