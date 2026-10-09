import QtQuick
import QtQuick.Templates as T
import "../../config"

T.Pane {
    padding: Design.panelPadding
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    background: Card {}
}
