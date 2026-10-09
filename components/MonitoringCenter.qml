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
    implicitHeight: Math.min(maximumHeight, content.implicitHeight)
    // Only membership changes should recreate graph canvases.
    readonly property string metricIds: JSON.stringify(SystemStats.metrics
        .filter(entry => entry.id === "cpu.power" || entry.available || (SystemStats.history[entry.id] || []).some(point => point.value !== null))
        .map(entry => entry.id))
    signal dismissed
    onActiveChanged: { if (active) forceActiveFocus(); }
    Keys.onEscapePressed: dismissed()
    component Label: UI.Text {
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    UI.ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        UI.ColumnLayout {
            id: content
            width: scroll.availableWidth
            spacing: Design.space12
            UI.RowLayout {
                Layout.fillWidth: true
                Label { text: "PC monitoring"; role: "section"; Layout.fillWidth: true }
                Label { text: "10 min"; color: Design.textSecondary }
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: SystemStats.launchError || SystemStats.errorMessage
                color: Design.danger
            }
            UI.GridLayout {
                Layout.fillWidth: true
                columns: width >= 480 ? 2 : 1
                columnSpacing: Design.space12
                rowSpacing: Design.space12
                Repeater {
                    model: JSON.parse(root.metricIds)
                    delegate: UI.Card {
                        id: card
                        required property string modelData
                        readonly property var metric: SystemStats.metric(modelData) || ({id: modelData, label: "", available: false, reason: ""})
                        objectName: "monitoring-graph-" + modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        implicitHeight: 180

                        UI.ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Design.space12
                            spacing: Design.space4
                            Label {
                                Layout.fillWidth: true
                                text: card.metric.label
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                role: "label"
                            }
                            Label { text: SystemStats.format(card.metric); role: "panel"; font.bold: true }
                            Label {
                                Layout.fillWidth: true
                                visible: !card.metric.available
                                text: card.metric.reason || "Sensor unavailable"
                                color: Design.textSecondary
                                role: "label"
                            }
                            MonitoringGraph {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                points: SystemStats.history[card.metric.id] || []
                                maximum: SystemStats.maximum(card.metric)
                            }
                            UI.RowLayout {
                                Layout.fillWidth: true
                                visible: card.metric.available || (SystemStats.history[card.metric.id] || []).some(point => point.value !== null)
                                Label { text: "−10m"; role: "caption"; color: Design.textSecondary }
                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    role: "caption"
                                    color: Design.textSecondary
                                    text: {
                                        const max = SystemStats.maximum(card.metric);
                                        const range = card.metric.unit === "B" ? (max / 1073741824).toFixed(1) + " GiB" : Math.round(max) + " " + card.metric.unit;
                                        return "0–" + range + (card.metric.maximum > 0 ? "" : " · peak");
                                    }
                                }
                                Label { text: "Now"; role: "caption"; color: Design.textSecondary }
                            }
                        }
                    }
                }
            }
            Label {
                visible: !SystemStats.metrics.some(entry => entry.available)
                text: "Waiting for monitoring data…"
                color: Design.textSecondary
            }
        }
    }
}
