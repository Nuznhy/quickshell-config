import QtQuick
import QtQuick.Layouts
import qs.components.ui as UI
import qs.config

UI.ColumnLayout {
    spacing: Design.space8
    UI.ComboBox {
        objectName: "ui-kit-selector"
        Layout.fillWidth: true
        enabled: Theme.ready
        model: UiKit.kits
        textRole: "name"
        valueRole: "id"
        currentIndex: UiKit.kits.findIndex(kit => kit.id === Theme.uiKit)
        onActivated: Theme.selectUiKit(currentValue)
        Accessible.name: "UI kit"
    }
    UI.HelperText {
        Layout.fillWidth: true
        text: UiKit.kits.find(kit => kit.id === UiKit.activeId).description
        wrapMode: Text.WordWrap
    }
}
