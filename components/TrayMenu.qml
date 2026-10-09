import QtQuick
import "ui" as UI
import QtQuick.Controls
import "../config"

Menu {
    id: root

    background: UI.MenuSurface {
        implicitWidth: 180
    }

    delegate: MenuItem {
        id: itemDelegate
        required property var modelData

        text: modelData.label
        enabled: modelData.enabled
        visible: modelData.visible

        contentItem: UI.Text {
            text: itemDelegate.text
            color: itemDelegate.highlighted ? Design.textOnAccent : Design.text
            role: "body"
            verticalAlignment: Text.AlignVCenter
            leftPadding: Design.space8
        }

        background: UI.ControlSurface {
            control: itemDelegate
            variant: "ghost"
            selected: itemDelegate.highlighted
        }
    }
}
