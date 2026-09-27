import QtQuick
import QtQuick.Controls
import "../config"

Slider {
    id: root
    property real mediaPosition: 0
    property real duration: 0
    property string trackKey: ""
    property string gestureTrack: ""
    property bool dirty: false
    signal seekRequested(real seconds)
    from: 0
    to: Math.max(1, duration)
    stepSize: 1
    implicitHeight: 24
    Accessible.name: "Playback position"
    Component.onCompleted: value = mediaPosition
    onMediaPositionChanged: { if (!pressed) value = mediaPosition; }
    onTrackKeyChanged: { if (!pressed) value = mediaPosition; }
    function commit() {
        seekRequested(Math.max(0, Math.min(duration, value)));
    }
    function cancelSeek() { dirty = false; gestureTrack = ""; }
    onMoved: {
        if (pressed) dirty = true;
        else if (enabled) commit();
    }
    onPressedChanged: {
        if (pressed) { gestureTrack = trackKey; dirty = false; }
        else {
            if (dirty && enabled && gestureTrack === trackKey) commit();
            else value = mediaPosition;
            dirty = false;
        }
    }
    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 4
        radius: 2
        color: Theme.overlay
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: root.enabled ? Theme.iris : Theme.muted
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 12; height: 12; radius: 6
        visible: root.enabled
        color: Theme.text
        border.color: root.activeFocus ? Theme.iris : Theme.highlightHigh
    }
}
