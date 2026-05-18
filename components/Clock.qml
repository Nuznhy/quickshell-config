import QtQuick
import Quickshell
import QtQuick.Layouts
import ".."

Text {
    text: Time.time
    color: Theme.text
    font.pixelSize: Theme.fontSize - 2
    font.family: Theme.fontFamily
    font.bold: true
}

