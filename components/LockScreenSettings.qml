import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../config"
import "../services"

ColumnLayout {
    id: root
    spacing: 14
    readonly property var target: AppTheming.targets.find(t => t.id === "hyprlock") || null
    property string candidate: ""
    property string errorMessage: ""
    onVisibleChanged: { if (visible) AppTheming.refresh(); }

    function selectMode(mode) {
        candidate = "";
        errorMessage = "";
        Theme.setLockBackground("mode", mode);
    }

    function chooseImage(source) {
        candidate = "";
        errorMessage = "";
        if (!source.startsWith("file:///") || !/\.(png|jpe?g|webp)$/i.test(source)) {
            errorMessage = "Choose a local PNG, JPEG, or WebP picture.";
            return;
        }
        try {
            const path = decodeURIComponent(source.slice(7));
            if (/[\r\n\x00$#{}]/.test(path) || path !== path.trim()) {
                root.errorMessage = "Rename the picture or folder to remove $, #, braces, or extra whitespace.";
                return;
            }
        } catch (error) {
            root.errorMessage = "Could not read this picture's path.";
            return;
        }
        candidate = source;
    }
    function pictureName() {
        if (!Theme.lockBackgroundImage) return "No picture selected";
        const name = Theme.lockBackgroundImage.slice(Theme.lockBackgroundImage.lastIndexOf("/") + 1);
        try { return decodeURIComponent(name); } catch (error) { return name; }
    }
    Image {
        source: root.candidate
        visible: false
        asynchronous: true
        cache: false
        sourceSize: Qt.size(640, 360)
        onStatusChanged: {
            if (!root.candidate) return;
            if (status === Image.Ready) {
                Theme.setLockBackground("image", root.candidate);
                Theme.setLockBackground("mode", "image");
                root.candidate = "";
            } else if (status === Image.Error) {
                root.errorMessage = "Could not open this picture. The previous background is unchanged.";
                root.candidate = "";
            }
        }
    }
    FileDialog {
        id: picker
        title: "Lock-screen picture"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Pictures (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: root.chooseImage(selectedFile.toString())
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Sync shell theme"
            wrapMode: Text.WordWrap
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }
        ControlSwitch {
            objectName: "lock-theme-sync"
            value: !!root.target?.enabled
            enabled: Theme.ready && !!root.target && (root.target.available || value) && !AppTheming.isApplying("hyprlock")
            Accessible.name: "Sync Hyprlock with the shell theme"
            onChangeRequested: value => AppTheming.setEnabled("hyprlock", value)
        }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: !!AppTheming.errorMessage || root.target?.state === "error" || (!!root.target && !root.target.available)
        Text {
            Layout.fillWidth: true
            text: AppTheming.errorMessage || root.target?.message || ""
            color: root.target?.state === "error" || AppTheming.errorMessage ? Theme.love : Theme.subtle
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
        NotificationButton {
            text: "Retry"
            visible: root.target?.state === "error"
            enabled: !AppTheming.busy
            onClicked: AppTheming.retry("hyprlock")
        }
    }
    Text { text: "Background"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 16 }
    RowLayout {
        spacing: 8
        NotificationButton {
            objectName: "lock-background-theme"
            text: "Theme color"
            accent: Theme.lockBackgroundMode === "theme"
            onClicked: root.selectMode("theme")
        }
        NotificationButton {
            objectName: "lock-background-color"
            text: "Plain color"
            accent: Theme.lockBackgroundMode === "color"
            onClicked: root.selectMode("color")
        }
        NotificationButton {
            objectName: "lock-background-image"
            text: "Picture"
            accent: Theme.lockBackgroundMode === "image"
            onClicked: {
                if (Theme.lockBackgroundImage) root.selectMode("image");
                else picker.open();
            }
        }
    }
    RowLayout {
        visible: Theme.lockBackgroundMode === "color"
        TextField {
            id: colorInput
            objectName: "lock-color-input"
            text: Theme.lockBackgroundColor
            placeholderText: "#RRGGBB"
            maximumLength: 7
            color: Theme.text
            font.family: Theme.fontFamily
            Accessible.name: "Lock-screen background color in hex"
            validator: RegularExpressionValidator { regularExpression: /#[0-9a-fA-F]{6}/ }
            onTextEdited: { if (acceptableInput) Theme.setLockBackground("color", text); }
            onEditingFinished: text = Qt.binding(() => Theme.lockBackgroundColor)
            background: Rectangle { color: Theme.surface; border.color: colorInput.activeFocus ? Theme.iris : Theme.highlightMed; radius: 8 }
        }
        Rectangle { width: 30; height: 30; radius: 6; color: Theme.lockBackgroundColor; border.color: Theme.highlightMed }
    }
    RowLayout {
        visible: Theme.lockBackgroundMode === "image"
        Layout.fillWidth: true
        NotificationButton { text: "Choose picture…"; onClicked: picker.open() }
        Text {
            Layout.fillWidth: true
            text: root.pictureName()
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 210
        color: Theme.lockBackgroundMode === "color" ? Theme.lockBackgroundColor : Theme.bg
        radius: 10
        clip: true
        Image {
            anchors.fill: parent
            source: Theme.lockBackgroundMode === "image" ? Theme.lockBackgroundImage : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(800, 450)
            asynchronous: true
        }
        Rectangle {
            anchors.centerIn: parent
            width: 260; height: 166; radius: 12
            color: Theme.bg
            Column {
                anchors.centerIn: parent
                spacing: 12
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "12:34"; color: Theme.text; font.pixelSize: 28; font.family: Theme.fontFamily }
                Rectangle {
                    width: 210; height: 32; radius: 6; color: Theme.surface; border.color: Theme.iris
                    Text { anchors.centerIn: parent; text: "Password"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 11 }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Keyboard layout: …"; color: Theme.gold; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Caps Lock: off"; color: Theme.gold; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: root.errorMessage.length > 0
        text: root.errorMessage
        color: Theme.love
        font.family: Theme.fontFamily
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
}
