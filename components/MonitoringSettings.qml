import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

UI.ColumnLayout {
    id: root
    property bool active: false
    signal backRequested
    spacing: Design.space12
    onActiveChanged: SystemStats.panels += active ? 1 : -1
    Component.onDestruction: { if (active) SystemStats.panels--; }
    readonly property var entries: {
        const entries = SystemStats.metrics.slice();
        Object.keys(Monitoring.modes).forEach(id => {
            if (!entries.some(entry => entry.id === id))
                entries.push({id: id, label: id, available: false, reason: "Device unavailable"});
        });
        return entries;
    }
    component Label: UI.Text {
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    UI.RowLayout {
        Layout.fillWidth: true
        UI.IconButton { text: "‹"; Layout.preferredWidth: 32; Accessible.name: "Back to bar layout"; onClicked: root.backRequested() }
        Label { text: "PC monitoring"; role: "panel"; Layout.fillWidth: true }
    }
    Repeater {
        model: root.entries
        delegate: UI.Card {
            id: card
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: row.implicitHeight + Design.panelPadding * 2

            UI.RowLayout {
                id: row
                x: Design.panelPadding; y: Design.panelPadding
                width: parent.width - Design.panelPadding * 2
                spacing: Design.space12
                UI.ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Design.space4
                    Label { text: card.modelData.label; Layout.fillWidth: true }
                    Label {
                        Layout.fillWidth: true
                        text: card.modelData.available ? SystemStats.format(card.modelData) + (card.modelData.source ? " · " + card.modelData.source : "") : card.modelData.reason
                        color: Design.textSecondary
                        role: "label"
                    }
                }
                Repeater {
                    model: ["off", "short", "long"]
                    delegate: NotificationButton {
                        required property string modelData
                        objectName: "monitoring-" + card.modelData.id + "-" + modelData
                        text: modelData[0].toUpperCase() + modelData.slice(1)
                        accent: Monitoring.mode(card.modelData.id) === modelData
                        enabled: Monitoring.ready
                        Accessible.name: card.modelData.label + " " + text
                        onClicked: Monitoring.setMode(card.modelData.id, modelData)
                    }
                }
            }
        }
    }
    Label { text: "CPU temperature sensor"; Layout.fillWidth: true }
    UI.ComboBox {
        id: sensorChoice
        objectName: "monitoring-temperature-source"
        Layout.fillWidth: true
        textRole: "label"
        valueRole: "id"
        enabled: Monitoring.ready
        model: {
            const sources = [{id: "", label: "Automatic"}].concat(SystemStats.temperatureSources);
            if (Monitoring.cpuSensor && !sources.some(source => source.id === Monitoring.cpuSensor))
                sources.push({id: Monitoring.cpuSensor, label: "Saved sensor (unavailable)"});
            return sources;
        }
        currentIndex: Math.max(0, model.findIndex(source => source.id === Monitoring.cpuSensor))
        onActivated: Monitoring.setCpuSensor(currentValue)
        wheelEnabled: false
    }
    Label {
        Layout.fillWidth: true
        visible: text !== ""
        text: Monitoring.errorMessage || SystemStats.errorMessage
        color: Design.danger
    }
}
