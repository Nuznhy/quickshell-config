import "." as UI
import QtQuick
import QtQuick.Controls as C
import QtQuick.Templates as T
import "../../config"

T.ComboBox {
    id: root
    property bool busy: false
    readonly property color foreground: Design.readableText(Design.fill("neutral", popup.visible, hovered, down, enabled, Design.accent))
    implicitWidth: 180
    implicitHeight: Design.controlHeight
    leftPadding: Design.space12
    rightPadding: Design.space32
    topPadding: Design.space4
    bottomPadding: Design.space4
    font.family: Design.fontFamily
    font.pixelSize: Design.bodySize
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Design.disabledOpacity
    Binding { target: root; property: "enabled"; value: false; when: root.busy; restoreMode: Binding.RestoreBindingOrValue }
    onEnabledChanged: { if (!enabled) popup.close(); }
    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    background: ControlSurface { control: root; selected: root.popup.visible }
    contentItem: UI.Text {
        text: root.displayText
        font: root.font
        color: root.foreground
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    indicator: UI.Text {
        x: root.width - width - Design.space12
        y: (root.height - height) / 2
        text: root.busy ? "◌" : root.popup.visible ? "▴" : "▾"
        color: root.foreground
    }
    delegate: C.ItemDelegate {
        id: option
        required property int index
        required property var modelData
        width: root.popup.availableWidth
        implicitHeight: Design.controlHeight
        padding: Design.space8
        text: root.textAt(index)
        highlighted: root.highlightedIndex === index
        hoverEnabled: true
        background: ControlSurface { control: option; selected: option.highlighted || root.currentIndex === option.index }
        contentItem: UI.Text {
            text: option.text
            color: option.highlighted || root.currentIndex === option.index ? Design.textOnAccent : Design.text
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }
    popup: Popup {
        y: root.height + Design.space4
        width: root.width
        height: Math.min(list.contentHeight, 240) + topPadding + bottomPadding
        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            highlightMoveDuration: 0
            C.ScrollIndicator.vertical: C.ScrollIndicator {}
        }
    }
}
