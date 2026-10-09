pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../config"

RowLayout {
    id: root
    required property var model
    property int currentIndex: -1
    signal selected(int index)
    spacing: Design.space4
    function navigate(index) {
        selected(index);
        // Only move focus to a selection actually accepted by the caller.
        Qt.callLater(() => options.itemAt(currentIndex)?.forceActiveFocus());
    }
    Repeater {
        id: options
        model: root.model
        Button {
            required property int index
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            text: String(modelData)
            highlighted: root.currentIndex === index
            onClicked: root.selected(index)
            Accessible.role: Accessible.RadioButton
            Accessible.checkable: true
            Accessible.checked: highlighted
            Keys.onLeftPressed: root.navigate(Math.max(0, index - 1))
            Keys.onRightPressed: root.navigate(Math.min(root.model.length - 1, index + 1))
        }
    }
}
