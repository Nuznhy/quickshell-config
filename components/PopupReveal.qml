import QtQuick

Item {
    id: root
    required property bool opened
    // Keep the window mapped until its closing animation has finished.
    readonly property bool presented: opened || progress > 0
    property real progress: opened ? 1 : 0
    enabled: opened
    opacity: progress
    transform: Translate { y: -12 * (1 - root.progress) }
    // Fade the card and its children as one surface.
    layer.enabled: progress > 0 && progress < 1

    Behavior on progress {
        NumberAnimation {
            duration: root.opened ? 180 : 130
            easing.type: root.opened ? Easing.OutCubic : Easing.InCubic
        }
    }
}
