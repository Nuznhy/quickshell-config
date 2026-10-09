import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../config"
import "../services"

UI.ColumnLayout {
    id: root
    spacing: Design.space12
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
    UI.RowLayout {
        Layout.fillWidth: true
        UI.Text {
            Layout.fillWidth: true
            text: "Sync shell theme"
            wrapMode: Text.WordWrap
            color: Design.text
            font.family: Design.fontFamily
            role: "section"
        }
        ControlSwitch {
            objectName: "lock-theme-sync"
            value: !!root.target?.enabled
            enabled: Theme.ready && !!root.target && (root.target.available || value) && !AppTheming.isApplying("hyprlock")
            Accessible.name: "Sync Hyprlock with the shell theme"
            onChangeRequested: value => AppTheming.setEnabled("hyprlock", value)
        }
    }
    UI.RowLayout {
        Layout.fillWidth: true
        visible: !!AppTheming.errorMessage || root.target?.state === "error" || (!!root.target && !root.target.available)
        UI.Text {
            Layout.fillWidth: true
            text: AppTheming.errorMessage || root.target?.message || ""
            color: root.target?.state === "error" || AppTheming.errorMessage ? Design.danger : Design.textSecondary
            wrapMode: Text.WordWrap
            font.family: Design.fontFamily
            role: "body"
        }
        NotificationButton {
            text: "Retry"
            visible: root.target?.state === "error"
            enabled: !AppTheming.busy
            onClicked: AppTheming.retry("hyprlock")
        }
    }
    UI.Text { text: "Background"; color: Design.text; font.family: Design.fontFamily; role: "section" }
    UI.RowLayout {
        spacing: Design.space8
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
    UI.RowLayout {
        visible: Theme.lockBackgroundMode === "color"
        UI.TextField {
            id: colorInput
            objectName: "lock-color-input"
            text: Theme.lockBackgroundColor
            placeholderText: "#RRGGBB"
            maximumLength: 7
            Accessible.name: "Lock-screen background color in hex"
            validator: RegularExpressionValidator { regularExpression: /#[0-9a-fA-F]{6}/ }
            invalid: length > 0 && !acceptableInput
            onTextEdited: { if (acceptableInput) Theme.setLockBackground("color", text); }
            onEditingFinished: text = Qt.binding(() => Theme.lockBackgroundColor)

        }
        Rectangle { width: 30; height: 30; radius: Design.radiusControl; color: Theme.lockBackgroundColor; border.color: Design.border }
    }
    UI.RowLayout {
        visible: Theme.lockBackgroundMode === "image"
        Layout.fillWidth: true
        NotificationButton { text: "Choose picture…"; onClicked: picker.open() }
        UI.Text {
            Layout.fillWidth: true
            text: root.pictureName()
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            color: Design.textSecondary
            font.family: Design.fontFamily
            role: "body"
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 210
        color: Theme.lockBackgroundMode === "color" ? Theme.lockBackgroundColor : Design.background
        radius: Design.radiusCard
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
            width: 260; height: 166; radius: Design.radiusCard
            color: Design.background
            Column {
                anchors.centerIn: parent
                spacing: Design.space12
                UI.Text { anchors.horizontalCenter: parent.horizontalCenter; text: "12:34"; color: Design.text; font.pixelSize: 28; font.family: Design.fontFamily }
                Rectangle {
                    width: 210; height: 32; radius: Design.radiusControl; color: Design.surface; border.color: Design.accent
                    UI.Text { anchors.centerIn: parent; text: "Password"; color: Design.text; font.family: Design.fontFamily; role: "label" }
                }
                UI.Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Keyboard layout: …"; color: Design.warning; font.family: Design.fontFamily; role: "label" }
                UI.Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Caps Lock: off"; color: Design.warning; font.family: Design.fontFamily; role: "label" }
            }
        }
    }
    UI.Text {
        Layout.fillWidth: true
        visible: root.errorMessage.length > 0
        text: root.errorMessage
        color: Design.danger
        font.family: Design.fontFamily
        role: "body"
        wrapMode: Text.WordWrap
    }
}
