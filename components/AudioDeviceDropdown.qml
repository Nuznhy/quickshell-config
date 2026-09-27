pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

Item {
    id: root
    required property string title
    required property var devices
    required property string selectedName
    property bool busy: false
    property bool expanded: false
    readonly property string selectedDescription: devices.find(device => device.name === selectedName)?.description || (devices.length ? "Select a device" : "No devices available")
    signal selected(string name)
    implicitHeight: selectorLayout.implicitHeight
    onBusyChanged: {
        if (busy)
            expanded = false;
    }
    onDevicesChanged: {
        if (!devices.length)
            expanded = false;
    }

    ColumnLayout {
        id: selectorLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6
        Text {
            text: root.title
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 1
        }

        Button {
            id: trigger
            Layout.fillWidth: true
            implicitHeight: 40
            leftPadding: 12
            rightPadding: 10
            enabled: root.devices.length > 0 && !root.busy
            hoverEnabled: true
            Accessible.name: root.title + ": " + root.selectedDescription
            onClicked: root.expanded = !root.expanded
            Keys.onEscapePressed: root.expanded = false
            HoverHandler {
                enabled: trigger.enabled
                cursorShape: Qt.PointingHandCursor
            }
            contentItem: RowLayout {
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: root.busy ? "Switching…" : root.selectedDescription
                    elide: Text.ElideRight
                    color: root.expanded ? Theme.bg : (trigger.enabled ? Theme.text : Theme.subtle)
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: root.expanded ? "▴" : "▾"
                    color: root.expanded ? Theme.bg : Theme.subtle
                    font.pixelSize: 15
                }
            }
            background: Rectangle {
                radius: 8
                color: root.expanded ? Theme.iris : (trigger.hovered ? Theme.overlay : Theme.surface)
                border.color: root.expanded || trigger.activeFocus ? Theme.iris : Theme.highlightMed
            }
        }
    }

    Popup {
        id: devicePopup
        // Draw in the window overlay, outside the selector's layout.
        popupType: Popup.Item
        parent: trigger
        x: 0
        property real slideOffset: 0
        y: trigger.height + 4 + slideOffset
        width: trigger.width
        height: Math.min(choices.implicitHeight, 170) + padding * 2
        padding: 6
        margins: 8
        visible: root.expanded
        focus: true
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 140
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: devicePopup
                    property: "slideOffset"
                    from: -8
                    to: 0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 110
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: devicePopup
                    property: "slideOffset"
                    to: -8
                    duration: 110
                    easing.type: Easing.InCubic
                }
            }
        }
        // Let the trigger handle its own toggle instead of closing on press
        // and immediately reopening when its clicked signal arrives.
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        onClosed: root.expanded = false
        background: Rectangle {
            color: Theme.bg
            radius: 10
            border.color: Theme.iris
        }
        contentItem: ScrollView {
            contentWidth: availableWidth
            clip: true
            ColumnLayout {
                id: choices
                width: parent.width
                spacing: 4
                Repeater {
                    model: devicePopup.visible ? root.devices : []
                    Button {
                        id: choice
                        required property var modelData
                        readonly property bool selectedDevice: modelData.name === root.selectedName
                        Layout.fillWidth: true
                        implicitHeight: Math.max(38, label.implicitHeight + 16)
                        leftPadding: 12
                        rightPadding: 10
                        hoverEnabled: true
                        onClicked: {
                            const name = modelData.name;
                            root.expanded = false;
                            if (name !== root.selectedName)
                                root.selected(name);
                            trigger.forceActiveFocus();
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        contentItem: Text {
                            id: label
                            text: (choice.selectedDevice ? "✓  " : "") + choice.modelData.description
                            color: choice.selectedDevice ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: choice.selectedDevice
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 6
                            color: choice.selectedDevice ? Theme.iris : (choice.hovered ? Theme.overlay : Theme.surface)
                            border.width: choice.activeFocus ? 2 : 1
                            border.color: choice.activeFocus ? Theme.text : (choice.selectedDevice ? Theme.iris : Theme.highlightMed)
                        }
                    }
                }
            }
        }
    }
}
