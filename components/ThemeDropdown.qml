pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

Item {
    id: root
    property bool expanded: false
    readonly property var activePreset: Theme.presets.find(preset => preset.id === Theme.preset) || Theme.presets[0]
    implicitHeight: 80
    onVisibleChanged: { if (!visible) expanded = false; }

    Button {
        id: trigger
        anchors.fill: parent
        enabled: Theme.ready
        hoverEnabled: true
        leftPadding: 14
        rightPadding: 14
        Accessible.name: "Theme: " + root.activePreset.name
        onClicked: root.expanded = !root.expanded
        HoverHandler { enabled: trigger.enabled; cursorShape: Qt.PointingHandCursor }
        background: Rectangle {
            radius: 10
            color: trigger.hovered || root.expanded ? Theme.overlay : Theme.surface
            border.color: Theme.iris
            border.width: root.expanded || trigger.activeFocus ? 2 : 1
        }
        contentItem: RowLayout {
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 9
                Text {
                    text: root.activePreset.name
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }
                PaletteSwatches {
                    colors: Theme.palette
                    swatchWidth: 28
                    swatchHeight: 14
                }
            }
            Text {
                text: root.expanded ? "▴" : "▾"
                color: Theme.iris
                font.pixelSize: 18
            }
        }
    }

    Popup {
        id: menu
        parent: trigger
        popupType: Popup.Item
        x: 0
        property real slideOffset: 0
        y: trigger.height + 4 + slideOffset
        width: trigger.width
        height: Math.min(choices.implicitHeight + padding * 2, 160)
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
                    target: menu
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
                    target: menu
                    property: "slideOffset"
                    to: -8
                    duration: 110
                    easing.type: Easing.InCubic
                }
            }
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        onClosed: root.expanded = false
        background: Rectangle {
            color: Theme.bg
            border.color: Theme.iris
            radius: 10
        }
        contentItem: ScrollView {
            contentWidth: availableWidth
            clip: true
            ColumnLayout {
                id: choices
                width: parent.width
                spacing: 4
                Repeater {
                    model: Theme.presets
                    Button {
                        id: choice
                        required property var modelData
                        readonly property bool selectedTheme: modelData.id === Theme.preset
                        Layout.fillWidth: true
                        implicitHeight: 38
                        leftPadding: 8
                        rightPadding: 8
                        hoverEnabled: true
                        Accessible.name: modelData.name
                        onClicked: {
                            Theme.selectPreset(modelData.id);
                            root.expanded = false;
                            trigger.forceActiveFocus();
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        background: Rectangle {
                            radius: 6
                            color: choice.selectedTheme ? Theme.iris : (choice.hovered ? Theme.overlay : Theme.surface)
                            border.color: choice.activeFocus ? Theme.text : Theme.highlightMed
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: choice.modelData.name
                                color: choice.selectedTheme ? Theme.bg : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: choice.selectedTheme
                                elide: Text.ElideRight
                            }
                            PaletteSwatches {
                                colors: Theme.preview(choice.modelData.id)
                                swatchWidth: 12
                                swatchHeight: 12
                            }
                        }
                    }
                }
            }
        }
    }
}
