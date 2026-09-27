import QtQuick
import "../../../config"
import "../../../services"

Text {
    id: memWidget

    text: SystemStats.memUsage + "% 󰾆"
    color: Theme.text
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
