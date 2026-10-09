import QtQuick
import "../../../config"
import "../../../services"
import "../../../components"

Item {
    id: cpuWidget
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.verticalBar ? Math.max(Settings.barHeight, label.implicitHeight + 8) : Settings.barHeight

    HoverHandler { id: hover }

    BarHoverIndicator {
        anchors.fill: parent
        hovered: hover.hovered
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Theme.verticalBar ? "󰍛\n" + SystemStats.cpuUsage + "%" : SystemStats.cpuUsage + "% 󰍛"
        horizontalAlignment: Text.AlignHCenter
        color: Theme.text
        font.pixelSize: Theme.fontSize
        font.family: Theme.barFontFamily
        font.bold: true
    }
}
