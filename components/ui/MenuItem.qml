import "." as UI
import QtQuick
import "../../config"

Button {
    id: root
    variant: "ghost"
    highlighted: checked
    background: ControlSurface {
        control: root
        variant: root.variant
        selected: root.checked || root.highlighted
        accentColor: root.accentColor
        radius: 0
    }
    contentItem: UI.Text {
        text: root.text
        font: root.font
        color: root.foreground
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
