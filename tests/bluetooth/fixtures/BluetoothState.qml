pragma Singleton
import QtQuick
QtObject {
    property bool available: true
    property bool enabled: true
    property bool discoverable: false
    property bool blocked: false
    property bool busy: false
    property bool scanning: false
    property int openPanels: 0
    property string errorMessage: ""
    property string busyLabel: ""
    property string operation: ""
    property string deviceName: "Test headphones"
    property var prompt: null
    property var lastAction: ({})
    property var adapter: ({ name: "Test adapter", adapterId: "hci0" })
    property var adapters: [adapter]
    property var device: ({ name: "Test headphones", address: "11:22:33:44:55:66", connected: false,
        paired: true, bonded: true, icon: "audio-headphones", blocked: false, batteryAvailable: true, battery: 0.75 })
    property var connectedDevices: []
    property var savedDevices: [device]
    property var nearbyDevices: []
    function setEnabled(value) { enabled = value; lastAction = {kind: "power", value: value}; }
    function setDiscoverable(value) { discoverable = value; lastAction = {kind: "discoverable", value: value}; }
    function selectAdapter(value) { adapter = value; }
    function scan() { scanning = !scanning; lastAction = {kind: "scan"}; }
    function status(value) { return value.connected ? "Connected" : "Paired"; }
    function changing(value) { return false; }
    function connectDevice(value) { lastAction = {kind: "connect"}; }
    function disconnectDevice(value) { lastAction = {kind: "disconnect"}; }
    function forgetDevice(value) { lastAction = {kind: "forget"}; }
    function cancel() { prompt = null; lastAction = {kind: "cancel"}; }
    function respond(accepted, value) { lastAction = {kind: "response", accepted: accepted, supplied: value.length > 0}; prompt = null; }
}
