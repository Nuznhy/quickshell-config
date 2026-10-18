import QtQuick
import qs.config
import qs.components.ui as UI
import qs.components.shared

Item {
    id: root
    implicitHeight: 220
    clip: true
    Rectangle {
        anchors.fill: parent
        color: Design.background
    }
    Repeater {
        model: Math.ceil(root.width / 48)
        Rectangle {
            required property int index
            x: index * 48
            width: 48
            height: root.height
            color: Qt.tint(Design.background, index % 2 ? "#50ffffff" : "#50000000")
        }
    }
    UI.KitSurface {
        kitSlot: "barSurface"
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44
        color: Design.background
        Row {
            anchors.fill: parent
            anchors.leftMargin: Design.space12
            spacing: Design.space16
            UI.Text {
                height: parent.height
                text: "Bar glass"
                verticalAlignment: Text.AlignVCenter
            }
            Item {
                width: 100
                height: parent.height
                BarHoverIndicator {
                    anchors.fill: parent
                    hovered: true
                    focused: true
                }
                UI.Text {
                    anchors.centerIn: parent
                    text: "Focused"
                }
            }
        }
    }
    UI.MenuSurface {
        x: 16
        y: 68
        width: Math.max(100, (root.width - 48) / 2)
        height: 132
        UI.Text {
            anchors.centerIn: parent
            text: "Menu surface"
        }
    }
    Item {
        id: dropdown
        x: root.width / 2 + 8
        y: 56
        width: Math.max(100, (root.width - 48) / 2)
        height: 144
        readonly property bool showStem: true
        readonly property int triggerWidth: 44
        readonly property string stemAlignment: "center"
        Loader {
            anchors.fill: parent
            readonly property var surface: dropdown
            sourceComponent: UiKit.visual("dropdownSurface")
        }
        UI.Text {
            anchors.centerIn: parent
            text: "Popup surface"
        }
    }
}
