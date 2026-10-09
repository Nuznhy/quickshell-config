import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

UI.ColumnLayout {
    id: root
    property bool active: false
    property bool expanded: false
    readonly property bool showing: active && expanded
    property real revealProgress: expanded ? 1 : 0
    Behavior on revealProgress {
        NumberAnimation { duration: Design.durationNormal; easing.type: Easing.InOutCubic }
    }
    // Include the section gap in the reveal so it cannot jump at either end.
    spacing: 0
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
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: (Design.space8 + details.height) * root.revealProgress
        clip: true
        visible: root.revealProgress > 0
        enabled: root.expanded

        UI.ScrollView {
            id: details
            y: Design.space8
            width: parent.width
            height: Math.min(280, rows.implicitHeight)
            opacity: root.revealProgress
            contentWidth: availableWidth
            clip: true
            UI.ColumnLayout {
                id: rows
                width: details.availableWidth
                spacing: Design.space8
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
                    UI.RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Design.space8
                        UI.Text {
                            Layout.preferredWidth: 68
                            Layout.alignment: Qt.AlignTop
                            text: modelData.label
                            color: Design.textSecondary
                            font.family: Design.fontFamily
                            role: "caption"
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }
                        UI.Text {
                            Layout.fillWidth: true
                            text: modelData.value
                            color: Design.text
                            font.family: Design.fontFamily
                            role: "caption"
                            wrapMode: Text.WrapAnywhere
                            textFormat: Text.PlainText
                        }
                    }
                }
                UI.RowLayout {
                    Layout.fillWidth: true
                    UI.Text {
                        Layout.fillWidth: true
                        text: "Updates (repos): " + (SystemInfo.checkingUpdates ? "Checking…" : SystemInfo.updateCount < 0 ? "Unknown" : SystemInfo.updateCount)
                        color: Design.text
                        font.family: Design.fontFamily
                        role: "caption"
                    }
                    UI.IconButton {
                        text: "󰑐"
                        implicitWidth: 30
                        enabled: !SystemInfo.checkingUpdates
                        Accessible.name: "Check repository updates"
                        onClicked: SystemInfo.checkUpdates()
                    }
                }
                UI.Text {
                    Layout.fillWidth: true
                    visible: SystemInfo.checkedAt > 0
                    text: "Checked " + Qt.formatDateTime(new Date(SystemInfo.checkedAt), "hh:mm")
                    color: Design.textSecondary
                    font.family: Design.fontFamily
                    role: "caption"
                }
                UI.Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: [SystemInfo.errorMessage, SystemInfo.updateError].filter(Boolean).join("\n")
                    color: Design.danger
                    font.family: Design.fontFamily
                    role: "caption"
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
