import QtQuick
import "../../config"

ControlSurface {
    // Follow the popup transition in both directions, including interrupted opens.
    property real reveal: 0
    bottomLeftRadius: radius * (1 - reveal)
    bottomRightRadius: radius * (1 - reveal)
}
