import QtQuick
import QtQuick.Effects
import "../../config"

Popup {
    id: root
    property real reveal: 0
    opacity: 0
    readonly property real bottomRadius: Design.radiusControl * reveal
    // Options meet the frame without an inset gutter.
    padding: Design.borderWidth
    background: MenuSurface {
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: root.bottomRadius
        bottomRightRadius: root.bottomRadius
    }
    // Clip the entire viewport, including highlighted rows while scrolling.
    // Rectangle.clip alone only clips to a rectangular bounding box.
    property Item viewportMask: Rectangle {
        parent: root.contentItem
        width: root.availableWidth
        height: root.availableHeight
        visible: false
        layer.enabled: true
        color: "white"
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Math.max(0, root.bottomRadius - root.padding)
        bottomRightRadius: bottomLeftRadius
    }
    Binding { target: root.contentItem; property: "layer.enabled"; value: true }
    Binding { target: root.contentItem; property: "layer.effect"; value: viewportEffect }
    Component {
        id: viewportEffect
        MultiEffect {
            maskEnabled: true
            maskSource: root.viewportMask
        }
    }
    enter: Transition {
        NumberAnimation { target: root; property: "reveal"; to: 1; duration: Design.durationNormal; easing.type: Easing.InOutCubic }
        NumberAnimation { property: "opacity"; to: 1; duration: Design.durationNormal }
    }
    exit: Transition {
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: Design.durationNormal; easing.type: Easing.InOutCubic }
        NumberAnimation { property: "opacity"; to: 0; duration: Design.durationNormal }
    }
}
