import QtQuick
import qs.components.shared
import qs.components.ui as UI
import qs.config
import qs.services.monitoring

Item {
    id: cpuWidget
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.verticalBar ? Math.max(Settings.barHeight, label.implicitHeight + 8) : Settings.barHeight

    HoverHandler {
        id: hover
    }

    BarHoverIndicator {
        anchors.fill: parent
        hovered: hover.hovered
    }

    UI.Text {
        id: label
        role: "bar"
        anchors.centerIn: parent
        text: Theme.verticalBar ? "󰍛\n" + SystemStats.cpuUsage + "%" : SystemStats.cpuUsage + "% 󰍛"
        horizontalAlignment: Text.AlignHCenter
        color: Design.text
        font.pixelSize: Theme.fontSize
        font.family: Theme.barFontFamily
        font.bold: true
    }
}
