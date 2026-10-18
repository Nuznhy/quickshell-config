import qs.components.ui as UI
import QtQuick

Button {
    id: root
    variant: "ghost"
    controlKind: "menuItem"
    highlighted: checked
    background: ControlSurface {
        control: root
        controlKind: root.controlKind
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
