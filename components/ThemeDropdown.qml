pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

Item {
    id: root
    property bool expanded: false
    readonly property var activePreset: Theme.presets.find(preset => preset.id === Theme.preset) || Theme.presets[0]
    implicitHeight: 80
    onVisibleChanged: { if (!visible) expanded = false; }

    UI.Button {
        highlighted: root.expanded
        id: trigger
        anchors.fill: parent
        enabled: Theme.ready
        leftPadding: Design.space12
        rightPadding: Design.space12
        Accessible.name: "Theme: " + root.activePreset.name
        onClicked: root.expanded = !root.expanded

        contentItem: UI.RowLayout {
            UI.ColumnLayout {
                Layout.fillWidth: true
                spacing: Design.space8
                UI.Text {
                    text: root.activePreset.name
                    color: trigger.foreground
                    font.family: Design.fontFamily
                    role: "section"
                    font.bold: true
                }
                PaletteSwatches {
                    colors: Theme.palette
                    swatchWidth: 28
                    swatchHeight: 14
                }
            }
            UI.Text {
                text: root.expanded ? "▴" : "▾"
                color: trigger.foreground
                role: "panel"
            }
        }
    }

    UI.Popup {
        id: menu
        parent: trigger
        x: 0
        property real slideOffset: 0
        y: trigger.height + 4 + slideOffset
        width: trigger.width
        height: Math.min(choices.implicitHeight + padding * 2, 160)
        visible: root.expanded

        onClosed: root.expanded = false

        contentItem: UI.ScrollView {
            contentWidth: availableWidth
            clip: true
            UI.ColumnLayout {
                id: choices
                width: parent.width
                spacing: Design.space4
                Repeater {
                    model: Theme.presets
                    UI.Button {
                        highlighted: selectedTheme
                        id: choice
                        required property var modelData
                        readonly property bool selectedTheme: modelData.id === Theme.preset
                        Layout.fillWidth: true
                        implicitHeight: Design.selectorHeight
                        leftPadding: Design.space8
                        rightPadding: Design.space8
                        Accessible.name: modelData.name
                        onClicked: {
                            Theme.selectPreset(modelData.id);
                            root.expanded = false;
                            trigger.forceActiveFocus();
                        }

                        contentItem: UI.RowLayout {
                            spacing: Design.space8
                            UI.Text {
                                Layout.fillWidth: true
                                text: choice.modelData.name
                                color: choice.selectedTheme ? Design.textOnAccent : Design.text
                                font.family: Design.fontFamily
                                role: "body"
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
