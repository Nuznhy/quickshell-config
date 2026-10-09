import "." as UI
import QtQuick
import QtQuick.Templates as T
import "../../config"

T.RadioButton {
    id: root
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(Design.controlHeight, implicitContentHeight + topPadding + bottomPadding)
    spacing: Design.space8
    padding: Design.space4
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Design.disabledOpacity
    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    indicator: ChoiceIndicator { control: root; radio: true }
    contentItem: UI.Text {
        text: root.text
        leftPadding: root.indicator.width + root.spacing
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
