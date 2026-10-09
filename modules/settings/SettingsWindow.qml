import QtQuick
import "../../components/ui" as UI
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
    color: Design.background
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
    UI.ColumnLayout {
        anchors.fill: parent
        anchors.margins: Design.space20
        spacing: Design.space16
        UI.RowLayout {
            Layout.fillWidth: true
            UI.Text {
                text: "Settings"
                color: Design.text
                font.family: Design.fontFamily
                role: "page"
                font.bold: true
                Layout.fillWidth: true
            }
            UI.IconButton {
                text: "×"
                Accessible.name: "Close settings"
                onClicked: ShellSettings.close()
            }
        }
        UI.RowLayout {
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
                UI.ScrollView {
                    id: monitoringScroll
                    clip: true
                    leftPadding: Design.space16
                    rightPadding: Design.space16
                    topPadding: Design.space4
                    bottomPadding: Design.space16
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    MonitoringSettings {
                        width: monitoringScroll.availableWidth
                        active: root.visible && pages.currentIndex === 0 && root.widgetSettings === "monitoring"
                        onBackRequested: root.widgetSettings = ""
                    }
                }
                UI.ScrollView {
                    id: workspaceScroll
                    clip: true
                    leftPadding: Design.space16
                    rightPadding: Design.space16
                    topPadding: Design.space4
                    bottomPadding: Design.space16
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    WorkspaceSettingsPanel {
                        width: workspaceScroll.availableWidth
                        onBackRequested: root.widgetSettings = ""
                    }
                }
            }
            UI.ScrollView {
                id: appearanceScroll
                clip: true
                leftPadding: Design.space16
                rightPadding: Design.space16
                topPadding: Design.space4
                bottomPadding: Design.space16
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ThemePicker {
                    width: appearanceScroll.availableWidth
                    onDismissed: ShellSettings.close()
                }
            }
            UI.ScrollView {
                id: wallpaperScroll
                clip: true
                leftPadding: Design.space16
                rightPadding: Design.space16
                topPadding: Design.space4
                bottomPadding: Design.space16
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                WallpaperPage {
                    width: wallpaperScroll.availableWidth
                    onDismissed: ShellSettings.close()
                }
            }
            UI.ScrollView {
                id: lockScroll
                clip: true
                leftPadding: Design.space16
                rightPadding: Design.space16
                topPadding: Design.space4
                bottomPadding: Design.space16
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                LockScreenSettings { width: lockScroll.availableWidth }
            }
        }
        UI.Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: [BarLayout.errorMessage, Theme.errorMessage].filter(message => message !== "").join("\n")
            color: Design.danger
            font.family: Design.fontFamily
            role: "body"
            wrapMode: Text.WordWrap
        }
    }
}
