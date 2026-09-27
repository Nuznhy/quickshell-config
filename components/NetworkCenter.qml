pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

FocusScope {
    id: root
    property bool active: false
    property int maximumHeight: 620
    implicitHeight: content.implicitHeight
    signal dismissed
    onActiveChanged: {
        NetworkState.openPanels += active ? 1 : -1;
        if (active) forceActiveFocus();
        else {
            password.text = "";
            NetworkState.passwordNetwork = null;
        }
    }
    Component.onDestruction: { if (active) NetworkState.openPanels--; }
    Keys.onEscapePressed: {
        if (NetworkState.passwordNetwork) NetworkState.passwordNetwork = null;
        else dismissed();
    }
    function editConnections() {
        root.dismissed();
        NetworkState.openSettings();
    }
    function submitPassword() {
        NetworkState.submitPassword(password.text);
        if (!NetworkState.passwordNetwork) password.text = "";
    }
    Connections {
        target: NetworkState
        function onPasswordNetworkChanged() {
            password.text = "";
            if (NetworkState.passwordNetwork && root.active) password.forceActiveFocus();
        }
    }
    component Label: Text {
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }
    component SectionTitle: Label {
        color: Theme.subtle
        font.pixelSize: 10
        font.letterSpacing: 1
    }
    component Card: Rectangle {
        color: Theme.surface
        radius: 10
        Layout.fillWidth: true
    }

    ColumnLayout {
        id: content
        x: 0; y: 0
        width: parent.width
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: "Network"
                font.pixelSize: 18
                font.bold: true
            }
            NotificationButton { text: "Advanced"; onClicked: root.editConnections() }
        }
        Label {
            id: errorLabel
            Layout.fillWidth: true
            visible: text.length > 0
            text: NetworkState.statusError || NetworkState.errorMessage || NetworkState.busyLabel
            color: NetworkState.statusError || NetworkState.errorMessage ? Theme.love : Theme.iris
            wrapMode: Text.Wrap
            maximumLineCount: 4
            font.pixelSize: 11
        }
        Card {
            id: passwordBox
            visible: NetworkState.passwordNetwork !== null
            implicitHeight: passwordContent.implicitHeight + 20
            border.color: Theme.iris
            ColumnLayout {
                id: passwordContent
                x: 10; y: 10
                width: parent.width - 20
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    text: NetworkState.passwordNetwork?.name || "Wi-Fi password"
                    font.bold: true
                }
                TextField {
                    id: password
                    objectName: "wifiPassword"
                    Layout.fillWidth: true
                    implicitHeight: 34
                    echoMode: TextInput.Password
                    placeholderText: "Wi-Fi password"
                    color: Theme.text
                    placeholderTextColor: Theme.muted
                    selectionColor: Theme.iris
                    selectedTextColor: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    selectByMouse: true
                    Accessible.name: "Wi-Fi password"
                    background: Rectangle {
                        radius: 8
                        color: Theme.overlay
                        border.color: password.activeFocus ? Theme.iris : Theme.highlightMed
                    }
                    onAccepted: root.submitPassword()
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    NotificationButton {
                        text: "Cancel"
                        onClicked: NetworkState.passwordNetwork = null
                    }
                    NotificationButton {
                        objectName: "submitPassword"
                        text: "Connect"
                        accent: true
                        enabled: password.text.length > 0 && !NetworkState.busy
                        onClicked: root.submitPassword()
                    }
                }
            }
        }
        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(details.implicitHeight,
                Math.max(160, root.maximumHeight - 80 - (passwordBox.visible ? passwordBox.implicitHeight + 12 : 0)
                    - (errorLabel.visible ? errorLabel.implicitHeight + 12 : 0)))
            contentWidth: availableWidth
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                id: details
                width: scroll.availableWidth
                spacing: 10
                SectionTitle { text: "CURRENT CONNECTIONS" }
                Label {
                    Layout.fillWidth: true
                    visible: NetworkState.connections.length === 0
                    text: NetworkState.available ? "Not connected" : "NetworkManager unavailable"
                    color: Theme.subtle
                }
                Repeater {
                    model: NetworkState.connections
                    Card {
                        id: currentCard
                        required property var modelData
                        implicitHeight: currentContent.implicitHeight + 20
                        ColumnLayout {
                            id: currentContent
                            x: 10; y: 10
                            width: parent.width - 20
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: currentCard.modelData.vpn ? "󰦝" : currentCard.modelData.type === "802-11-wireless" ? "󰤨" : "󰈀"
                                    color: Theme.iris
                                    font.pixelSize: 19
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: currentCard.modelData.name
                                    font.bold: true
                                }
                                Label {
                                    text: currentCard.modelData.state === "activated" ? "Connected" : currentCard.modelData.state
                                    color: currentCard.modelData.state === "activated" ? Theme.foam : Theme.gold
                                    font.pixelSize: 10
                                }
                            }
                            Label {
                                Layout.fillWidth: true
                                text: currentCard.modelData.devices.join(", ")
                                color: Theme.muted
                                font.pixelSize: 10
                            }
                            Repeater {
                                model: currentCard.modelData.ipv4.concat(currentCard.modelData.ipv6)
                                TextEdit {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    text: modelData
                                    textFormat: TextEdit.PlainText
                                    readOnly: true
                                    selectByMouse: true
                                    color: Theme.subtle
                                    selectionColor: Theme.iris
                                    selectedTextColor: Theme.bg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    wrapMode: TextEdit.WrapAnywhere
                                    Accessible.name: "Local IP address " + modelData
                                }
                            }
                            Label {
                                visible: currentCard.modelData.ipv4.length + currentCard.modelData.ipv6.length === 0
                                text: "Waiting for an IP address…"
                                color: Theme.muted
                                font.pixelSize: 11
                            }
                        }
                    }
                }
                SectionTitle { text: "ETHERNET"; Layout.topMargin: 6 }
                Label {
                    visible: NetworkState.wiredDevices.length === 0
                    text: "No wired adapter"
                    color: Theme.muted
                }
                Repeater {
                    model: NetworkState.wiredDevices
                    Card {
                        id: wiredCard
                        required property var modelData
                        implicitHeight: 54
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Label { text: wiredCard.modelData.name }
                                Label {
                                    text: !wiredCard.modelData.nmManaged ? "Unmanaged"
                                        : wiredCard.modelData.connected ? "Connected · " + wiredCard.modelData.linkSpeed + " Mbps"
                                        : wiredCard.modelData.hasLink ? "Disconnected" : "Cable unplugged"
                                    font.pixelSize: 10
                                    color: Theme.subtle
                                }
                            }
                            ControlSwitch {
                                objectName: "wiredToggle"
                                value: wiredCard.modelData.connected
                                enabled: NetworkState.available && !NetworkState.busy && wiredCard.modelData.nmManaged
                                    && (wiredCard.modelData.hasLink || checked)
                                Accessible.name: "Ethernet " + wiredCard.modelData.name
                                onChangeRequested: value => NetworkState.setWired(wiredCard.modelData, value)
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    SectionTitle { Layout.fillWidth: true; text: "VPN" }
                    NotificationButton { text: "Add VPN"; onClicked: root.editConnections() }
                }
                Label {
                    visible: NetworkState.vpnProfiles.length === 0
                    text: "No saved VPN connections"
                    color: Theme.muted
                }
                Repeater {
                    model: NetworkState.vpnProfiles
                    Card {
                        id: vpnCard
                        required property var modelData
                        implicitHeight: 56
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label {
                                    Layout.fillWidth: true
                                    text: vpnCard.modelData.name
                                }
                                Label {
                                    text: vpnCard.modelData.active ? "Connected" : vpnCard.modelData.state === "activating" ? "Connecting…" : "Off"
                                    color: vpnCard.modelData.active ? Theme.foam : Theme.muted
                                    font.pixelSize: 10
                                }
                            }
                            ControlSwitch {
                                objectName: "vpnToggle"
                                value: vpnCard.modelData.active
                                enabled: NetworkState.available && !NetworkState.busy
                                Accessible.name: "VPN " + vpnCard.modelData.name
                                onChangeRequested: value => NetworkState.setVpn(vpnCard.modelData, value)
                            }
                        }
                    }
                }
                Card {
                    Layout.topMargin: 6
                    implicitHeight: 46
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        Label { Layout.fillWidth: true; text: "Wi-Fi" }
                        ControlSwitch {
                            objectName: "wifiToggle"
                            value: NetworkState.wifiEnabled
                            enabled: NetworkState.available && !NetworkState.busy
                                && NetworkState.wifiDevices.length > 0 && NetworkState.wifiHardwareEnabled
                            Accessible.name: "Wi-Fi"
                            onChangeRequested: value => NetworkState.setWifi(value)
                        }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    visible: !NetworkState.wifiEnabled || !NetworkState.wifiHardwareEnabled
                        || NetworkState.wifiDevices.length === 0 || NetworkState.wifiNetworks.length === 0
                    text: NetworkState.wifiDevices.length === 0 ? "No Wi-Fi adapter"
                        : !NetworkState.wifiHardwareEnabled ? "Wi-Fi is blocked by the hardware switch"
                        : !NetworkState.wifiEnabled ? "Wi-Fi is off" : "Searching for networks…"
                    color: Theme.muted
                    wrapMode: Text.Wrap
                }
                Repeater {
                    model: NetworkState.wifiEnabled ? NetworkState.wifiNetworks : []
                    Card {
                        id: wifiCard
                        required property var modelData
                        implicitHeight: 62
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            Label {
                                text: wifiCard.modelData.signalStrength >= 0.7 ? "󰤨" : wifiCard.modelData.signalStrength >= 0.4 ? "󰤥" : "󰤟"
                                color: wifiCard.modelData.connected ? Theme.iris : Theme.subtle
                                font.pixelSize: 21
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label {
                                    Layout.fillWidth: true
                                    text: wifiCard.modelData.name
                                    font.bold: wifiCard.modelData.connected
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: Math.round(wifiCard.modelData.signalStrength * 100) + "% · " + NetworkState.securityLabel(wifiCard.modelData)
                                        + (wifiCard.modelData.known ? " · Saved" : "")
                                        + (NetworkState.wifiDevices.length > 1 ? " · " + wifiCard.modelData.device.name : "")
                                    font.pixelSize: 10
                                    color: Theme.subtle
                                }
                            }
                            NotificationButton {
                                objectName: "connectWifi"
                                text: wifiCard.modelData.stateChanging ? "Connecting…" : wifiCard.modelData.connected ? "Disconnect" : "Connect"
                                enabled: NetworkState.available && !NetworkState.busy && !wifiCard.modelData.stateChanging
                                onClicked: {
                                    if (wifiCard.modelData.connected) NetworkState.disconnectWifi(wifiCard.modelData);
                                    else NetworkState.connectWifi(wifiCard.modelData);
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
