pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../components"
import "../../config"
import "../../services"

PanelWindow {
    id: root
    screen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
    anchors { top: true; right: true }
    margins.top: Settings.barHeight + Theme.barTopMargin + 12
    margins.right: Theme.barSideMargin + 16
    implicitWidth: 390
    implicitHeight: Math.min(stack.implicitHeight, (screen?.height || 800) - margins.top - 24)
    visible: Notifications.popups.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notifications"
    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        Column {
            id: stack
            width: scroll.availableWidth
            spacing: 8
            Repeater {
                model: Notifications.popups
                NotificationCard {
                    required property var modelData
                    width: stack.width
                    entry: modelData
                    toast: true
                    onDismissed: {
                        Notifications.patch(entry.key, { read: true, popup: false });
                        const watcher = Notifications.watchers[entry.key];
                        if (watcher) watcher.notification.dismiss();
                    }
                    opacity: 0
                    Component.onCompleted: opacity = 1
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
            }
        }
    }
}
