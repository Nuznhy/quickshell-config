import QtQuick
import "../../../components/ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../config"
import "../../../services"
import "../../../components"

DropdownWidget {
    id: root
    barWindow: root.QsWindow.window
    readonly property var entries: SystemStats.metrics.filter(entry => Monitoring.mode(entry.id) !== "off")
    // Keep delegates alive while sample values change.
    readonly property string entryIds: JSON.stringify(entries.map(entry => entry.id))
    implicitWidth: cells.implicitWidth
    implicitHeight: Theme.verticalBar ? cells.implicitHeight : Settings.barHeight
    Layout.preferredHeight: implicitHeight
    popupWidth: Math.min(580, (barWindow?.screen?.width || 800) - 32)
    sizeToContent: true
    showStem: false
    rightClickEnabled: true
    onRightClicked: SystemStats.openBtop()
    UI.GridLayout {
        id: cells
        rows: Theme.verticalBar ? -1 : 1
        columns: Theme.verticalBar ? 1 : -1
        rowSpacing: Settings.widgetSpacing
        columnSpacing: Settings.widgetSpacing
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: JSON.parse(root.entryIds)
            delegate: Item {
                id: cell
                required property string modelData
                readonly property var metric: SystemStats.metric(modelData) || ({id: modelData, label: "", available: false, reason: ""})
                objectName: "monitoring-cell-" + modelData
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                readonly property bool longMode: Monitoring.mode(modelData) === "long"
                implicitWidth: Theme.verticalBar ? Math.max(26, longMode ? 48 : 26) : longMode ? Math.max(74, labelMetrics.advanceWidth + 26) : 38
                implicitHeight: Theme.verticalBar ? (longMode ? Math.max(62, Theme.fontSize + 44) : Math.max(36, Theme.fontSize + 10)) : Settings.barHeight
                TextMetrics {
                    id: labelMetrics
                    font.family: Theme.barFontFamily
                    font.pixelSize: Theme.fontSize
                    text: cell.metric.unit === "B" ? ((cell.metric.total || 0) / 1073741824).toFixed(1).replace(/[0-9]/g, "8") + "/" + ((cell.metric.total || 0) / 1073741824).toFixed(1).replace(/[0-9]/g, "8") + " GiB" : cell.metric.unit === "W" ? "888.8 W" : "100 °C"
                }
                UI.Text {
                    role: "bar"
                    x: Theme.verticalBar ? (parent.width - width) / 2 : 0
                    y: Theme.verticalBar ? 0 : (parent.height - height) / 2 - 3
                    text: SystemStats.icon(cell.metric)
                    color: Design.text
                    font.family: Design.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                UI.Text {
                    role: "bar"
                    visible: cell.longMode
                    x: Theme.verticalBar ? 0 : 24
                    y: Theme.verticalBar ? Math.max(23, Theme.fontSize + 5) : (parent.height - height) / 2 - 3
                    width: Theme.verticalBar ? parent.width : parent.width - 24
                    text: Theme.verticalBar && cell.metric.unit === "B" && cell.metric.available
                        ? (cell.metric.value / 1073741824).toFixed(1) + "G\n/" + (cell.metric.total / 1073741824).toFixed(1) + "G" : SystemStats.format(cell.metric)
                    horizontalAlignment: Theme.verticalBar ? Text.AlignHCenter : Text.AlignLeft
                    color: cell.metric.available ? Design.text : Design.textSecondary
                    font.family: Theme.barFontFamily
                    font.pixelSize: Theme.verticalBar ? Math.min(12, Theme.fontSize) : Theme.fontSize
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.verticalBar ? 0 : 4
                    width: parent.width
                    height: 3
                    radius: Design.radiusSmall
                    color: Design.border
                    Rectangle {
                        width: parent.width * (cell.metric.available ? Math.max(0, Math.min(1, cell.metric.value / SystemStats.maximum(cell.metric))) : 0)
                        height: parent.height
                        radius: parent.radius
                        color: Design.accent
                        Behavior on width { NumberAnimation { duration: 180 } }
                    }
                }
                Accessible.name: cell.metric.label
                Accessible.description: cell.metric.available ? SystemStats.format(cell.metric) : cell.metric.reason
            }
        }
        UI.Text {
            role: "bar"
            visible: root.entries.length === 0
            text: "󰍹"
            color: Design.text
            font.family: Design.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.preferredHeight: Settings.barHeight
            verticalAlignment: Text.AlignVCenter
        }
    }
    popupContent: MonitoringCenter {
        active: root.dropdownOpen
        maximumHeight: Math.max(100, Math.min(650, (root.barWindow?.screen?.height || 800) - 110))
        onDismissed: root.dropdownOpen = false
    }
}
