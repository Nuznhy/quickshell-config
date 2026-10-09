import QtQuick
import QtQuick.Templates as T
import "../../config"

T.Slider {
    id: root
    property color accentColor: Design.accent
    property bool showHandle: true
    implicitWidth: 160
    implicitHeight: Design.controlHeight
    padding: Design.space8
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    wheelEnabled: false
    opacity: enabled ? 1 : Design.disabledOpacity
    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    background: Rectangle {
        x: root.horizontal ? root.leftPadding : root.leftPadding + (root.availableWidth - width) / 2
        y: root.horizontal ? root.topPadding + (root.availableHeight - height) / 2 : root.topPadding
        width: root.horizontal ? root.availableWidth : Design.sliderTrack
        height: root.horizontal ? Design.sliderTrack : root.availableHeight
        radius: Design.sliderTrack / 2
        color: Design.surfaceRaised
        Rectangle {
            y: root.horizontal ? 0 : root.visualPosition * parent.height
            width: root.horizontal ? root.position * parent.width : parent.width
            height: root.horizontal ? parent.height : root.position * parent.height
            radius: parent.radius
            color: root.accentColor
        }
    }
    handle: Rectangle {
        x: root.leftPadding + (root.horizontal ? root.visualPosition * (root.availableWidth - width) : (root.availableWidth - width) / 2)
        y: root.topPadding + (root.horizontal ? (root.availableHeight - height) / 2 : root.visualPosition * (root.availableHeight - height))
        width: Design.sliderThumb
        height: width
        radius: height / 2
        visible: root.showHandle
        color: root.pressed ? root.accentColor : Design.text
        border.width: root.activeFocus ? Design.focusWidth : Design.borderWidth
        border.color: root.activeFocus || root.hovered ? root.accentColor : Design.border
    }
}
