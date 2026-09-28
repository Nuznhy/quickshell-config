//@ pragma UseQApplication
import Quickshell
import "modules/bar"
import "modules/notifications"
import "modules/wallpaper"
import "modules/settings"

ShellRoot {
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
