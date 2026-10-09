pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

UI.ColumnLayout {
    id: root
    spacing: Design.space8
    property bool expanded: false
    onVisibleChanged: { if (!visible) expanded = false; }
    readonly property var families: Qt.fontFamilies().sort((a, b) => a.localeCompare(b))
    readonly property var matches: families.filter(name => name.toLowerCase().includes(search.text.trim().toLowerCase()))

    UI.RowLayout {
        Layout.fillWidth: true
        UI.Text {
            Layout.fillWidth: true
            text: "Bar font"
            color: Design.textSecondary
            font.family: Design.fontFamily
            role: "label"
        }
        NotificationButton {
            objectName: "bar-font-reset"
            text: "Reset"
            enabled: Theme.ready && Theme.barFontFamily !== Theme.defaultBarFontFamily
            onClicked: Theme.setBarFontFamily(Theme.defaultBarFontFamily)
        }
    }
    UI.Button {
        highlighted: root.expanded
        id: trigger
        background: UI.SelectTriggerSurface { control: trigger; selected: trigger.highlighted; reveal: menu.reveal }
        objectName: "bar-font-picker"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: 80
        leftPadding: Design.space12
        rightPadding: Design.space12
        topInset: 0
        bottomInset: 0
        enabled: Theme.ready
        Accessible.name: "Bar font: " + Theme.barFontFamily
        onClicked: root.expanded = !root.expanded

        contentItem: UI.RowLayout {
            UI.ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Design.space8
                UI.Text {
                    Layout.fillWidth: true
                    text: Theme.barFontFamily
                    textFormat: Text.PlainText
                    color: trigger.foreground
                    font.family: Design.fontFamily
                    role: "section"
                    font.bold: true
                    elide: Text.ElideRight
                }
                UI.Text {
                    role: "bar"
                    Layout.fillWidth: true
                    text: "The quick brown fox · 12:34 · 100%"
                    color: Design.textSecondary
                    font.family: Theme.barFontFamily
                    font.pixelSize: Math.min(Theme.fontSize, 20)
                    elide: Text.ElideRight
                    Accessible.name: "Bar font preview"
                }
            }
            UI.Text {
                text: root.expanded ? "▴" : "▾"
                color: trigger.foreground
                role: "panel"
            }
        }
        UI.SelectPopup {
            id: menu
            parent: trigger
            x: 0
            y: trigger.height - Design.borderWidth
            width: trigger.width
            height: search.implicitHeight + Design.space16 + Math.min(Math.max(Design.controlHeight, choices.contentHeight), 160) + padding * 2
            visible: root.expanded

            onOpened: {
                search.clear();
                choices.currentIndex = root.matches.indexOf(Theme.barFontFamily);
                choices.positionViewAtIndex(Math.max(0, choices.currentIndex), ListView.Contain);
                search.forceActiveFocus();
            }
            onClosed: {
                root.expanded = false;
                if (root.visible) trigger.forceActiveFocus();
            }

            contentItem: UI.ColumnLayout {
                spacing: 0
                UI.TextField {
                    id: search
                    objectName: "bar-font-search"
                    Layout.margins: Design.space8
                    Layout.fillWidth: true
                    placeholderText: "Search installed fonts…"
                    Accessible.name: "Search installed bar fonts"
                    onTextChanged: choices.currentIndex = root.matches.length ? 0 : -1
                    Keys.onDownPressed: {
                        if (choices.count) {
                            choices.currentIndex = Math.max(0, choices.currentIndex);
                            choices.forceActiveFocus();
                        }
                    }
                    onAccepted: {
                        if (choices.currentIndex >= 0) root.choose(root.matches[choices.currentIndex]);
                    }

                }
                ListView {
                    id: choices
                    objectName: "bar-font-choices"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.matches
                    spacing: 0
                    keyNavigationEnabled: true
                    highlightMoveDuration: 0
                    ScrollBar.vertical: UI.ScrollBar {}
                    Keys.onReturnPressed: { if (currentIndex >= 0) root.choose(root.matches[currentIndex]); }
                    Keys.onEnterPressed: { if (currentIndex >= 0) root.choose(root.matches[currentIndex]); }
                    delegate: UI.MenuItem {
                        id: option
                        required property string modelData
                        required property int index
                        width: choices.width
                        readonly property bool selectedFont: modelData === Theme.barFontFamily
                        height: Design.controlHeight
                        leftPadding: Design.space8
                        rightPadding: Design.space8
                        highlighted: selectedFont || (choices.activeFocus && choices.currentIndex === index)
                        hoverEnabled: true
                        Accessible.name: modelData
                        Accessible.checkable: true
                        Accessible.checked: modelData === Theme.barFontFamily
                        onClicked: root.choose(modelData)

                        contentItem: UI.Text {
                            text: option.modelData
                            textFormat: Text.PlainText
                            color: option.foreground
                            font.family: Design.fontFamily
                            role: "body"
                            font.bold: option.selectedFont
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                    UI.Text {
                        anchors.centerIn: parent
                        visible: choices.count === 0
                        text: "No matching fonts"
                        color: Design.textSecondary
                        font.family: Design.fontFamily
                        role: "body"
                    }
                }
            }
        }
    }
    function choose(family) {
        Theme.setBarFontFamily(family);
        root.expanded = false;
        trigger.forceActiveFocus();
    }
}
