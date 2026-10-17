import QtQuick
import QtQuick.Controls as C
import qs.config

C.Popup {
    id: root
    Connections {
        target: UiKit
        function onActiveIdChanged() {
            root.close();
        }
    }
    padding: Design.space8
    margins: Design.space8
    popupType: C.Popup.Item
    focus: true
    closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutsideParent
    background: MenuSurface {}
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Design.durationNormal
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: Design.durationFast
        }
    }
}
