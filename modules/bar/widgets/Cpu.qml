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

    IconLabel {
        id: label
        anchors.centerIn: parent
        icon: "󰍛"
        text: SystemStats.cpuUsage + "%"
        iconAfterText: true
        color: Design.barColor("text")
    }
}
