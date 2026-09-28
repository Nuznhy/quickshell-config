import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

ColumnLayout {
    id: root
    property bool active: false
    signal backRequested
    spacing: 12
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
    component Label: Text {
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    RowLayout {
        Layout.fillWidth: true
        NotificationButton { text: "‹"; Layout.preferredWidth: 32; Accessible.name: "Back to bar layout"; onClicked: root.backRequested() }
        Label { text: "PC monitoring"; font.pixelSize: 18; Layout.fillWidth: true }
    }
    Repeater {
        model: root.entries
        delegate: Rectangle {
            id: card
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: row.implicitHeight + 24
            color: Theme.surface
            radius: 10
            RowLayout {
                id: row
                x: 12; y: 12
                width: parent.width - 24
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label { text: card.modelData.label; Layout.fillWidth: true }
                    Label {
                        Layout.fillWidth: true
                        text: card.modelData.available ? SystemStats.format(card.modelData) + (card.modelData.source ? " · " + card.modelData.source : "") : card.modelData.reason
                        color: Theme.subtle
                        font.pixelSize: 11
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
    ComboBox {
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
        palette.button: Theme.overlay
        palette.buttonText: Theme.text
        palette.base: Theme.surface
        palette.text: Theme.text
        palette.highlight: Theme.iris
        palette.highlightedText: Theme.bg
    }
    Label {
        Layout.fillWidth: true
        visible: text !== ""
        text: Monitoring.errorMessage || SystemStats.errorMessage
        color: Theme.love
    }
}
