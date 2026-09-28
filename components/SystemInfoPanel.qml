import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

ColumnLayout {
    id: root
    property bool active: false
    property bool expanded: false
    readonly property bool showing: active && expanded
    spacing: 8
    onShowingChanged: {
        SystemInfo.openPanels += showing ? 1 : -1;
        BatteryState.openPanels += showing ? 1 : -1;
        if (showing) NetworkState.refresh();
    }
    Component.onDestruction: {
        if (showing) { SystemInfo.openPanels--; BatteryState.openPanels--; }
    }
    NotificationButton {
        objectName: "system-info-expand"
        Layout.fillWidth: true
        text: "System info  " + (root.expanded ? "󰅃" : "󰅀")
        Accessible.name: "System information"
        onClicked: root.expanded = !root.expanded
    }
    ScrollView {
        visible: root.expanded
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(280, rows.implicitHeight)
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: rows
            width: parent.width
            spacing: 8
            Repeater {
                model: [
                    {label: "OS", value: SystemInfo.details.os || "…"},
                    {label: "Kernel", value: SystemInfo.details.kernel || "…"},
                    {label: "CPU", value: SystemInfo.details.cpu || "…"},
                    {label: "GPU", value: SystemInfo.details.gpu || "…"},
                    {label: "RAM", value: SystemInfo.details.ram || "…"},
                    {label: "Home drive", value: SystemInfo.details.disk || "…"}
                ].concat(BatteryState.batteries.map(b => ({label: b.id, value: (b.percent === null ? "—" : b.percent + "%") + " · " + b.status})))
                 .concat(NetworkState.connections.filter(c => c.state === "activated").map(c => ({label: c.vpn ? "VPN" : "Network", value: c.name + "\n" + c.devices.join(", ") + " · " + c.ipv4.concat(c.ipv6).join(", ")})))
                 .concat(NetworkState.connections.some(c => c.state === "activated") ? [] : [{label: "Network", value: NetworkState.statusError || "Disconnected"}])
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 10
                    Text {
                        Layout.preferredWidth: 68
                        Layout.alignment: Qt.AlignTop
                        text: modelData.label
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.value
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        wrapMode: Text.WrapAnywhere
                        textFormat: Text.PlainText
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Updates (repos): " + (SystemInfo.checkingUpdates ? "Checking…" : SystemInfo.updateCount < 0 ? "Unknown" : SystemInfo.updateCount)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                NotificationButton {
                    text: "󰑐"
                    implicitWidth: 30
                    enabled: !SystemInfo.checkingUpdates
                    Accessible.name: "Check repository updates"
                    onClicked: SystemInfo.checkUpdates()
                }
            }
            Text {
                Layout.fillWidth: true
                visible: SystemInfo.checkedAt > 0
                text: "Checked " + Qt.formatDateTime(new Date(SystemInfo.checkedAt), "hh:mm")
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: [SystemInfo.errorMessage, SystemInfo.updateError].filter(Boolean).join("\n")
                color: Theme.love
                font.family: Theme.fontFamily
                font.pixelSize: 10
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }
        }
    }
}
