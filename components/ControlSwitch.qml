import QtQuick
import QtQuick.Layouts
import "../config"
import "ui" as UI

UI.Switch {
    id: root
    property bool value: false
    signal changeRequested(bool value)
    checked: value
    onToggled: {
        const requested = checked;
        checked = Qt.binding(() => root.value);
        changeRequested(requested);
    }
    Layout.minimumWidth: Design.switchWidth
    Layout.preferredWidth: Design.switchWidth
    Layout.maximumWidth: Design.switchWidth
    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
}
