import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root
    property string pendingResponse: ""
    property bool hasPendingResponse: false
    property string errorMessage: ""
    Component.onCompleted: Quickshell.watchFiles = false
    function submit(response) {
        if (pam.active) {
            if (pam.responseRequired) pam.respond(response);
            return;
        }
        errorMessage = "";
        pendingResponse = response;
        hasPendingResponse = true;
        if (!pam.start()) {
            pendingResponse = "";
            hasPendingResponse = false;
            errorMessage = "Could not start authentication. Try again.";
        }
    }
    PamContext {
        id: pam
        config: "login"
        onPamMessage: {
            if (responseRequired && root.hasPendingResponse) {
                const response = root.pendingResponse;
                root.pendingResponse = "";
                root.hasPendingResponse = false;
                respond(response);
            }
        }
        onCompleted: result => {
            root.pendingResponse = "";
            root.hasPendingResponse = false;
            if (result === PamResult.Success) {
                lock.locked = false;
                Qt.quit();
            } else root.errorMessage = "Authentication failed. Try again.";
        }
    }
    WlSessionLock {
        id: lock
        locked: true
        WlSessionLockSurface {
            LockView {
                anchors.fill: parent
                authentication: pam
                username: Quickshell.env("USER")
                backgroundColor: Quickshell.env("QS_LOCK_BG") || "#191724"
                textColor: Quickshell.env("QS_LOCK_TEXT") || "#e0def4"
                accentColor: Quickshell.env("QS_LOCK_ACCENT") || "#c4a7e7"
                errorMessage: root.errorMessage
                onSubmitted: response => root.submit(response)
            }
        }
    }
    IpcHandler {
        target: "lock"
        function status(): string { return lock.secure ? "secure" : "pending"; }
    }
}
