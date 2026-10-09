import "." as UI
import QtQuick
import "../../config"

Button {
    id: root
    variant: "ghost"
    highlighted: checked
    contentItem: UI.Text {
        text: root.text
        font: root.font
        color: root.foreground
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
