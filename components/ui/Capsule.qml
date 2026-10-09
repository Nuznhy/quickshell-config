import QtQuick
import "../../config"

Card {
    readonly property color foreground: Design.readableText(color)
    radius: height / 2
    color: Design.surfaceRaised
}
