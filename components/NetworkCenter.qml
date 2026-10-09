pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
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
    component Label: UI.Text {
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }
    component SectionTitle: Label {
        color: Design.textSecondary
        role: "caption"
        font.letterSpacing: 1
    }
    component Card: UI.Card {
        Layout.fillWidth: true
    }

    UI.ColumnLayout {
        id: content
        x: 0; y: 0
        width: parent.width
        spacing: Design.space12
        UI.RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: "Network"
                role: "panel"
                font.bold: true
            }
            NotificationButton { text: "Advanced"; onClicked: root.editConnections() }
        }
        Label {
            id: errorLabel
            Layout.fillWidth: true
            visible: text.length > 0
            text: NetworkState.statusError || NetworkState.errorMessage || NetworkState.busyLabel
            color: NetworkState.statusError || NetworkState.errorMessage ? Design.danger : Design.accent
            wrapMode: Text.Wrap
            maximumLineCount: 4
            role: "label"
        }
        Card {
            id: passwordBox
            visible: NetworkState.passwordNetwork !== null
            implicitHeight: passwordContent.implicitHeight + Design.panelPadding * 2
            border.color: Design.accent
            UI.ColumnLayout {
                id: passwordContent
                x: Design.panelPadding; y: Design.panelPadding
                width: parent.width - Design.panelPadding * 2
                spacing: Design.space8
                Label {
                    Layout.fillWidth: true
                    text: NetworkState.passwordNetwork?.name || "Wi-Fi password"
                    font.bold: true
                }
                UI.TextField {
                    id: password
                    objectName: "wifiPassword"
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Wi-Fi password"
                    selectByMouse: true
                    Accessible.name: "Wi-Fi password"

                    onAccepted: root.submitPassword()
                }
                UI.RowLayout {
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
        UI.ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(details.implicitHeight,
                Math.max(160, root.maximumHeight - 80 - (passwordBox.visible ? passwordBox.implicitHeight + 12 : 0)
                    - (errorLabel.visible ? errorLabel.implicitHeight + 12 : 0)))
            contentWidth: availableWidth
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            UI.ColumnLayout {
                id: details
                width: scroll.availableWidth
                spacing: Design.space8
                SectionTitle { text: "CURRENT CONNECTIONS" }
                Label {
                    Layout.fillWidth: true
                    visible: NetworkState.connections.length === 0
                    text: NetworkState.available ? "Not connected" : "NetworkManager unavailable"
                    color: Design.textSecondary
                }
                Repeater {
                    model: NetworkState.connections
                    Card {
                        id: currentCard
                        required property var modelData
                        implicitHeight: currentContent.implicitHeight + Design.panelPadding * 2
                        UI.ColumnLayout {
                            id: currentContent
                            x: Design.panelPadding; y: Design.panelPadding
                            width: parent.width - Design.panelPadding * 2
                            spacing: Design.space4
                            UI.RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: currentCard.modelData.vpn ? "󰦝" : currentCard.modelData.type === "802-11-wireless" ? "󰤨" : "󰈀"
                                    color: Design.accent
                                    font.pixelSize: Design.iconLarge
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: currentCard.modelData.name
                                    font.bold: true
                                }
                                Label {
                                    text: currentCard.modelData.state === "activated" ? "Connected" : currentCard.modelData.state
                                    color: currentCard.modelData.state === "activated" ? Design.success : Design.warning
                                    role: "caption"
                                }
                            }
                            Label {
                                Layout.fillWidth: true
                                text: currentCard.modelData.devices.join(", ")
                                color: Design.textMuted
                                role: "caption"
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
                                    color: Design.textSecondary
                                    selectionColor: Design.accent
                                    selectedTextColor: Design.background
                                    font.family: Design.fontFamily
                                    font.pixelSize: Design.labelSize
                                    wrapMode: TextEdit.WrapAnywhere
                                    Accessible.name: "Local IP address " + modelData
                                }
                            }
                            Label {
                                visible: currentCard.modelData.ipv4.length + currentCard.modelData.ipv6.length === 0
                                text: "Waiting for an IP address…"
                                color: Design.textMuted
                                role: "label"
                            }
                        }
                    }
                }
                SectionTitle { text: "ETHERNET"; Layout.topMargin: Design.space4 }
                Label {
                    visible: NetworkState.wiredDevices.length === 0
                    text: "No wired adapter"
                    color: Design.textMuted
                }
                Repeater {
                    model: NetworkState.wiredDevices
                    Card {
                        id: wiredCard
                        required property var modelData
                        implicitHeight: 54
                        UI.RowLayout {
                            anchors.fill: parent
                            anchors.margins: Design.panelPadding
                            UI.ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Design.space2
                                Label { text: wiredCard.modelData.name }
                                Label {
                                    text: !wiredCard.modelData.nmManaged ? "Unmanaged"
                                        : wiredCard.modelData.connected ? "Connected · " + wiredCard.modelData.linkSpeed + " Mbps"
                                        : wiredCard.modelData.hasLink ? "Disconnected" : "Cable unplugged"
                                    role: "caption"
                                    color: Design.textSecondary
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
                UI.RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Design.space4
                    SectionTitle { Layout.fillWidth: true; text: "VPN" }
                    NotificationButton { text: "Add VPN"; onClicked: root.editConnections() }
                }
                Label {
                    visible: NetworkState.vpnProfiles.length === 0
                    text: "No saved VPN connections"
                    color: Design.textMuted
                }
                Repeater {
                    model: NetworkState.vpnProfiles
                    Card {
                        id: vpnCard
                        required property var modelData
                        implicitHeight: 56
                        UI.RowLayout {
                            anchors.fill: parent
                            anchors.margins: Design.panelPadding
                            UI.ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Design.space4
                                Label {
                                    Layout.fillWidth: true
                                    text: vpnCard.modelData.name
                                }
                                Label {
                                    text: vpnCard.modelData.active ? "Connected" : vpnCard.modelData.state === "activating" ? "Connecting…" : "Off"
                                    color: vpnCard.modelData.active ? Design.success : Design.textMuted
                                    role: "caption"
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
                    Layout.topMargin: Design.space4
                    implicitHeight: 46
                    UI.RowLayout {
                        anchors.fill: parent
                        anchors.margins: Design.panelPadding
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
                    color: Design.textMuted
                    wrapMode: Text.Wrap
                }
                Repeater {
                    model: NetworkState.wifiEnabled ? NetworkState.wifiNetworks : []
                    Card {
                        id: wifiCard
                        required property var modelData
                        implicitHeight: 62
                        UI.RowLayout {
                            anchors.fill: parent
                            anchors.margins: Design.panelPadding
                            spacing: Design.space8
                            Label {
                                text: wifiCard.modelData.signalStrength >= 0.7 ? "󰤨" : wifiCard.modelData.signalStrength >= 0.4 ? "󰤥" : "󰤟"
                                color: wifiCard.modelData.connected ? Design.accent : Design.textSecondary
                                font.pixelSize: Design.iconLarge
                            }
                            UI.ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Design.space4
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
                                    role: "caption"
                                    color: Design.textSecondary
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
