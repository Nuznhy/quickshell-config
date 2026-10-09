pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../config"

UI.ColumnLayout {
    id: root
    spacing: Design.space8
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
    UI.RowLayout {
        Layout.fillWidth: true
        UI.Text {
            Layout.fillWidth: true
            text: "Settings button icon"
            color: Design.text
            font.family: Design.fontFamily
            role: "body"
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
        spacing: Design.space8
        Repeater {
            model: root.presets.concat([{name: "Custom", icon: "󰏫"}])
            delegate: UI.Button {
        highlighted: selected
                id: option
                required property var modelData
                required property int index
                readonly property bool isCustom: index === root.presets.length
                readonly property bool selected: isCustom ? root.customSelected
                    : !root.customSelected && root.selectedPreset === index
                objectName: "settings-icon-option-" + modelData.name.toLowerCase()
                width: 72
                height: 64
                padding: Design.space4
                topInset: 0
                bottomInset: 0
                enabled: Theme.ready
                Accessible.name: modelData.name + " settings icon"
                Accessible.checkable: true
                Accessible.checked: selected
                onClicked: {
                    if (isCustom) {
                        root.customEditing = true;
                        glyph.forceActiveFocus();
                    } else root.selectPreset(index);
                }

                contentItem: Column {
                    spacing: Design.space4
                    Item {
                        width: parent.width
                        height: 32
                        SettingsIcon {
                            anchors.centerIn: parent
                            glyph: option.modelData.icon
                            source: ""
                            iconSize: 24
                            color: option.foreground
                        }
                    }
                    UI.Text {
                        width: parent.width
                        text: option.modelData.name
                        color: option.foreground
                        font.family: Design.fontFamily
                        role: "caption"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
    UI.RowLayout {
        Layout.fillWidth: true
        visible: root.customSelected
        spacing: Design.space8
        UI.Card {
            implicitWidth: 40; implicitHeight: Design.selectorHeight
            SettingsIcon { anchors.centerIn: parent; iconSize: 24; color: Design.accent }
        }
        UI.TextField {
            id: glyph
            objectName: "settings-icon-glyph"
            Layout.fillWidth: true
            Layout.minimumWidth: 50
            text: Theme.settingsIcon
            placeholderText: "Paste an icon glyph"
            maximumLength: 16
            enabled: Theme.ready
            Accessible.name: "Settings icon glyph"
            onEditingFinished: {
                if (root.customSelected && text !== Theme.settingsIcon) Theme.setSettingsIcon(text, "");
            }

        }
        NotificationButton {
            text: "Image…"
            enabled: Theme.ready
            onClicked: picker.open()
        }
    }
    UI.Text {
        Layout.fillWidth: true
        visible: root.customSelected && root.errorMessage !== ""
        text: root.errorMessage
        wrapMode: Text.WordWrap
        color: Design.danger
        font.family: Design.fontFamily
        role: "label"
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
