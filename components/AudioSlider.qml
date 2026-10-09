import QtQuick
import "ui" as UI
import QtQuick.Controls
import "../config"

UI.Slider {
    id: root
    accentColor: muted ? Design.textMuted : Design.danger
    required property real level
    property bool muted: false
    property int maximum: 150
    property bool pendingChange: false
    signal volumeRequested(real value)
    from: 0
    to: maximum
    stepSize: 1
    wheelEnabled: true

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
}
