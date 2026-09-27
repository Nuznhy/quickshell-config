//@ pragma UseQApplication
import Quickshell
import "modules/bar"
import "modules/notifications"

ShellRoot {
    NotificationToasts {}
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            assignedScreen: modelData
        }
    }
}
