import QtQuick
import "../../config"

Rectangle {
    required property var control
    property string variant: "neutral"
    property bool selected: false
    property color accentColor: Design.accent
    property bool capsule: false
    readonly property bool emphasized: selected || variant === "primary" || variant === "destructive"
    readonly property color hoverBorder: emphasized
        ? Design.readableText(variant === "destructive" ? Design.danger : accentColor) : accentColor
    radius: capsule ? height / 2 : Design.radiusControl
    color: Design.fill(variant, selected, control.hovered, control.down, control.enabled, accentColor)
    border.width: control.activeFocus ? Design.focusWidth : Design.borderWidth
    border.color: control.activeFocus ? (emphasized ? Design.text : Design.accent)
        : control.enabled && control.hovered ? hoverBorder : "transparent"
    Behavior on color { ColorAnimation { duration: Design.durationFast } }
    Behavior on border.color { ColorAnimation { duration: Design.durationFast } }
}
