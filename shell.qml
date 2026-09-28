//@ pragma UseQApplication
import Quickshell
import QtQuick
import "modules/bar"
import "modules/notifications"
import "modules/wallpaper"
import "modules/settings"
import "services"

ShellRoot {
    Component.onCompleted: AppTheming.refresh()
    SettingsWindow {}
    Wallpapers {}
    NotificationToasts {}
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            assignedScreen: modelData
        }
    }
}
