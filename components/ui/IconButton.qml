import QtQuick
import qs.components.ui as UI
import qs.config

Button {
    id: root
    property string iconName: ""
    Accessible.name: text || iconName
    implicitWidth: implicitHeight
    leftPadding: Design.space4
    rightPadding: Design.space4
    font.family: Design.iconFontFamily
    font.pixelSize: Design.iconLarge
    contentItem: UI.Icon {
        name: root.iconName
        text: root.text
        size: root.font.pixelSize
        font: root.font
        color: root.foreground
    }
}
