pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth as BT

Singleton {
    id: root
    readonly property var adapters: BT.Bluetooth.adapters.values
    property var selectedAdapter: null
    readonly property var adapter: selectedAdapter || BT.Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discoverable: adapter?.discoverable ?? false
    readonly property bool blocked: adapter?.state === BT.BluetoothAdapterState.Blocked
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var connectedDevices: devices.filter(device => device.connected)
    readonly property var savedDevices: devices.filter(device => !device.connected && (device.paired || device.bonded))
    readonly property var nearbyDevices: devices.filter(device => !device.connected && !device.paired && !device.bonded)
        .sort((a, b) => (a.name || a.address).localeCompare(b.name || b.address))
    readonly property bool busy: actionProc.running
    property int openPanels: 0
    property var scanAdapter: null
    readonly property bool scanning: scanAdapter !== null
    property string operation: ""
    property string busyLabel: ""
    property string errorMessage: ""
    property var prompt: null
    property string deviceName: ""
    property bool receivedResult: false

    onAdaptersChanged: { if (selectedAdapter && !adapters.includes(selectedAdapter)) selectedAdapter = null; }
    onOpenPanelsChanged: {
        if (openPanels <= 0) {
            stopScan();
            if (busy && (operation === "pair" || prompt)) cancel();
        }
    }
    onAdapterChanged: stopScan()
    onEnabledChanged: { if (!enabled) stopScan(); }
    function selectAdapter(value) {
        if (busy || !adapters.includes(value)) return;
        stopScan();
        selectedAdapter = value;
        errorMessage = "";
    }
    function scan() {
        if (!adapter || !enabled || busy) return;
        errorMessage = "";
        if (scanAdapter) { stopScan(); return; }
        // Do not stop a discovery session started by another Bluetooth manager.
        if (adapter.discovering) return;
        scanAdapter = adapter;
        adapter.discovering = true;
        scanTimeout.restart();
        scanCheck.restart();
    }
    function stopScan() {
        scanTimeout.stop();
        scanCheck.stop();
        if (scanAdapter) scanAdapter.discovering = false;
        scanAdapter = null;
    }
    function perform(action, target, value) {
        if (busy || !target) return;
        const adapterAction = action === "power" || action === "discoverable";
        if (!adapterAction && !devices.includes(target)) return;
        if (adapterAction && target !== adapter) return;
        errorMessage = "";
        prompt = null;
        receivedResult = false;
        operation = action;
        deviceName = target.name || target.address || "Bluetooth";
        busyLabel = action === "power" ? "Changing Bluetooth power…" : action === "discoverable" ? "Changing discovery visibility…"
            : action === "pair" ? "Pairing with " + deviceName + "…"
            : action === "connect" ? "Connecting to " + deviceName + "…"
            : action === "forget" ? "Removing " + deviceName + "…" : "Disconnecting " + deviceName + "…";
        if (action === "power" || action === "pair") stopScan();
        actionProc.command = ["python3", decodeURIComponent(Qt.resolvedUrl("../scripts/bluetooth-action.py").toString().replace(/^file:\/\//, "")),
            action, target.dbusPath].concat(adapterAction ? [value ? "on" : "off"] : []);
        actionProc.running = true;
    }
    function setEnabled(value) { if (!blocked) perform("power", adapter, value); }
    function setDiscoverable(value) { if (enabled) perform("discoverable", adapter, value); }
    function connectDevice(device) { if (enabled && !device.blocked) perform(device.paired || device.bonded ? "connect" : "pair", device); }
    function disconnectDevice(device) { perform("disconnect", device); }
    function forgetDevice(device) { perform("forget", device); }
    function respond(accepted, value) {
        if (!busy || !prompt) return;
        errorMessage = "";
        actionProc.write(JSON.stringify({ id: prompt.id, accepted: accepted, value: value || "" }) + "\n");
    }
    function cancel() {
        if (busy) actionProc.write(JSON.stringify({ cancel: true }) + "\n");
    }
    function changing(device) {
        return device.pairing || device.state === BT.BluetoothDeviceState.Connecting || device.state === BT.BluetoothDeviceState.Disconnecting;
    }
    function status(device) {
        if (device.pairing) return "Pairing…";
        if (device.state === BT.BluetoothDeviceState.Connecting) return "Connecting…";
        if (device.state === BT.BluetoothDeviceState.Disconnecting) return "Disconnecting…";
        if (device.blocked) return "Blocked";
        return device.connected ? "Connected" : device.paired || device.bonded ? "Paired" : "Available";
    }
    Timer { id: scanTimeout; interval: 30000; onTriggered: root.stopScan() }
    Timer {
        id: scanCheck
        interval: 3000
        onTriggered: {
            if (root.scanAdapter && !root.scanAdapter.discovering) {
                root.stopScan();
                root.errorMessage = "Could not start Bluetooth discovery. Check the adapter and try again.";
            }
        }
    }
    Process {
        id: actionProc
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const message = JSON.parse(data);
                    if (message.type === "prompt") root.prompt = message.prompt;
                    else if (message.type === "input-error") root.errorMessage = message.error;
                    else if (message.type === "result") {
                        root.receivedResult = true;
                        if (!message.ok) root.errorMessage = message.error || "Bluetooth operation failed.";
                    }
                } catch (error) { root.errorMessage = "Could not read the Bluetooth response."; }
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            if (!root.receivedResult) root.errorMessage = "Bluetooth helper failed. Check Python, PyGObject, and BlueZ.";
            root.prompt = null;
            root.busyLabel = "";
            root.operation = "";
        }
    }
}
