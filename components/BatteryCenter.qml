import QtQuick
import "ui" as UI
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
    component Label: UI.Text {
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    UI.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        UI.ColumnLayout {
            id: content
            width: parent.width
            spacing: Design.space12
            Label { text: "Battery"; role: "section" }
            Label { text: "Power profile"; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: Design.space4
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
                color: Design.textSecondary
                role: "caption"
                text: BatteryState.powerProfiles.available
                    ? "Controls your laptop's performance, power use and cooling. Authorization may be required."
                    : "Power profiles are not exposed by this device's firmware."
            }
            Repeater {
                model: BatteryState.batteries
                UI.Card {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: details.implicitHeight + Design.panelPadding * 2

                    UI.ColumnLayout {
                        id: details
                        x: Design.panelPadding; y: Design.panelPadding
                        width: parent.width - Design.panelPadding * 2
                        spacing: Design.space8
                        Label {
                            Layout.fillWidth: true
                            text: card.modelData.model + " · " + card.modelData.id
                            font.bold: true
                        }
                        Label {
                            Layout.fillWidth: true
                            text: (card.modelData.percent === null ? "Unknown charge" : card.modelData.percent + "%") + " · " + card.modelData.status
                            color: Design.accent
                            role: "section"
                        }
                        Label {
                            objectName: "battery-estimate-" + card.modelData.id
                            Layout.fillWidth: true
                            text: root.estimateText(card.modelData)
                            visible: text.length > 0
                            color: Design.textSecondary
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
                            color: Design.textSecondary
                            role: "caption"
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
                        UI.RowLayout {
                            visible: card.modelData.limitSupported
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: "Current limit: " + card.modelData.limit + "%"
                                color: Design.textSecondary
                                role: "caption"
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
                            color: Design.textSecondary
                            role: "caption"
                        }
                    }
                }
            }
            Label { Layout.fillWidth: true; visible: !BatteryState.present; text: "No laptop battery detected."; color: Design.textSecondary }
            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: BatteryState.changing ? "Applying… Authorize the request if prompted." : BatteryState.errorMessage || BatteryState.message
                color: BatteryState.errorMessage ? Design.danger : Design.textSecondary
                role: "caption"
            }
        }
    }
}
