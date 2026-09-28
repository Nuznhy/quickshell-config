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
    Connections {
        target: BatteryState
        function onChangingChanged() { if (!BatteryState.changing && !BatteryState.errorMessage) root.drafts = {}; }
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
