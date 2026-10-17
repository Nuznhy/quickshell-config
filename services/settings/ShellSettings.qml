pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool opened: false
    signal activateRequested
    function open() { opened = true; activateRequested(); }
    function close() { opened = false; }
    function toggle() { if (opened) close(); else open(); }
    IpcHandler {
        target: "settings"
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
    }
}
