import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

FocusScope {
    id: root
    property bool active: false
    property int maximumHeight: 600
    property var drafts: ({})
    implicitHeight: Math.min(maximumHeight, content.implicitHeight)
    signal dismissed
    onActiveChanged: {
        BatteryState.openPanels += active ? 1 : -1;
        if (active) forceActiveFocus();
    }
    Component.onDestruction: { if (active) BatteryState.openPanels--; }
    Keys.onEscapePressed: { if (!BatteryState.changing) dismissed(); }
    function edit(id, value) {
        const next = Object.assign({}, drafts);
        next[id] = Math.round(value);
        drafts = next;
    }
    function estimateText(battery) {
        if (battery.status !== "Charging" && battery.status !== "Discharging") return "";
        const target = battery.status === "Discharging" ? "until empty"
            : battery.chargeTarget > 0 && battery.chargeTarget < 100 ? "to " + battery.chargeTarget + "% limit" : "until full";
        const seconds = battery.timeRemaining;
        if (typeof seconds !== "number" || !Number.isFinite(seconds) || seconds < 0)
            return "Time " + target + ": unavailable";
        if (seconds < 60) return "Estimated " + target + ": less than 1 min";
        const minutes = Math.ceil(seconds / 60);
        const hours = Math.floor(minutes / 60);
        return "Estimated " + target + ": " + (hours ? hours + " h" + (minutes % 60 ? " " : "") : "")
            + (minutes % 60 ? minutes % 60 + " min" : "");
    }
    Connections {
        target: BatteryState
        function onChangingChanged() {
            if (!BatteryState.changing && !BatteryState.errorMessage && BatteryState.actionKind === "limit") root.drafts = {};
        }
    }
    component Label: Text {
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: content
            width: parent.width
            spacing: 12
            Label { text: "Battery"; font.pixelSize: 16 }
            Label { text: "Power profile"; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: BatteryState.powerProfiles.profiles
                    NotificationButton {
                        required property var modelData
                        objectName: "power-profile-" + modelData.id
                        text: modelData.label
                        accent: BatteryState.powerProfiles.current === modelData.id
                        enabled: BatteryState.powerProfiles.available && !BatteryState.changing
                        Accessible.name: modelData.label + " power profile"
                        Accessible.checkable: true
                        Accessible.checked: accent
                        onClicked: BatteryState.setProfile(modelData.id)
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                color: Theme.subtle
                font.pixelSize: 10
                text: BatteryState.powerProfiles.available
                    ? "Controls your laptop's performance, power use and cooling. Authorization may be required."
                    : "Power profiles are not exposed by this device's firmware."
            }
            Repeater {
                model: BatteryState.batteries
                Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: details.implicitHeight + 24
                    color: Theme.surface
                    radius: 10
                    ColumnLayout {
                        id: details
                        x: 12; y: 12
                        width: parent.width - 24
                        spacing: 10
                        Label {
                            Layout.fillWidth: true
                            text: card.modelData.model + " · " + card.modelData.id
                            font.bold: true
                        }
                        Label {
                            Layout.fillWidth: true
                            text: (card.modelData.percent === null ? "Unknown charge" : card.modelData.percent + "%") + " · " + card.modelData.status
                            color: Theme.iris
                            font.pixelSize: 16
                        }
                        Label {
                            objectName: "battery-estimate-" + card.modelData.id
                            Layout.fillWidth: true
                            text: root.estimateText(card.modelData)
                            visible: text.length > 0
                            color: Theme.subtle
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "Health: " + (card.modelData.health === null ? "Unavailable" : card.modelData.health + "%")
                                + (card.modelData.cycles === null ? "" : " · " + card.modelData.cycles + " cycles")
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: card.modelData.full !== null && card.modelData.design !== null
                            text: Number(card.modelData.full).toFixed(1) + " / " + Number(card.modelData.design).toFixed(1) + " " + card.modelData.unit + " · full / design"
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                        AppearanceSlider {
                            objectName: "charge-limit-" + card.modelData.id
                            Layout.fillWidth: true
                            visible: card.modelData.limitSupported
                            enabled: !BatteryState.changing
                            label: "Charge limit"
                            minimum: 50
                            maximum: 100
                            suffix: "%"
                            value: root.drafts[card.modelData.id] ?? card.modelData.limit ?? 100
                            onValueEdited: value => root.edit(card.modelData.id, value)
                        }
                        RowLayout {
                            visible: card.modelData.limitSupported
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: "Current limit: " + card.modelData.limit + "%"
                                color: Theme.subtle
                                font.pixelSize: 10
                            }
                            NotificationButton {
                                objectName: "apply-limit-" + card.modelData.id
                                text: "󰄬"
                                implicitWidth: 34
                                accent: true
                                enabled: !BatteryState.changing && root.drafts[card.modelData.id] !== undefined && root.drafts[card.modelData.id] !== card.modelData.limit
                                Accessible.name: "Apply charge limit for " + card.modelData.id
                                onClicked: BatteryState.setLimit(card.modelData.id, root.drafts[card.modelData.id])
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            text: card.modelData.limitSupported
                                ? "Hardware stops charging at the applied limit. 100% allows a full charge."
                                : "Charge limiting is not supported by this battery driver."
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                    }
                }
            }
            Label { Layout.fillWidth: true; visible: !BatteryState.present; text: "No laptop battery detected."; color: Theme.subtle }
            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: BatteryState.changing ? "Applying… Authorize the request if prompted." : BatteryState.errorMessage || BatteryState.message
                color: BatteryState.errorMessage ? Theme.love : Theme.subtle
                font.pixelSize: 10
            }
        }
    }
}
