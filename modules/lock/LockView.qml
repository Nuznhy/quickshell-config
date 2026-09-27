import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    required property var authentication
    property color backgroundColor: "#191724"
    property color textColor: "#e0def4"
    property color accentColor: "#c4a7e7"
    property string username: ""
    property string errorMessage: ""
    signal submitted(string response)
    color: backgroundColor
    function clearInput() { password.clear(); password.forceActiveFocus(); }
    Connections {
        target: root.authentication
        function onActiveChanged() { if (!root.authentication.active) root.clearInput(); }
    }
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(360, parent.width - 48)
        spacing: 20
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰌾"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 56
            color: root.accentColor
        }
        Text {
            Layout.fillWidth: true
            text: root.username
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            color: root.textColor
            font.pixelSize: 22
        }
        TextField {
            id: password
            Layout.fillWidth: true
            implicitHeight: 48
            focus: true
            enabled: !root.authentication.active || root.authentication.responseRequired
            onEnabledChanged: { if (enabled) forceActiveFocus(); }
            echoMode: root.authentication.responseRequired && root.authentication.responseVisible ? TextInput.Normal : TextInput.Password
            placeholderText: root.authentication.responseRequired ? root.authentication.message : "Password"
            color: root.textColor
            placeholderTextColor: Qt.alpha(root.textColor, 0.6)
            font.pixelSize: 16
            leftPadding: 14
            rightPadding: 14
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            background: Rectangle { radius: 10; color: Qt.alpha(root.textColor, 0.06); border.color: root.accentColor }
            onAccepted: { const response = text; clear(); root.submitted(response); }
            Component.onCompleted: forceActiveFocus()
        }
        Button {
            id: unlock
            Layout.fillWidth: true
            implicitHeight: 44
            enabled: password.enabled
            text: root.authentication.active && !root.authentication.responseRequired ? "Authenticating…" : "Unlock"
            onClicked: { const response = password.text; password.clear(); root.submitted(response); }
            background: Rectangle { radius: 10; color: root.accentColor; opacity: unlock.enabled ? 1 : 0.5 }
            contentItem: Text { text: unlock.text; color: root.backgroundColor; font.pixelSize: 15; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        Text {
            Layout.fillWidth: true
            text: root.errorMessage
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            color: root.textColor
            visible: text.length > 0
        }
    }
}
