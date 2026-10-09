pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
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

    UI.ColumnLayout {
        id: selectorLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Design.space4
        UI.Text {
            text: root.title
            color: Design.textSecondary
            font.family: Design.fontFamily
            role: "label"
            font.letterSpacing: 1
        }

        UI.Button {
            highlighted: root.expanded
            id: trigger
            Layout.fillWidth: true
            implicitHeight: Design.selectorHeight
            leftPadding: Design.space12
            rightPadding: Design.space8
            enabled: root.devices.length > 0 && !root.busy
            // Pending work blocks input without fading the confirmed device label.
            opacity: root.devices.length > 0 ? 1 : Design.disabledOpacity
            Accessible.name: root.title + ": " + root.selectedDescription
            onClicked: root.expanded = !root.expanded
            Keys.onEscapePressed: root.expanded = false

            contentItem: UI.RowLayout {
                spacing: Design.space8
                UI.Text {
                    Layout.fillWidth: true
                    text: root.selectedDescription
                    elide: Text.ElideRight
                    color: root.expanded ? Design.textOnAccent : (root.devices.length > 0 ? Design.text : Design.textSecondary)
                    font.family: Design.fontFamily
                    role: "body"
                }
                UI.Text {
                    text: root.busy ? "◌" : root.expanded ? "▴" : "▾"
                    color: root.expanded ? Design.textOnAccent : Design.textSecondary
                    role: "section"
                }
            }

        }
    }

    UI.SelectPopup {
        id: devicePopup
        // Draw in the window overlay, outside the selector's layout.
        parent: trigger
        x: 0
        property real slideOffset: 0
        y: trigger.height + 4 + slideOffset
        width: trigger.width
        height: Math.min(choices.implicitHeight, 170) + padding * 2
        visible: root.expanded

        // Let the trigger handle its own toggle instead of closing on press
        // and immediately reopening when its clicked signal arrives.
        onClosed: root.expanded = false

        contentItem: UI.ScrollView {
            contentWidth: availableWidth
            clip: true
            UI.ColumnLayout {
                id: choices
                width: parent.width
                spacing: 0
                Repeater {
                    model: devicePopup.visible ? root.devices : []
                    UI.MenuItem {
                        highlighted: selectedDevice
                        id: choice
                        required property var modelData
                        readonly property bool selectedDevice: modelData.name === root.selectedName
                        Layout.fillWidth: true
                        implicitHeight: Math.max(Design.controlHeight, label.implicitHeight + Design.space16)
                        leftPadding: Design.space12
                        rightPadding: Design.space8
                        onClicked: {
                            const name = modelData.name;
                            root.expanded = false;
                            if (name !== root.selectedName)
                                root.selected(name);
                            trigger.forceActiveFocus();
                        }

                        contentItem: UI.Text {
                            id: label
                            text: (choice.selectedDevice ? "✓  " : "") + choice.modelData.description
                            color: choice.selectedDevice ? Design.textOnAccent : Design.text
                            font.family: Design.fontFamily
                            role: "body"
                            font.bold: choice.selectedDevice
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                        }

                    }
                }
            }
        }
    }
}
