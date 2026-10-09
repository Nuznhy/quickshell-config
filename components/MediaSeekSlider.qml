import QtQuick
import "ui" as UI
import QtQuick.Controls
import "../config"

UI.Slider {
    id: root
    showHandle: enabled
    property real mediaPosition: 0
    property real duration: 0
    property string trackKey: ""
    property string gestureTrack: ""
    property bool dirty: false
    signal seekRequested(real seconds)
    from: 0
    to: Math.max(1, duration)
    stepSize: 1
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
}
