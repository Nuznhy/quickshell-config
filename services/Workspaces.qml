pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../config"

Singleton {
    id: root
    // Store windows per workspace
    property var workspaceIcons: ({})
    property var pendingWorkspaceIcons: ({})
    property string pendingIconsJson: "{}"

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
        const icons = {};
        const grouped = {};
        const resolved = {};
        for (const client of clients) {
            const wsId = client.workspace?.id;
            if (!(wsId > 0) || !client.address || client.mapped === false) continue;
            if (!icons[wsId]) {
                icons[wsId] = [];
                grouped[wsId] = new Map();
            }
            const key = JSON.stringify([client.class, client.initialClass]);
            if (!resolved[key])
                resolved[key] = Icons.resolveWindow(client.class, client.initialClass);
            const icon = resolved[key];
            const rank = client.focusHistoryID >= 0 ? client.focusHistoryID : Number.MAX_SAFE_INTEGER;
            const previous = grouped[wsId].get(icon.appId);
            if (!previous) {
                grouped[wsId].set(icon.appId, { icon: icon, address: client.address, rank: rank, addresses: [client.address] });
            } else {
                previous.addresses.push(client.address);
                if (rank < previous.rank) {
                    previous.address = client.address;
                    previous.rank = rank;
                }
            }
        }
        for (const wsId in icons) {
            icons[wsId] = Array.from(grouped[wsId].values()).map(window => ({
                appId: window.icon.appId,
                source: window.icon.source,
                address: window.address,
                addresses: window.addresses
            }));
        }
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
        Component.onCompleted: running = true
    }

    // Update on Hyprland events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowsProc.running = true;
        }
    }

    // Backup timer
    Timer {
        interval: Settings.workspaceInterval
        running: true
        repeat: true
        onTriggered: windowsProc.running = true
    }

    property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property var occupiedWorkspaceIds: Object.keys(workspaceIcons)
        .map(id => Number(id)).sort((a, b) => a - b)
}
