import "." as UI
import QtQuick
import "../../config"

Rectangle {
    required property var control
    property bool radio: false
    implicitWidth: Design.iconSize
    implicitHeight: implicitWidth
    x: control.leftPadding
    y: (control.height - height) / 2
    radius: radio ? height / 2 : Design.radiusSmall
    color: Design.fill("neutral", control.checked, control.hovered, control.down, control.enabled, Design.accent)
    border.width: control.activeFocus ? Design.focusWidth : Design.borderWidth
    border.color: control.activeFocus ? Design.text : Design.border
    UI.Text {
        anchors.centerIn: parent
        text: parent.radio ? "●" : "✓"
        visible: parent.control.checked
        color: Design.textOnAccent
        font.pixelSize: Design.captionSize
        lineHeight: 1
    }
}
