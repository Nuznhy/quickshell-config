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
    property string widgetSettings: ""
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
                onClicked: { root.widgetSettings = ""; pages.currentIndex = 0; }
            }
            NotificationButton {
                text: "Appearance"
                accent: pages.currentIndex === 1
                onClicked: pages.currentIndex = 1
            }
            NotificationButton {
                objectName: "wallpapers-tab"
                text: "Wallpapers"
                accent: pages.currentIndex === 2
                onClicked: pages.currentIndex = 2
            }
            NotificationButton {
                objectName: "lock-screen-tab"
                text: "Lock screen"
                accent: pages.currentIndex === 3
                onClicked: pages.currentIndex = 3
            }
            Item { Layout.fillWidth: true }
        }
        StackLayout {
            id: pages
            Layout.fillWidth: true
            Layout.fillHeight: true
            StackLayout {
                currentIndex: root.widgetSettings === "monitoring" ? 1 : root.widgetSettings === "workspaces" ? 2 : 0
                BarLayoutEditor {
                    id: editor
                    onSettingsRequested: widgetId => { root.widgetSettings = widgetId; }
                }
                ScrollView {
                    id: monitoringScroll
                    clip: true
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 4
                    bottomPadding: 16
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    MonitoringSettings {
                        width: monitoringScroll.availableWidth
                        active: root.visible && pages.currentIndex === 0 && root.widgetSettings === "monitoring"
                        onBackRequested: root.widgetSettings = ""
                    }
                }
                ScrollView {
                    id: workspaceScroll
                    clip: true
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 4
                    bottomPadding: 16
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    WorkspaceSettingsPanel {
                        width: workspaceScroll.availableWidth
                        onBackRequested: root.widgetSettings = ""
                    }
                }
            }
            ScrollView {
                id: appearanceScroll
                clip: true
                leftPadding: 16
                rightPadding: 16
                topPadding: 4
                bottomPadding: 16
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ThemePicker {
                    width: appearanceScroll.availableWidth
                    onDismissed: ShellSettings.close()
                }
            }
            ScrollView {
                id: wallpaperScroll
                clip: true
                leftPadding: 16
                rightPadding: 16
                topPadding: 4
                bottomPadding: 16
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                WallpaperPage {
                    width: wallpaperScroll.availableWidth
                    onDismissed: ShellSettings.close()
                }
            }
            ScrollView {
                id: lockScroll
                clip: true
                leftPadding: 16
                rightPadding: 16
                topPadding: 4
                bottomPadding: 16
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                LockScreenSettings { width: lockScroll.availableWidth }
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
