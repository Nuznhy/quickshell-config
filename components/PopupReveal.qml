import QtQuick
import "../config"

Item {
    id: root
    required property bool opened
    // Keep the window mapped until its closing animation has finished.
    readonly property bool presented: opened || progress > 0
    property real progress: 0
    onOpenedChanged: {
        revealAnimation.stop();
        revealAnimation.to = opened ? 1 : 0;
        revealAnimation.start();
    }
    function finishClosing() {
        // A compositor dismissal can hide the window before the fade completes.
        // Reset presented now so the next open remaps a fresh native window.
        if (!opened) {
            revealAnimation.stop();
            progress = 0;
        }
    }
    enabled: opened
    opacity: progress
    transform: Translate {
        x: Theme.verticalBar ? (Theme.barPosition === "left" ? -12 : 12) * (1 - root.progress) : 0
        y: Theme.verticalBar ? 0 : (Theme.barPosition === "bottom" ? 12 : -12) * (1 - root.progress)
    }
    // Fade the card and its children as one surface.
    layer.enabled: progress > 0 && progress < 1

    NumberAnimation {
        id: revealAnimation
        target: root
        property: "progress"
        duration: root.opened ? Design.durationNormal : Design.durationFast
        easing.type: root.opened ? Easing.OutCubic : Easing.InCubic
    }
}
