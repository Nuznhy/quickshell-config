pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as Native
import "../config"

Singleton {
    id: root
    property bool ready: false
    property bool doNotDisturb: false
    property int openPanels: 0
    property string errorMessage: ""
    property var entries: []
    property var watchers: ({})
    property var pending: []
    property int sequence: 0
    readonly property var history: entries.filter(entry => !entry.transient)
    readonly property var popups: entries.filter(entry => entry.popup).slice(0, 3)
    readonly property int unreadCount: history.filter(entry => !entry.read).length
    signal openRequested

    function save() {
        if (ready) saveTimer.restart();
    }
    function patch(key, values) {
        entries = entries.map(entry => entry.key === key ? Object.assign({}, entry, values) : entry);
        save();
    }
    function setDoNotDisturb(value) {
        doNotDisturb = value;
        if (value) hidePopups();
        save();
    }
    function markRead() {
        entries = entries.map(entry => Object.assign({}, entry, { read: true }));
        save();
    }
    function hidePopups() {
        for (const entry of entries.slice()) hidePopup(entry.key);
    }
    function hidePopup(key) {
        const watcher = watchers[key];
        if (watcher && watcher.notification.transient) watcher.notification.expire();
        else patch(key, { popup: false });
    }
    function remove(key) {
        const watcher = watchers[key];
        if (watcher) watcher.notification.dismiss();
        entries = entries.filter(entry => entry.key !== key);
        save();
    }
    function clearHistory() {
        for (const entry of history.slice()) remove(entry.key);
    }
    function invoke(key, identifier) {
        const watcher = watchers[key];
        if (!watcher) return;
        const action = watcher.notification.actions.find(action => action.identifier === identifier);
        if (!action) return;
        // The callback may destroy the live notification, so copy sender metadata first.
        const entry = entries.find(entry => entry.key === key);
        const shouldFocus = identifier === "default" || identifier.toLowerCase() === "open"
            || (action.text || "Open").trim().toLowerCase() === "open";
        const aliases = shouldFocus && entry ? senderAliases(entry) : [];
        patch(key, { read: true, popup: false });
        if (shouldFocus) openRequested();
        action.invoke();
        if (aliases.length) {
            Quickshell.execDetached(["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/focus-notification.py")
                .toString().replace(/^file:\/\//, ""))].concat(aliases));
        }
    }
    function senderAliases(entry) {
        const names = [entry.desktopEntry, entry.appName].filter(name => !!name);
        const desktop = DesktopEntries.byId(entry.desktopEntry || "")
            || DesktopEntries.heuristicLookup(entry.desktopEntry || entry.appName);
        if (desktop) names.push(desktop.id, desktop.startupClass, desktop.name);
        return [...new Set(names.filter(name => !!name))];
    }
    function iconSource(icon, desktopEntry, appName) {
        if (icon.startsWith("/") || icon.startsWith("file:") || icon.startsWith("image:"))
            return icon.startsWith("/") ? "file://" + icon : icon;
        return (icon ? Quickshell.iconPath(icon, true) : "")
            || Icons.resolveWindow(desktopEntry, appName).source;
    }
    function capture(watcher, restored) {
        const n = watcher.notification;
        const previous = entries.find(entry => entry.key === watcher.key);
        const entry = {
            key: watcher.key, liveId: n.id, instance: Quickshell.instanceId,
            appName: n.appName || "Application", icon: n.appIcon, desktopEntry: n.desktopEntry,
            summary: n.summary, body: n.body, urgency: n.urgency, transient: n.transient,
            timestamp: restored && previous ? previous.timestamp : Date.now(),
            read: restored && previous ? previous.read : openPanels > 0,
            popup: !restored && !doNotDisturb && openPanels === 0,
            actions: n.actions.map(action => ({ identifier: action.identifier, text: action.text || "Open" }))
        };
        entries = [entry].concat(entries.filter(item => item.key !== watcher.key));
        // Limit both memory and saved history. Keep only three visible toasts.
        for (const old of entries.slice(100)) remove(old.key);
        for (const old of entries.filter(item => item.popup).slice(3)) hidePopup(old.key);
        watcher.restartTimeout(restored);
        save();
    }
    function receive(n) {
        n.tracked = true;
        if (!ready) { pending = pending.concat([n]); return; }
        const previous = n.lastGeneration ? entries.find(entry => entry.liveId === n.id
            && entry.instance === Quickshell.instanceId) : null;
        const key = previous ? previous.key : Date.now() + "-" + (++sequence);
        const watcher = watcherComponent.createObject(root, { notification: n, key: key });
        watchers[key] = watcher;
        capture(watcher, n.lastGeneration);
    }
    function closed(key) {
        delete watchers[key];
        const entry = entries.find(item => item.key === key);
        if (entry?.transient) entries = entries.filter(item => item.key !== key);
        else patch(key, { popup: false, actions: [] });
        save();
    }
    function finishLoading() {
        ready = true;
        const waiting = pending;
        pending = [];
        for (const notification of waiting) receive(notification);
    }

    Native.NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        onNotification: notification => root.receive(notification)
    }

    Component {
        id: watcherComponent
        QtObject {
            id: watcher
            required property var notification
            required property string key
            property bool hovered: false
            function restartTimeout(restored) {
                timeout.stop();
                // Quickshell 0.3.1 exposes the protocol timeout in milliseconds.
                if (notification.urgency === Native.NotificationUrgency.Critical
                        || notification.expireTimeout === 0) return;
                timeout.interval = notification.expireTimeout > 0 ? notification.expireTimeout : 6000;
                if (!restored || notification.expireTimeout > 0 || notification.transient) timeout.start();
            }
            property Timer timeout: Timer {
                running: false
                onTriggered: {
                    if (watcher.hovered) { restart(); return; }
                    if (watcher.notification.expireTimeout > 0 || watcher.notification.transient)
                        watcher.notification.expire();
                    else root.hidePopup(watcher.key);
                }
            }
            property Timer updateTimer: Timer {
                interval: 0
                onTriggered: root.capture(watcher, false)
            }
            property Connections events: Connections {
                target: watcher.notification
                function onSummaryChanged() { watcher.updateTimer.restart(); }
                function onBodyChanged() { watcher.updateTimer.restart(); }
                function onAppNameChanged() { watcher.updateTimer.restart(); }
                function onAppIconChanged() { watcher.updateTimer.restart(); }
                function onUrgencyChanged() { watcher.updateTimer.restart(); }
                function onActionsChanged() { watcher.updateTimer.restart(); }
                function onExpireTimeoutChanged() { watcher.updateTimer.restart(); }
                function onTransientChanged() { watcher.updateTimer.restart(); }
                function onHintsChanged() { watcher.updateTimer.restart(); }
                function onClosed(reason) {
                    watcher.updateTimer.stop();
                    watcher.timeout.stop();
                    root.closed(watcher.key);
                    watcher.destroy();
                }
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 150
        onTriggered: stateFile.setText(JSON.stringify({ version: 1, doNotDisturb: root.doNotDisturb,
            entries: root.history.map(entry => Object.assign({}, entry, { popup: false, actions: [] })) }))
    }
    FileView {
        id: stateFile
        path: Quickshell.statePath("notifications.json")
        atomicWrites: true
        printErrors: false
        onLoaded: {
            if (root.ready) return;
            try {
                const saved = JSON.parse(text());
                root.doNotDisturb = saved.doNotDisturb === true;
                root.entries = (Array.isArray(saved.entries) ? saved.entries : []).filter(entry =>
                    typeof entry.key === "string" && typeof entry.summary === "string"
                    && typeof entry.body === "string" && typeof entry.appName === "string"
                    && Number.isFinite(entry.timestamp)).slice(0, 100).map(entry => Object.assign({}, entry,
                        { popup: false, actions: [], transient: false, icon: entry.icon || "", desktopEntry: entry.desktopEntry || "" }));
            } catch (error) {
                root.errorMessage = "Could not read saved notification history.";
            }
            root.finishLoading();
        }
        onLoadFailed: error => {
            if (root.ready) return;
            if (error !== FileViewError.FileNotFound) root.errorMessage = "Could not read saved notification history.";
            root.finishLoading();
        }
        onSaved: root.errorMessage = ""
        onSaveFailed: error => root.errorMessage = "Notification history could not be saved."
    }

    IpcHandler {
        target: "notifications"
        function dnd(enabled: bool): void { root.setDoNotDisturb(enabled); }
        function toggleDnd(): void { root.setDoNotDisturb(!root.doNotDisturb); }
        function clear(): void { root.clearHistory(); }
        function status(): string {
            return JSON.stringify({ doNotDisturb: root.doNotDisturb, count: root.history.length,
                unread: root.unreadCount, popups: root.popups.length });
        }
    }
}
