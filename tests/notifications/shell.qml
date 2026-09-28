import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "components"
import "services"
ShellRoot {
    property int historyChanges: 0
    Connections {
        target: Notifications
        function onEntriesChanged() { historyChanges++; }
    }
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
        function onReloadFailed(error) { Quickshell.inhibitReloadPopup(); }
    }
    FloatingWindow {
        id: host
        signal closeAllPopups
        property var testPopup: null
        visible: true
        implicitWidth: 420
        implicitHeight: center.implicitHeight + 16
        color: "#191724"
        NotificationCenter {
            id: center
            x: 8; y: 8; width: 404
            onDismissed: active = false
        }
        DropdownWidget {
            id: dropdown
            barWindow: host
            // Offscreen has no Hyprland focus-grab protocol. Exercise actual window
            // closure separately from compositor focus behavior.
            focusGrabEnabled: false
            Text { text: "Test popup" }
            popupContent: Rectangle {
                id: popupBody
                color: "#191724"
                Component.onCompleted: host.testPopup = Qt.binding(() => popupBody.QsWindow.window)
            }
        }
    }
    IpcHandler {
        target: "test"
        function snapshot(): string {
            return JSON.stringify({ ready: Notifications.ready, centerActive: center.active, dnd: Notifications.doNotDisturb,
                historyChanges: historyChanges,
                popupOpen: dropdown.dropdownOpen, popupVisible: host.testPopup?.visible || false,
                entries: Notifications.entries, popups: Notifications.popups.length,
                watchers: Object.keys(Notifications.watchers).length });
        }
        function invoke(key: string, action: string): void { Notifications.invoke(key, action); }
        function remove(key: string): void { Notifications.remove(key); }
        function markRead(): void { Notifications.markRead(); }
        function open(): void { center.active = true; }
        function close(): void { center.active = false; }
        function openPopup(): void {
            host.closeAllPopups();
            dropdown.dropdownOpen = true;
        }
        function switchWorkspace(): void { host.closeAllPopups(); }
        function dismissPopup(): void { host.testPopup.contentItem.Window.window.close(); }
        function screenshot(): void {
            center.grabToImage(result => {
                result.saveToFile(Quickshell.env("QS_NOTIFICATION_TEST_DIR") + "/preview.png");
                console.log("Preview saved", center.implicitHeight);
            });
        }
        function quit(): void { Qt.quit(); }
    }
}
