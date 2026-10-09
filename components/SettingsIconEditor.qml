pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../config"

ColumnLayout {
    id: root
    spacing: 10
    property string candidate: ""
    property string errorMessage: ""
    property bool customEditing: false
    readonly property var presets: [
        {name: "Gear", icon: Theme.defaultSettingsIcon},
        {name: "Sliders", icon: ""},
        {name: "Palette", icon: "󰏘"},
        {name: "Grid", icon: ""},
        {name: "Linux", icon: "󰌽"},
        {name: "Arch", icon: "󰣇"}
    ]
    readonly property int selectedPreset: Theme.settingsIconSource ? -1
        : presets.findIndex(preset => preset.icon === Theme.settingsIcon)
    readonly property bool customSelected: customEditing || selectedPreset < 0

    function selectPreset(index) {
        candidate = "";
        errorMessage = "";
        customEditing = false;
        Theme.setSettingsIcon(presets[index].icon, "");
        glyph.text = Theme.settingsIcon;
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Settings button icon"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
        NotificationButton {
            objectName: "settings-icon-reset"
            text: "Reset"
            enabled: Theme.ready
            onClicked: root.selectPreset(0)
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: root.presets.concat([{name: "Custom", icon: "󰏫"}])
            delegate: Button {
                id: option
                required property var modelData
                required property int index
                readonly property bool isCustom: index === root.presets.length
                readonly property bool selected: isCustom ? root.customSelected
                    : !root.customSelected && root.selectedPreset === index
                objectName: "settings-icon-option-" + modelData.name.toLowerCase()
                width: 72
                height: 64
                padding: 6
                topInset: 0
                bottomInset: 0
                enabled: Theme.ready
                hoverEnabled: true
                Accessible.name: modelData.name + " settings icon"
                Accessible.checkable: true
                Accessible.checked: selected
                onClicked: {
                    if (isCustom) {
                        root.customEditing = true;
                        glyph.forceActiveFocus();
                    } else root.selectPreset(index);
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                background: Rectangle {
                    radius: 10
                    color: option.selected || option.hovered ? Theme.overlay : Theme.surface
                    border.width: option.selected ? 2 : 1
                    border.color: option.selected || option.activeFocus ? Theme.iris : Theme.highlightMed
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                contentItem: Column {
                    spacing: 4
                    Item {
                        width: parent.width
                        height: 32
                        SettingsIcon {
                            anchors.centerIn: parent
                            glyph: option.modelData.icon
                            source: ""
                            iconSize: 24
                            color: option.selected ? Theme.iris : Theme.text
                        }
                    }
                    Text {
                        width: parent.width
                        text: option.modelData.name
                        color: option.selected ? Theme.text : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: root.customSelected
        spacing: 10
        Rectangle {
            implicitWidth: 40; implicitHeight: 40
            color: Theme.surface; radius: 10
            SettingsIcon { anchors.centerIn: parent; iconSize: 24; color: Theme.iris }
        }
        TextField {
            id: glyph
            objectName: "settings-icon-glyph"
            Layout.fillWidth: true
            Layout.minimumWidth: 50
            implicitHeight: 36
            text: Theme.settingsIcon
            placeholderText: "Paste an icon glyph"
            maximumLength: 16
            color: Theme.text
            placeholderTextColor: Theme.subtle
            selectionColor: Theme.iris
            selectedTextColor: Theme.bg
            font.family: Theme.fontFamily
            font.pixelSize: 18
            enabled: Theme.ready
            Accessible.name: "Settings icon glyph"
            onEditingFinished: {
                if (root.customSelected && text !== Theme.settingsIcon) Theme.setSettingsIcon(text, "");
            }
            background: Rectangle {
                radius: 8
                color: Theme.surface
                border.color: glyph.activeFocus ? Theme.iris : Theme.highlightMed
            }
        }
        NotificationButton {
            text: "Image…"
            enabled: Theme.ready
            onClicked: picker.open()
        }
    }
    Text {
        Layout.fillWidth: true
        visible: root.customSelected && root.errorMessage !== ""
        text: root.errorMessage
        wrapMode: Text.WordWrap
        color: Theme.love
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
    FileDialog {
        id: picker
        title: "Settings button icon"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.svg *.png *.webp *.jpg *.jpeg *.bmp)"]
        onAccepted: {
            root.errorMessage = "";
            root.candidate = "";
            root.candidate = selectedFile.toString();
        }
    }
    Image {
        visible: false
        source: root.candidate
        sourceSize: Qt.size(64, 64)
        asynchronous: true
        cache: false
        onStatusChanged: {
            if (!root.candidate) return;
            if (status === Image.Ready) {
                Theme.setSettingsIcon(Theme.settingsIcon, root.candidate);
                root.candidate = "";
            } else if (status === Image.Error) {
                root.errorMessage = "Could not open this icon image.";
                root.candidate = "";
            }
        }
    }
}
