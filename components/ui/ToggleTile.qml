import qs.components.ui as UI
import QtQuick
import QtQuick.Layouts
import qs.config

Button {
    id: root
    property string iconGlyph: ""
    property string iconName: ""
    implicitHeight: Math.max(64, implicitContentHeight + topPadding + bottomPadding)
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: checked
    contentItem: ColumnLayout {
        spacing: Design.space4
        Icon {
            name: root.iconName
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
