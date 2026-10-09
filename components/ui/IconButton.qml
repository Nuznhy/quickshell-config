import "." as UI
import "../../config"

Button {
    id: root
    implicitWidth: implicitHeight
    leftPadding: Design.space4
    rightPadding: Design.space4
    font.family: Design.iconFontFamily
    font.pixelSize: Design.iconLarge
    contentItem: UI.Icon {
        text: root.text
        size: root.font.pixelSize
        font: root.font
        color: root.foreground
    }
}
