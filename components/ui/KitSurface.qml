import QtQuick
import qs.config

// Stable presentation API: changing kits only replaces the paint delegate.
// Children, bindings, geometry, and the owning control remain alive.
Item {
    id: root
    property var control: null
    property string kitSlot: "cardSurface"
    property color color: "transparent"
    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    component Border: QtObject {
        property real width: 1
        property color color: "transparent"
    }
    readonly property Border border: Border {}
    Loader {
        anchors.fill: parent
        z: -1
        readonly property var surface: root
        sourceComponent: UiKit.visual(root.kitSlot)
    }
}
