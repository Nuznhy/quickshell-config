import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../components"

FloatingWindow {
    id: root
    title: "Quickshell Settings"
    implicitWidth: 900
    implicitHeight: 720
    minimumSize: Qt.size(640, 480)
    color: Theme.bg
    visible: ShellSettings.opened && Theme.ready
    onClosed: ShellSettings.close()
    onVisibleChanged: {
        if (visible) Qt.callLater(activate);
        else editor.cancelDrag();
    }
    function activate() {
        if (!visible) return;
        minimized = false;
        contentItem.Window.window?.raise();
        contentItem.Window.window?.requestActivate();
    }
    Connections {
        target: ShellSettings
        function onActivateRequested() { Qt.callLater(root.activate); }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Settings"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
            }
            NotificationButton {
                text: "×"
                Accessible.name: "Close settings"
                onClicked: ShellSettings.close()
            }
        }
        RowLayout {
            NotificationButton {
                text: "Bar layout"
                accent: pages.currentIndex === 0
                onClicked: pages.currentIndex = 0
            }
            NotificationButton {
                text: "Appearance"
                accent: pages.currentIndex === 1
                onClicked: pages.currentIndex = 1
            }
            Item { Layout.fillWidth: true }
        }
        StackLayout {
            id: pages
            Layout.fillWidth: true
            Layout.fillHeight: true
            BarLayoutEditor { id: editor }
            ScrollView {
                id: appearanceScroll
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ThemePicker {
                    width: appearanceScroll.availableWidth
                    onDismissed: ShellSettings.close()
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: [BarLayout.errorMessage, Theme.errorMessage].filter(message => message !== "").join("\n")
            color: Theme.love
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }
}
