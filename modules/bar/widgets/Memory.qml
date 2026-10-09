import QtQuick
import "../../../components/ui" as UI
import "../../../config"
import "../../../services"
import "../../../components"

Item {
    id: memWidget
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.verticalBar ? Math.max(Settings.barHeight, label.implicitHeight + 8) : Settings.barHeight

    HoverHandler { id: hover }

    BarHoverIndicator {
        anchors.fill: parent
        hovered: hover.hovered
    }

    UI.Text {
        role: "bar"
        id: label
        anchors.centerIn: parent
        text: Theme.verticalBar ? "󰾆\n" + SystemStats.memUsage + "%" : SystemStats.memUsage + "% 󰾆"
        color: Design.text
        font.pixelSize: Theme.fontSize
        font.family: Theme.barFontFamily
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
