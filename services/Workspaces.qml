pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../config"
import "WorkspaceWindows.js" as WorkspaceWindows
import "WorkspacePreviewData.js" as PreviewData

Singleton {
    id: root
    // Store windows per workspace
    property var workspaceIcons: ({})
    property var pendingWorkspaceIcons: ({})
    property string pendingIconsJson: "{}"
    property var workspaceWindows: ({})
    property string windowsJson: "{}"
    property bool refreshPending: false

    function requestRefresh() {
        refreshPending = true;
        // Do not restart a running timer: continuous title events must not starve updates.
        if (!windowsProc.running && !windowRefresh.running) windowRefresh.start();
    }
    Timer {
        id: windowRefresh
        interval: 100
        onTriggered: {
            root.refreshPending = false;
            windowsProc.running = true;
        }
    }

    Timer {
        id: iconUpdateDebounce
        interval: 100
        onTriggered: {
            if (JSON.stringify(root.workspaceIcons) !== root.pendingIconsJson)
                root.workspaceIcons = root.pendingWorkspaceIcons;
        }
    }
    readonly property var urgentWindowAddresses: Hyprland.toplevels.values
        .filter(window => window.urgent && !window.activated)
        .map(window => normalizeAddress(window.address))
    readonly property var telegramTrayItems: SystemTray.items.values.filter(item => isTelegram(item.id))

    function isTelegram(appId) {
        return /(^|[._-])telegram([._-]?desktop)?($|[._-])/i.test(appId || "");
    }

    function trayHasUnread(item) {
        // Telegram owns these icon states; they survive focus and clear with its badge count.
        const icon = item.icon.toString().split("?")[0];
        return item.status === Status.NeedsAttention
            || /-(attention|mute)-(symbolic|panel)$/.test(icon);
    }

    function needsAttention(appId, addresses) {
        if (isTelegram(appId) && telegramTrayItems.length > 0)
            return telegramTrayItems.some(item => trayHasUnread(item));
        return attentionWindow(addresses) !== "";
    }

    function normalizeAddress(address) {
        return "0x" + String(address || "").replace(/^0x/i, "").toLowerCase();
    }

    function attentionWindow(addresses) {
        return (addresses || []).find(address => urgentWindowAddresses.includes(normalizeAddress(address))) || "";
    }

    function getWsIcons(wsId) {
        return workspaceIcons[wsId] || [];
    }
    function getWsWindows(wsId) { return workspaceWindows[wsId] || []; }
    function captureSource(address) {
        return Hyprland.toplevels.values.find(window => normalizeAddress(window.address) === address)?.wayland || null;
    }

    function focusWindow(address) {
        if (!/^0x[0-9a-f]+$/i.test(address || "")) return;
        Quickshell.execDetached(["bash", decodeURIComponent(Qt.resolvedUrl("../scripts/focus-window.sh").toString().replace(/^file:\/\//, "")), address]);
    }

    function updateWindows(data) {
        let clients;
        try {
            clients = JSON.parse(data);
        } catch (error) {
            return; // Keep the last good state if hyprctl is temporarily unavailable.
        }
        if (!Array.isArray(clients)) return;
        const previews = PreviewData.windows(clients);
        const previewJson = JSON.stringify(previews);
        if (previewJson !== windowsJson) {
            windowsJson = previewJson;
            workspaceWindows = previews;
        }
        const icons = WorkspaceWindows.build(clients, (appClass, initialClass) => Icons.resolveWindow(appClass, initialClass));
        // Publish only after a short quiet period, collapsing move-event bursts.
        const snapshot = JSON.stringify(icons);
        if (snapshot !== root.pendingIconsJson) {
            root.pendingWorkspaceIcons = icons;
            root.pendingIconsJson = snapshot;
            iconUpdateDebounce.restart();
        }
    }

    Process {
        id: windowsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.updateWindows(text)
        }
        Component.onCompleted: root.requestRefresh()
        onExited: { if (root.refreshPending) Qt.callLater(root.requestRefresh); }
    }

    // Update on Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            root.requestRefresh();
        }
    }

    // Backup timer
    Timer {
        interval: Settings.workspaceInterval
        running: true
        repeat: true
        onTriggered: root.requestRefresh()
    }

    property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property var occupiedWorkspaceIds: Object.keys(workspaceIcons)
        .map(id => Number(id)).sort((a, b) => a - b)
}
