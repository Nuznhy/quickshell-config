import QtQuick
import "../../../config"
import "../../../services"

Text {
    id: cpuWidget

    text: SystemStats.cpuUsage + "% 󰍛"
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true
}
