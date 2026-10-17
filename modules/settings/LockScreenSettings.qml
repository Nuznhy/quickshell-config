import QtQuick
import qs.components.shared
import qs.components.ui as UI
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.config
import qs.services.appearance

UI.ColumnLayout {
    id: root
    spacing: Design.space12
    readonly property var target: AppTheming.targets.find(t => t.id === "hyprlock") || null
    property string candidate: ""
    property string errorMessage: ""
    onVisibleChanged: {
        if (visible)
            AppTheming.refresh();
    }

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
        if (!Theme.lockBackgroundImage)
            return "No picture selected";
        const name = Theme.lockBackgroundImage.slice(Theme.lockBackgroundImage.lastIndexOf("/") + 1);
        try {
            return decodeURIComponent(name);
        } catch (error) {
            return name;
        }
    }
    Image {
        source: root.candidate
        visible: false
        asynchronous: true
        cache: false
        sourceSize: Qt.size(640, 360)
        onStatusChanged: {
            if (!root.candidate)
                return;
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
    UI.RowLayout {
        Layout.fillWidth: true
        UI.Text {
            Layout.fillWidth: true
            text: "Clock, local Codex activity, and current media. Changes appear on the next lock."
            wrapMode: Text.WordWrap
            color: Design.textSecondary
            role: "body"
        }
        NotificationButton {
            text: "Reapply"
            enabled: !!root.target?.enabled && !AppTheming.busy
            onClicked: AppTheming.retry("hyprlock")
        }
    }
    UI.Text {
        text: "Background"
        color: Design.text
        font.family: Design.fontFamily
        role: "section"
    }
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
                if (Theme.lockBackgroundImage)
                    root.selectMode("image");
                else
                    picker.open();
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
            validator: RegularExpressionValidator {
                regularExpression: /#[0-9a-fA-F]{6}/
            }
            invalid: length > 0 && !acceptableInput
            onTextEdited: {
                if (acceptableInput)
                    Theme.setLockBackground("color", text);
            }
            onEditingFinished: text = Qt.binding(() => Theme.lockBackgroundColor)
        }
        Rectangle {
            width: 30
            height: 30
            radius: Design.radiusControl
            color: Theme.lockBackgroundColor
            border.color: Design.border
        }
    }
    UI.RowLayout {
        visible: Theme.lockBackgroundMode === "image"
        Layout.fillWidth: true
        NotificationButton {
            text: "Choose picture…"
            onClicked: picker.open()
        }
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
        Layout.preferredHeight: Theme.lockAsciiEnabled && Theme.lockAsciiText.trim() ? 310 : 210
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
            width: 260
            height: parent.height - 44
            radius: Design.radiusCard
            color: Design.background
            Column {
                anchors.centerIn: parent
                spacing: Design.space12
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: Theme.lockAsciiEnabled && Theme.lockAsciiText.trim().length > 0
                    text: Theme.lockAsciiText
                    textFormat: Text.PlainText
                    font.family: "monospace"
                    width: 230
                    height: 100
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 1
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    color: Design.accent
                }
                UI.Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "12:34"
                    color: Design.text
                    font.pixelSize: 28
                    font.family: Design.fontFamily
                }
                Rectangle {
                    width: 210
                    height: 32
                    radius: Design.radiusControl
                    color: Design.surface
                    border.color: Design.accent
                    UI.Text {
                        anchors.centerIn: parent
                        text: "Password"
                        color: Design.text
                        font.family: Design.fontFamily
                        role: "label"
                    }
                }
                UI.Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Keyboard layout: …"
                    color: Design.warning
                    font.family: Design.fontFamily
                    role: "label"
                }
                UI.Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Caps Lock: off"
                    color: Design.warning
                    font.family: Design.fontFamily
                    role: "label"
                }
            }
        }
    }
    UI.RowLayout {
        Layout.fillWidth: true
        UI.Text {
            Layout.fillWidth: true
            text: "Show ASCII art"
            color: Design.text
            role: "section"
        }
        ControlSwitch {
            objectName: "lock-ascii-enabled"
            value: Theme.lockAsciiEnabled
            enabled: Theme.ready
            Accessible.name: "Show ASCII art on the lock screen"
            onChangeRequested: value => Theme.setLockAscii(value, Theme.lockAsciiText)
        }
    }
    UI.Text {
        Layout.fillWidth: true
        text: "Paste ASCII or Unicode/Braille art, up to 64 lines of 160 characters. Large art appears beside the clock and unlock controls. Enable theme sync to apply on the next lock."
        wrapMode: Text.WordWrap
        color: Design.textSecondary
        role: "body"
    }
    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: 160
        TextArea {
            id: asciiInput
            objectName: "lock-ascii-input"
            text: Theme.lockAsciiText
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.NoWrap
            font.family: "monospace"
            font.pixelSize: 14
            color: Design.text
            selectByMouse: true
            placeholderText: "Paste ASCII art here"
            Accessible.name: "Lock-screen ASCII art"
            function isValidArt(value) {
                return value.split("\n").length <= 64 && value.split("\n").every(line => Array.from(line).length <= 160) && !/[\x00-\x09\x0b-\x1f\x7f-\x9f\u00ad\u061c\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]/.test(value);
            }
            readonly property bool validArt: isValidArt(text)
            onTextChanged: {
                if (isValidArt(text) && text !== Theme.lockAsciiText)
                    Theme.setLockAscii(Theme.lockAsciiEnabled, text);
            }
            background: Rectangle {
                color: Design.surface
                radius: Design.radiusControl
                border.color: asciiInput.validArt ? Design.border : Design.danger
            }
        }
    }
    NotificationButton {
        text: "Import quoted lines"
        onClicked: {
            try {
                let source = asciiInput.text.trim();
                if (!source.startsWith("["))
                    source = "[" + source.replace(/,\s*$/, "") + "]";
                const lines = JSON.parse(source);
                if (!Array.isArray(lines) || !lines.every(line => typeof line === "string"))
                    throw new Error();
                const art = lines.join("\n");
                if (!asciiInput.isValidArt(art))
                    throw new Error();
                asciiInput.text = art;
                root.errorMessage = "";
            } catch (error) {
                root.errorMessage = "Paste a list of double-quoted lines, separated by commas, then import again.";
            }
        }
    }
    UI.Text {
        Layout.fillWidth: true
        visible: !asciiInput.validArt
        text: "Use at most 64 lines of 160 characters, without control characters. This edit has not been saved."
        wrapMode: Text.WordWrap
        color: Design.danger
        role: "body"
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
