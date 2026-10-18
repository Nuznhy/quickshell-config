import QtQuick
import QtQuick.Layouts
import qs.components.ui as UI
import qs.config

GridLayout {
    id: root
    property string icon: ""
    property string text: ""
    property bool iconAfterText: false
    property color color: Design.barColor("text")
    columns: Theme.verticalBar ? 1 : 2
    rowSpacing: 0
    columnSpacing: Design.space8

    UI.Icon {
        Layout.row: 0
        Layout.column: !Theme.verticalBar && root.iconAfterText ? 1 : 0
        Layout.alignment: Qt.AlignCenter
        text: root.icon
        size: Theme.fontSize
        color: root.color
    }
    UI.Text {
        Layout.row: Theme.verticalBar ? 1 : 0
        Layout.column: Theme.verticalBar || root.iconAfterText ? 0 : 1
        Layout.alignment: Qt.AlignCenter
        role: "bar"
        text: root.text
        color: root.color
        font.pixelSize: Theme.fontSize
        font.family: Theme.barFontFamily
        font.bold: true
    }
}
