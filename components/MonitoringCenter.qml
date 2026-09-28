import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

FocusScope {
    id: root
    property bool active: false
    property int maximumHeight: 600
    implicitHeight: Math.min(maximumHeight, content.implicitHeight)
    signal dismissed
    onActiveChanged: { if (active) forceActiveFocus(); }
    Keys.onEscapePressed: dismissed()
    component Label: Text {
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            id: content
            width: scroll.availableWidth
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Label { text: "PC monitoring"; font.pixelSize: 17; Layout.fillWidth: true }
                Label { text: "10 min"; color: Theme.subtle }
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: SystemStats.launchError || SystemStats.errorMessage
                color: Theme.love
            }
            GridLayout {
                Layout.fillWidth: true
                columns: width >= 480 ? 2 : 1
                columnSpacing: 12
                rowSpacing: 12
                Repeater {
                    model: SystemStats.metrics.filter(entry => entry.id === "cpu.power" || entry.available || (SystemStats.history[entry.id] || []).some(point => point.value !== null))
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        objectName: "monitoring-graph-" + modelData.id
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        implicitHeight: 180
                        color: Theme.surface
                        radius: 10
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 5
                            Label {
                                Layout.fillWidth: true
                                text: card.modelData.label
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.pixelSize: 11
                            }
                            Label { text: SystemStats.format(card.modelData); font.pixelSize: 18; font.bold: true }
                            Label {
                                Layout.fillWidth: true
                                visible: !card.modelData.available
                                text: card.modelData.reason || "Sensor unavailable"
                                color: Theme.subtle
                                font.pixelSize: 11
                            }
                            MonitoringGraph {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                points: SystemStats.history[card.modelData.id] || []
                                maximum: SystemStats.maximum(card.modelData)
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: card.modelData.available || (SystemStats.history[card.modelData.id] || []).some(point => point.value !== null)
                                Label { text: "−10m"; font.pixelSize: 10; color: Theme.subtle }
                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 10
                                    color: Theme.subtle
                                    text: {
                                        const max = SystemStats.maximum(card.modelData);
                                        const range = card.modelData.unit === "B" ? (max / 1073741824).toFixed(1) + " GiB" : Math.round(max) + " " + card.modelData.unit;
                                        return "0–" + range + (card.modelData.maximum > 0 ? "" : " · peak");
                                    }
                                }
                                Label { text: "Now"; font.pixelSize: 10; color: Theme.subtle }
                            }
                        }
                    }
                }
            }
            Label {
                visible: !SystemStats.metrics.some(entry => entry.available)
                text: "Waiting for monitoring data…"
                color: Theme.subtle
            }
        }
    }
}
