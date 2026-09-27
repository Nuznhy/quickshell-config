import QtQuick
import Quickshell
import Quickshell.Io
import "components"
import "services"
ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
        function onReloadFailed(error) { Quickshell.inhibitReloadPopup(); }
    }
    FloatingWindow {
        id: host
        visible: true
        implicitWidth: 420
        implicitHeight: center.implicitHeight + 16
        color: "#191724"
        NotificationCenter {
            id: center
            x: 8; y: 8; width: 404
            onDismissed: active = false
        }
    }
    IpcHandler {
        target: "test"
        function snapshot(): string {
            return JSON.stringify({ ready: Notifications.ready, centerActive: center.active, dnd: Notifications.doNotDisturb,
                entries: Notifications.entries, popups: Notifications.popups.length,
                watchers: Object.keys(Notifications.watchers).length });
        }
        function invoke(key: string, action: string): void { Notifications.invoke(key, action); }
        function remove(key: string): void { Notifications.remove(key); }
        function markRead(): void { Notifications.markRead(); }
        function open(): void { center.active = true; }
        function close(): void { center.active = false; }
        function screenshot(): void {
            center.grabToImage(result => {
                result.saveToFile(Quickshell.env("QS_NOTIFICATION_TEST_DIR") + "/preview.png");
                console.log("Preview saved", center.implicitHeight);
            });
        }
        function quit(): void { Qt.quit(); }
    }
}
