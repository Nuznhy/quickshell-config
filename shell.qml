//@ pragma UseQApplication
import Quickshell
import QtQuick
import qs.modules.bar
import qs.modules.notifications
import qs.modules.wallpaper
import qs.modules.settings
import qs.services.appearance
import qs.services.wallpaper

ShellRoot {
    Component.onCompleted: {
        AppTheming.refresh();
        WallpaperTheme.initialize();
    }
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
