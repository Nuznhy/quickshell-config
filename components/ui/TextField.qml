import QtQuick
import QtQuick.Templates as T
import "." as UI
import "../../config"

T.TextField {
    id: root
    property bool invalid: false
    implicitWidth: 160
    implicitHeight: Math.max(Design.controlHeight, contentHeight + topPadding + bottomPadding)
    padding: Design.space8
    leftPadding: Design.space12
    rightPadding: Design.space12
    font.family: Design.fontFamily
    font.pixelSize: Design.bodySize
    color: Design.text
    selectionColor: Design.accent
    selectedTextColor: Design.textOnAccent
    placeholderTextColor: Design.textSecondary
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true
    hoverEnabled: true
    opacity: enabled ? 1 : Design.disabledOpacity
    UI.Text {
        anchors.fill: parent
        anchors.leftMargin: root.leftPadding
        anchors.rightMargin: root.rightPadding
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        text: root.placeholderText
        font: root.font
        color: root.placeholderTextColor
        visible: !root.length && !root.preeditText
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: Design.radiusControl
        color: Design.surface
        border.width: root.activeFocus ? Design.focusWidth : Design.borderWidth
        border.color: root.invalid ? Design.danger : root.activeFocus ? Design.accent : root.hovered && root.enabled ? Design.textSecondary : Design.border
        Behavior on border.color { ColorAnimation { duration: Design.durationFast } }
        // Invalid status and keyboard focus remain independently visible.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Design.space2
            visible: root.invalid && root.activeFocus
            color: "transparent"
            radius: Design.radiusControl + Design.space2
            border.width: Design.borderWidth
            border.color: Design.accent
        }
    }
}
