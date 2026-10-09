import "." as UI
import QtQuick
import QtQuick.Templates as T
import "../../config"

T.Button {
    id: root
    property string variant: "neutral"
    property string size: "default"
    property bool busy: false
    property bool capsule: false
    property color accentColor: Design.accent
    readonly property color foreground: variant === "ghost" && !checked && !highlighted && !(enabled && (hovered || down))
        ? Design.text : Design.readableText(Design.fill(variant, checked || highlighted, hovered, down, enabled, accentColor))
    implicitWidth: Math.max(implicitContentWidth + leftPadding + rightPadding, implicitHeight)
    implicitHeight: Math.max(size === "compact" ? Design.compactHeight : Design.controlHeight, implicitContentHeight + topPadding + bottomPadding)
    leftPadding: Design.space12
    rightPadding: Design.space12
    topPadding: Design.space4
    bottomPadding: Design.space4
    font.family: Design.fontFamily
    font.pixelSize: Design.labelSize
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Design.disabledOpacity
    // Restore any caller's enabled binding after an asynchronous operation.
    Binding { target: root; property: "enabled"; value: false; when: root.busy; restoreMode: Binding.RestoreBindingOrValue }
    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    Accessible.name: text
    Accessible.description: busy ? "In progress" : ""
    UI.Icon {
        anchors.right: parent.right
        anchors.rightMargin: Design.space2
        anchors.verticalCenter: parent.verticalCenter
        text: "◌"
        size: Design.space8
        color: root.foreground
        visible: root.busy
        RotationAnimator on rotation { from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: root.busy && root.visible }
    }
    background: ControlSurface {
        control: root
        variant: root.variant
        selected: root.checked || root.highlighted
        accentColor: root.accentColor
        capsule: root.capsule
    }
    contentItem: UI.Text {
        text: root.text
        font: root.font
        lineHeight: 1
        color: root.foreground
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
