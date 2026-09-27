import QtQuick
import QtQuick.Controls
import "../config"

Slider {
    id: root
    required property real level
    property bool muted: false
    property int maximum: 150
    property bool pendingChange: false
    signal volumeRequested(real value)
    from: 0
    to: maximum
    stepSize: 1
    wheelEnabled: true
    implicitHeight: 32

    // Do not rebind on release: retain the user's value until fresh state arrives.
    Component.onCompleted: value = level
    onLevelChanged: {
        if (!pressed && !pendingChange) value = level;
    }
    function sendValue() {
        pendingChange = false;
        volumeRequested(Math.round(value));
        updateTimer.restart();
    }
    onMoved: {
        pendingChange = true;
        if (!updateTimer.running) sendValue();
    }
    onPressedChanged: {
        if (!pressed && pendingChange) sendValue();
    }
    Timer {
        id: updateTimer
        interval: 60
        onTriggered: { if (root.pendingChange) root.sendValue(); }
    }
    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        radius: 3
        color: Theme.overlay
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: 3
            color: root.muted || !root.enabled ? Theme.muted : Theme.love
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 14
        height: 14
        radius: 7
        color: root.enabled ? Theme.text : Theme.muted
        border.color: root.activeFocus ? Theme.iris : Theme.highlightHigh
    }
}
