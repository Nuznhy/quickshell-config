pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking as Net

Singleton {
    id: root
    property bool available: false
    property var connections: []
    property var vpnProfiles: []
    property string statusError: ""
    property string errorMessage: ""
    property string busyLabel: ""
    property int openPanels: 0
    property var pendingWifi: null
    property var passwordNetwork: null
    property int revision: 0
    readonly property bool busy: actionProc.running || pendingWifi !== null
    readonly property bool wifiEnabled: Net.Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Net.Networking.wifiHardwareEnabled
    readonly property var wifiDevices: Net.Networking.devices.values.filter(device => device.type === Net.DeviceType.Wifi)
    readonly property var wiredDevices: Net.Networking.devices.values.filter(device => device.type === Net.DeviceType.Wired)
    readonly property var wifiNetworks: {
        let networks = [];
        for (const device of wifiDevices)
            for (const network of device.networks.values) networks.push(network);
        return networks.filter(network => !!network.name)
            .sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength);
    }
    readonly property bool vpnActive: vpnProfiles.some(profile => profile.active)
    readonly property bool connected: connections.some(connection => connection.state === "activated")
    readonly property string connectivity: Net.NetworkConnectivity.toString(Net.Networking.connectivity)
    readonly property string icon: vpnActive ? "󰦝" : wiredDevices.some(device => device.connected) ? "󰈀"
        : wifiNetworks.some(network => network.connected) ? "󰤨" : "󰤭"

    onOpenPanelsChanged: {
        updateScanning();
        if (openPanels > 0) refresh();
    }
    onWifiDevicesChanged: updateScanning()
    onWifiEnabledChanged: {
        updateScanning();
        if (!wifiEnabled) passwordNetwork = null;
        refresh();
    }
    function updateScanning() {
        for (const device of wifiDevices) device.scannerEnabled = openPanels > 0 && wifiEnabled;
    }
    function refresh() {
        if (statusProc.running) { refreshAgain = true; return; }
        statusProc.revision = revision;
        statusProc.running = true;
    }
    property bool refreshAgain: false
    function runAction(command, label) {
        if (busy || !available) return;
        revision++;
        errorMessage = "";
        busyLabel = label;
        actionProc.command = command;
        actionProc.running = true;
    }
    function setWifi(enabled) {
        if (!wifiHardwareEnabled || !wifiDevices.length) return;
        if (!enabled) passwordNetwork = null;
        runAction(["nmcli", "--wait", "15", "radio", "wifi", enabled ? "on" : "off"], enabled ? "Enabling Wi-Fi…" : "Disabling Wi-Fi…");
    }
    function setWired(device, enabled) {
        if (!wiredDevices.includes(device) || !device.nmManaged) return;
        runAction(["nmcli", "--wait", "30", "device", enabled ? "connect" : "disconnect", device.name], enabled ? "Connecting Ethernet…" : "Disconnecting Ethernet…");
    }
    function setVpn(profile, enabled) {
        if (!vpnProfiles.some(item => item.uuid === profile.uuid)) return;
        runAction(["nmcli", "--wait", "45", "connection", enabled ? "up" : "down", "uuid", profile.uuid], enabled ? "Connecting VPN…" : "Disconnecting VPN…");
    }
    function needsPassword(network) {
        return [Net.WifiSecurityType.WpaPsk, Net.WifiSecurityType.Wpa2Psk, Net.WifiSecurityType.Sae].includes(network.security);
    }
    function securityLabel(network) {
        if (network.security === Net.WifiSecurityType.Open) return "Open";
        if (network.security === Net.WifiSecurityType.Owe) return "Enhanced open";
        if (network.security === Net.WifiSecurityType.Sae) return "WPA3";
        if (needsPassword(network)) return "WPA/WPA2";
        return "Enterprise / other";
    }
    function connectWifi(network) {
        if (busy || !available || !wifiEnabled || !wifiNetworks.includes(network)) return;
        errorMessage = "";
        if (!network.known && needsPassword(network)) { passwordNetwork = network; return; }
        if (!network.known && ![Net.WifiSecurityType.Open, Net.WifiSecurityType.Owe].includes(network.security)) {
            errorMessage = "Configure this network in Advanced first, then connect here.";
            return;
        }
        beginWifi(network);
        network.connect();
    }
    function beginWifi(network) {
        revision++;
        errorMessage = "";
        pendingWifi = network;
        busyLabel = "Connecting to " + network.name + "…";
        wifiTimeout.restart();
    }
    function submitPassword(password) {
        const network = passwordNetwork;
        if (!network || busy || !wifiNetworks.includes(network)) return;
        if ((network.security !== Net.WifiSecurityType.Sae && password.length < 8)
                || password.length === 0 || password.length > 64
                || (network.security === Net.WifiSecurityType.Sae && password.length > 63)
                || (password.length === 64 && !/^[0-9a-fA-F]{64}$/.test(password))) {
            errorMessage = "Enter a valid Wi-Fi password.";
            return;
        }
        passwordNetwork = null;
        beginWifi(network);
        network.connectWithPsk(password);
    }
    function disconnectWifi(network) {
        if (busy || !wifiNetworks.includes(network)) return;
        runAction(["nmcli", "--wait", "15", "device", "disconnect", network.device.name], "Disconnecting Wi-Fi…");
    }
    function openSettings() { editorProc.running = true; }

    Connections {
        target: root.pendingWifi
        function onConnectionFailed(reason) {
            const network = root.pendingWifi;
            root.pendingWifi = null;
            wifiTimeout.stop();
            root.busyLabel = "";
            if (reason === Net.ConnectionFailReason.NoSecrets && network && root.needsPassword(network)) {
                root.passwordNetwork = network;
                root.errorMessage = "Authentication failed. Enter the Wi-Fi password.";
            } else root.errorMessage = "Connection failed: " + Net.ConnectionFailReason.toString(reason);
            root.refresh();
        }
        function onConnectedChanged() {
            if (root.pendingWifi?.connected) {
                root.pendingWifi = null;
                wifiTimeout.stop();
                root.busyLabel = "";
                root.refresh();
            }
        }
    }
    Timer {
        id: wifiTimeout
        interval: 60000
        onTriggered: {
            root.pendingWifi = null;
            root.busyLabel = "";
            root.errorMessage = "Connection timed out. Check the network and try again.";
            root.refresh();
        }
    }
    Process {
        id: actionProc
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {}
        stderr: StdioCollector { id: actionError }
        onExited: code => {
            root.busyLabel = "";
            if (code !== 0) root.errorMessage = actionError.text.trim() || "Network operation failed.";
            root.refresh();
        }
    }
    Process {
        id: editorProc
        command: ["nm-connection-editor"]
        onExited: code => {
            if (code !== 0) root.errorMessage = "Could not open nm-connection-editor.";
            root.refresh();
        }
    }
    Process {
        id: statusProc
        property int revision: 0
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/network-status.py").toString().replace("file://", ""))]
        stdout: StdioCollector {
            onStreamFinished: {
                if (statusProc.revision !== root.revision) return;
                try {
                    const snapshot = JSON.parse(text);
                    root.available = snapshot.ok === true;
                    root.statusError = snapshot.ok ? "" : snapshot.error;
                    if (snapshot.ok) {
                        if (JSON.stringify(root.connections) !== JSON.stringify(snapshot.connections)) root.connections = snapshot.connections;
                        if (JSON.stringify(root.vpnProfiles) !== JSON.stringify(snapshot.vpns)) root.vpnProfiles = snapshot.vpns;
                    } else {
                        root.connections = [];
                        root.vpnProfiles = [];
                    }
                } catch (error) {
                    root.available = false;
                    root.statusError = "Could not read network status.";
                }
            }
        }
        onExited: code => {
            if (code !== 0) { root.available = false; root.statusError = "Network status helper failed."; }
            if (root.refreshAgain || revision !== root.revision) {
                root.refreshAgain = false;
                Qt.callLater(root.refresh);
            }
        }
        Component.onCompleted: root.refresh()
    }
    Timer {
        interval: root.openPanels > 0 ? 2500 : 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    Timer {
        id: changeDebounce
        interval: 150
        onTriggered: root.refresh()
    }
    Process {
        id: networkMonitor
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: data => changeDebounce.restart() }
        stderr: StdioCollector {}
        running: true
    }
    Timer {
        interval: 5000
        running: !networkMonitor.running
        repeat: true
        onTriggered: networkMonitor.running = true
    }
}
