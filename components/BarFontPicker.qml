pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

ColumnLayout {
    id: root
    spacing: 8
    property bool expanded: false
    onVisibleChanged: { if (!visible) expanded = false; }
    readonly property var families: Qt.fontFamilies().sort((a, b) => a.localeCompare(b))
    readonly property var matches: families.filter(name => name.toLowerCase().includes(search.text.trim().toLowerCase()))

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Bar font"
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        NotificationButton {
            objectName: "bar-font-reset"
            text: "Reset"
            enabled: Theme.ready && Theme.barFontFamily !== Theme.defaultBarFontFamily
            onClicked: Theme.setBarFontFamily(Theme.defaultBarFontFamily)
        }
    }
    Button {
        id: trigger
        objectName: "bar-font-picker"
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: 80
        leftPadding: 14
        rightPadding: 14
        topInset: 0
        bottomInset: 0
        enabled: Theme.ready
        hoverEnabled: true
        Accessible.name: "Bar font: " + Theme.barFontFamily
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
                Layout.minimumWidth: 0
                spacing: 9
                Text {
                    Layout.fillWidth: true
                    text: Theme.barFontFamily
                    textFormat: Text.PlainText
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: "The quick brown fox · 12:34 · 100%"
                    color: Theme.subtle
                    font.family: Theme.barFontFamily
                    font.pixelSize: Math.min(Theme.fontSize, 20)
                    elide: Text.ElideRight
                    Accessible.name: "Bar font preview"
                }
            }
            Text {
                text: root.expanded ? "▴" : "▾"
                color: Theme.iris
                font.pixelSize: 18
            }
        }
        Popup {
            id: menu
            parent: trigger
            x: 0
            property real slideOffset: 0
            y: trigger.height + 4 + slideOffset
            width: trigger.width
            height: search.implicitHeight + 8 + Math.min(Math.max(38, choices.contentHeight), 160) + padding * 2
            padding: 6
            margins: 8
            popupType: Popup.Item
            visible: root.expanded
            focus: true
            enter: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
                    NumberAnimation { target: menu; property: "slideOffset"; from: -8; to: 0; duration: 160; easing.type: Easing.OutCubic }
                }
            }
            exit: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
                    NumberAnimation { target: menu; property: "slideOffset"; to: -8; duration: 110; easing.type: Easing.InCubic }
                }
            }
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
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
            background: Rectangle {
                color: Theme.bg
                border.color: Theme.iris
                radius: 10
            }
            contentItem: ColumnLayout {
                spacing: 8
                TextField {
                    id: search
                    objectName: "bar-font-search"
                    Layout.fillWidth: true
                    implicitHeight: 34
                    leftPadding: 8
                    rightPadding: 8
                    placeholderText: "Search installed fonts…"
                    color: Theme.text
                    placeholderTextColor: Theme.subtle
                    selectionColor: Theme.iris
                    selectedTextColor: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
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
                    background: Rectangle { color: Theme.surface; radius: 6; border.color: search.activeFocus ? Theme.iris : Theme.highlightMed }
                }
                ListView {
                    id: choices
                    objectName: "bar-font-choices"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.matches
                    spacing: 4
                    keyNavigationEnabled: true
                    highlightMoveDuration: 0
                    ScrollBar.vertical: ScrollBar {}
                    Keys.onReturnPressed: { if (currentIndex >= 0) root.choose(root.matches[currentIndex]); }
                    Keys.onEnterPressed: { if (currentIndex >= 0) root.choose(root.matches[currentIndex]); }
                    delegate: ItemDelegate {
                        id: option
                        required property string modelData
                        required property int index
                        width: choices.width
                        readonly property bool selectedFont: modelData === Theme.barFontFamily
                        height: 38
                        leftPadding: 8
                        rightPadding: 8
                        highlighted: choices.activeFocus && choices.currentIndex === index
                        hoverEnabled: true
                        Accessible.name: modelData
                        Accessible.checkable: true
                        Accessible.checked: modelData === Theme.barFontFamily
                        onClicked: root.choose(modelData)
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        background: Rectangle {
                            radius: 6
                            color: option.selectedFont ? Theme.iris : option.hovered ? Theme.overlay : Theme.surface
                            border.color: option.highlighted || option.activeFocus ? Theme.text : Theme.highlightMed
                        }
                        contentItem: Text {
                            text: option.modelData
                            textFormat: Text.PlainText
                            color: option.selectedFont ? Theme.bg : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: option.selectedFont
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: choices.count === 0
                        text: "No matching fonts"
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
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
