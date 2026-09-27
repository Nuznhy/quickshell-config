import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

Switch {
    id: root
    property bool value: false
    signal changeRequested(bool value)
    checked: value
    onToggled: {
        const requested = checked;
        checked = Qt.binding(() => root.value);
        changeRequested(requested);
    }
    implicitWidth: 40
    implicitHeight: 26
    Layout.minimumWidth: 40
    Layout.preferredWidth: 40
    Layout.maximumWidth: 40
    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    padding: 0
    hoverEnabled: true
    opacity: enabled ? 1 : 0.4
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    background: null
    contentItem: Item {}
    indicator: Rectangle {
        anchors.centerIn: parent
        width: 40; height: 22
        radius: 11
        color: root.checked ? Theme.iris : Theme.highlightMed
        border.color: root.activeFocus || root.hovered ? Theme.iris : "transparent"
        Behavior on color { ColorAnimation { duration: 140 } }
        Rectangle {
            x: root.checked ? 21 : 3
            y: 3
            width: 16; height: 16; radius: 8
            color: root.checked ? Theme.bg : Theme.text
            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }
}
