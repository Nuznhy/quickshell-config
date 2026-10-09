import "." as UI
import QtQuick
import QtQuick.Layouts
import "../../config"

Button {
    id: root
    property string iconGlyph: ""
    implicitHeight: Math.max(64, implicitContentHeight + topPadding + bottomPadding)
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: checked
    contentItem: ColumnLayout {
        spacing: Design.space4
        Icon {
            Layout.fillWidth: true
            text: root.iconGlyph
            size: Design.iconLarge
            color: root.foreground
        }
        UI.Text {
            Layout.fillWidth: true
            role: "caption"
            text: root.text
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: root.foreground
        }
    }
}
