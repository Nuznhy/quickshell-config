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
    property var forgetTarget: null
    implicitHeight: content.implicitHeight + 24
    signal dismissed
    onActiveChanged: {
        BluetoothState.openPanels += active ? 1 : -1;
        if (active) forceActiveFocus();
        else { pin.text = ""; forgetTarget = null; }
    }
    Component.onDestruction: { if (active) BluetoothState.openPanels--; }
    Keys.onEscapePressed: {
        if (BluetoothState.prompt) BluetoothState.cancel();
        else if (forgetTarget) forgetTarget = null;
        else dismissed();
    }
    Connections {
        target: BluetoothState
        function onPromptChanged() {
            pin.text = "";
            if (BluetoothState.prompt && promptBox.needsInput && root.active) pin.forceActiveFocus();
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
        Layout.topMargin: 6
    }
    component Card: Rectangle {
        Layout.fillWidth: true
        radius: 10
        color: Theme.surface
    }
    component DeviceCard: Card {
        id: deviceCard
        required property var device
        implicitHeight: cardContent.implicitHeight + 20
        ColumnLayout {
            id: cardContent
            x: 10; y: 10
            width: parent.width - 20
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Label {
                    text: deviceCard.device.icon.indexOf("audio") >= 0 || deviceCard.device.icon.indexOf("head") >= 0 ? "󰋋"
                        : deviceCard.device.icon.indexOf("keyboard") >= 0 ? "󰌌"
                        : deviceCard.device.icon.indexOf("mouse") >= 0 ? "󰍽"
                        : deviceCard.device.icon.indexOf("phone") >= 0 ? "󰏲" : "󰂯"
                    color: deviceCard.device.connected ? Theme.iris : Theme.subtle
                    font.pixelSize: 22
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        Layout.fillWidth: true
                        text: deviceCard.device.name || deviceCard.device.address
                        font.bold: deviceCard.device.connected
                    }
                    Label {
                        Layout.fillWidth: true
                        text: BluetoothState.status(deviceCard.device)
                            + (deviceCard.device.batteryAvailable ? " · " + Math.round(deviceCard.device.battery * 100) + "% battery" : "")
                        color: deviceCard.device.connected ? Theme.foam : Theme.subtle
                        font.pixelSize: 10
                    }
                }
                NotificationButton {
                    objectName: "deviceAction"
                    text: BluetoothState.changing(deviceCard.device) ? "Working…" : deviceCard.device.connected ? "Disconnect"
                        : deviceCard.device.paired || deviceCard.device.bonded ? "Connect" : "Pair"
                    enabled: BluetoothState.enabled && !BluetoothState.busy && !BluetoothState.changing(deviceCard.device)
                        && !deviceCard.device.blocked
                    onClicked: {
                        if (deviceCard.device.connected) BluetoothState.disconnectDevice(deviceCard.device);
                        else BluetoothState.connectDevice(deviceCard.device);
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: deviceCard.device.address
                    color: Theme.muted
                    font.pixelSize: 10
                }
                NotificationButton {
                    objectName: "forgetDevice"
                    visible: deviceCard.device.paired || deviceCard.device.bonded
                    enabled: !BluetoothState.busy
                    text: "Forget"
                    implicitHeight: 24
                    onClicked: root.forgetTarget = deviceCard.device
                }
            }
        }
    }
    ColumnLayout {
        id: content
        x: 12; y: 12
        width: parent.width - 24
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: "Bluetooth"
                font.pixelSize: 18
                font.bold: true
            }
            NotificationButton {
                objectName: "scanButton"
                text: BluetoothState.scanning ? "Stop scan" : "Scan"
                enabled: BluetoothState.enabled && !BluetoothState.busy
                onClicked: BluetoothState.scan()
            }
        }
        Card {
            implicitHeight: 58
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        Layout.fillWidth: true
                        text: BluetoothState.adapter?.name || "Bluetooth"
                    }
                    Label {
                        Layout.fillWidth: true
                        text: !BluetoothState.available ? "No Bluetooth adapter" : BluetoothState.blocked ? "Blocked by hardware"
                            : BluetoothState.enabled ? "On" : "Off"
                        color: Theme.subtle
                        font.pixelSize: 10
                    }
                }
                ControlSwitch {
                    objectName: "bluetoothPower"
                    value: BluetoothState.enabled
                    enabled: BluetoothState.available && !BluetoothState.busy && !BluetoothState.blocked
                    Accessible.name: "Bluetooth power"
                    onChangeRequested: value => BluetoothState.setEnabled(value)
                }
            }
        }
        Card {
            implicitHeight: 46
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                Label { Layout.fillWidth: true; text: "Allow discovery" }
                ControlSwitch {
                    objectName: "allowDiscovery"
                    value: BluetoothState.discoverable
                    enabled: BluetoothState.enabled && !BluetoothState.busy
                    Accessible.name: "Allow Bluetooth discovery"
                    onChangeRequested: value => BluetoothState.setDiscoverable(value)
                }
            }
        }
        Flow {
            Layout.fillWidth: true
            visible: BluetoothState.adapters.length > 1
            spacing: 6
            Repeater {
                model: BluetoothState.adapters
                NotificationButton {
                    required property var modelData
                    text: modelData.name + " · " + modelData.adapterId
                    width: Math.min(implicitWidth, content.width)
                    accent: modelData === BluetoothState.adapter
                    enabled: !BluetoothState.busy
                    onClicked: BluetoothState.selectAdapter(modelData)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: BluetoothState.errorMessage.length > 0 || BluetoothState.busy
            Label {
                id: message
                Layout.fillWidth: true
                text: BluetoothState.errorMessage || BluetoothState.busyLabel
                color: BluetoothState.errorMessage ? Theme.love : Theme.iris
                wrapMode: Text.Wrap
                maximumLineCount: 3
                font.pixelSize: 11
            }
            NotificationButton {
                visible: BluetoothState.busy && BluetoothState.operation === "pair" && !BluetoothState.prompt
                text: "Cancel"
                onClicked: BluetoothState.cancel()
            }
        }
        Card {
            id: promptBox
            readonly property bool needsInput: BluetoothState.prompt?.kind === "pin" || BluetoothState.prompt?.kind === "passkey"
            visible: BluetoothState.prompt !== null
            implicitHeight: promptContent.implicitHeight + 20
            border.color: Theme.iris
            ColumnLayout {
                id: promptContent
                x: 10; y: 10
                width: parent.width - 20
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    text: BluetoothState.deviceName
                    font.bold: true
                }
                Label {
                    Layout.fillWidth: true
                    text: promptBox.needsInput ? "Enter the code shown on your device"
                        : BluetoothState.prompt?.kind === "display" ? "Type this code on your device, then press Enter"
                        : BluetoothState.prompt?.kind === "confirm" ? "Does this code match your device?" : "Allow this device to connect?"
                    wrapMode: Text.Wrap
                    color: Theme.subtle
                    font.pixelSize: 11
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !!BluetoothState.prompt?.code
                    text: BluetoothState.prompt?.code || ""
                    color: Theme.iris
                    font.pixelSize: 26
                    font.letterSpacing: 4
                }
                TextField {
                    id: pin
                    objectName: "pairingInput"
                    Layout.fillWidth: true
                    visible: promptBox.needsInput
                    implicitHeight: 34
                    maximumLength: BluetoothState.prompt?.kind === "passkey" ? 6 : 16
                    placeholderText: "PIN / passkey"
                    color: Theme.text
                    placeholderTextColor: Theme.muted
                    selectionColor: Theme.iris
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    Accessible.name: "Bluetooth pairing code"
                    background: Rectangle {
                        color: Theme.overlay
                        radius: 8
                        border.color: pin.activeFocus ? Theme.iris : Theme.highlightMed
                    }
                    onAccepted: BluetoothState.respond(true, text)
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    NotificationButton {
                        text: "Cancel"
                        onClicked: BluetoothState.cancel()
                    }
                    NotificationButton {
                        objectName: "confirmPairing"
                        text: promptBox.needsInput ? "Pair" : "Confirm"
                        accent: true
                        visible: BluetoothState.prompt?.kind !== "display"
                        enabled: !promptBox.needsInput || pin.text.length > 0
                        onClicked: BluetoothState.respond(true, pin.text)
                    }
                }
            }
        }
        Card {
            id: forgetBox
            visible: root.forgetTarget !== null
            implicitHeight: forgetContent.implicitHeight + 20
            ColumnLayout {
                id: forgetContent
                x: 10; y: 10
                width: parent.width - 20
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    text: "Forget " + (root.forgetTarget?.name || "device") + "?"
                    wrapMode: Text.Wrap
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    NotificationButton { text: "Cancel"; onClicked: root.forgetTarget = null }
                    NotificationButton {
                        objectName: "confirmForget"
                        text: "Forget"
                        enabled: !BluetoothState.busy
                        onClicked: {
                            BluetoothState.forgetDevice(root.forgetTarget);
                            root.forgetTarget = null;
                        }
                    }
                }
            }
        }
        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(deviceList.implicitHeight, Math.max(100, root.maximumHeight - 218
                - (promptBox.visible ? promptBox.implicitHeight + 12 : 0)
                - (forgetBox.visible ? forgetBox.implicitHeight + 12 : 0)
                - (message.visible ? message.implicitHeight : 0)))
            contentWidth: availableWidth
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                id: deviceList
                width: scroll.availableWidth
                spacing: 10
                Label {
                    Layout.fillWidth: true
                    visible: !BluetoothState.enabled
                    text: BluetoothState.available ? "Turn on Bluetooth to connect devices" : "Connect a Bluetooth adapter to get started"
                    color: Theme.muted
                    wrapMode: Text.Wrap
                }
                SectionTitle { visible: BluetoothState.enabled; text: "CONNECTED" }
                Label {
                    visible: BluetoothState.enabled && BluetoothState.connectedDevices.length === 0
                    text: "No connected devices"
                    color: Theme.muted
                }
                Repeater {
                    model: BluetoothState.enabled ? BluetoothState.connectedDevices : []
                    DeviceCard { required property var modelData; device: modelData }
                }
                SectionTitle { visible: BluetoothState.enabled; text: "PAIRED" }
                Label {
                    visible: BluetoothState.enabled && BluetoothState.savedDevices.length === 0
                    text: "No paired devices"
                    color: Theme.muted
                }
                Repeater {
                    model: BluetoothState.enabled ? BluetoothState.savedDevices : []
                    DeviceCard { required property var modelData; device: modelData }
                }
                SectionTitle { visible: BluetoothState.enabled; text: "NEARBY" }
                Label {
                    Layout.fillWidth: true
                    visible: BluetoothState.enabled && BluetoothState.nearbyDevices.length === 0
                    text: BluetoothState.scanning ? "Searching for devices…" : "Scan to find devices in pairing mode"
                    color: Theme.muted
                    wrapMode: Text.Wrap
                }
                Repeater {
                    model: BluetoothState.enabled ? BluetoothState.nearbyDevices : []
                    DeviceCard { required property var modelData; device: modelData }
                }
            }
        }
    }
}
