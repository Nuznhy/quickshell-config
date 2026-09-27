pragma Singleton
import QtQuick

QtObject {
    property bool available: true
    property bool busy: false
    property string statusError: ""
    property string errorMessage: ""
    property string busyLabel: ""
    property int openPanels: 0
    property bool wifiEnabled: true
    property bool wifiHardwareEnabled: true
    property var passwordNetwork: null
    property var lastAction: ({})
    property bool failAction: false
    property var connections: []
    property QtObject wired: QtObject {
        property string name: "eth0"
        property bool connected: true
        property bool nmManaged: true
        property bool hasLink: true
        property int linkSpeed: 1000
    }
    property QtObject wifi: QtObject {
        property string name: "Test Wi-Fi: \\\ network"
        property bool connected: false
        property bool known: false
        property bool stateChanging: false
        property real signalStrength: 0.9
    }
    property var wiredDevices: [wired]
    property var wifiDevices: [{}]
    property var wifiNetworks: [wifi]
    property var vpnProfiles: [{uuid: "test-vpn", name: "Work VPN", active: false, state: "disconnected"}]
    function setWifi(value) { lastAction = {kind: "wifi", enabled: value}; if (!failAction) wifiEnabled = value; }
    function setWired(device, value) { lastAction = {kind: "wired", enabled: value}; if (!failAction) device.connected = value; }
    function setVpn(profile, value) {
        lastAction = {kind: "vpn", uuid: profile.uuid, enabled: value};
        if (!failAction) vpnProfiles = [{uuid: profile.uuid, name: profile.name, active: value, state: value ? "activated" : "disconnected"}];
    }
    function securityLabel(network) { return "WPA2"; }
    function connectWifi(network) { passwordNetwork = network; }
    function disconnectWifi(network) { lastAction = {kind: "disconnect"}; }
    function submitPassword(value) { lastAction = {kind: "password", supplied: value.length > 0}; passwordNetwork = null; }
    function openSettings() { lastAction = {kind: "editor"}; }
}
