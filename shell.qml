//@ pragma UseQApplication
import Quickshell
import "modules/bar"
import "modules/notifications"
import "modules/wallpaper"

ShellRoot {
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
