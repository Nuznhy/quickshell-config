import QtQuick
import qs.config
import qs.config as ConfigScripts

Item {
    id: root
    required property bool hovered
    property bool active: false
    property bool focused: false
    property var styleSettings: Theme.widgetStyle || ConfigScripts.WidgetStyle.defaults()
    readonly property real sideInset: Theme.verticalBar ? Math.max(0, (width - Theme.sideBarWidth + 8) / 2) : 0
    readonly property real targetLines: styleSettings.lines !== "off" && (hovered || active || focused) ? 1 : 0
    readonly property real targetBackground: styleSettings.background !== "off" && hovered ? styleSettings.strength / 100 : 0
    property real lineOpacity: 0
    property real backgroundOpacity: 0
    opacity: enabled ? 1 : Design.disabledOpacity

    function updateLines(animate) {
        lineAnimation.stop();
        if (animate && styleSettings.lines === "animated") {
            lineAnimation.to = targetLines;
            lineAnimation.start();
        } else
            lineOpacity = targetLines;
    }
    function updateBackground(animate) {
        backgroundAnimation.stop();
        if (animate && styleSettings.background === "animated") {
            backgroundAnimation.to = targetBackground;
            backgroundAnimation.start();
        } else
            backgroundOpacity = targetBackground;
    }
    onTargetLinesChanged: updateLines(true)
    onTargetBackgroundChanged: updateBackground(true)
    // Mode changes also settle animations already in flight.
    onStyleSettingsChanged: {
        updateLines(false);
        updateBackground(false);
    }
    Component.onCompleted: {
        updateLines(false);
        updateBackground(false);
    }

    NumberAnimation {
        id: lineAnimation
        target: root
        property: "lineOpacity"
        duration: root.styleSettings.duration
    }
    NumberAnimation {
        id: backgroundAnimation
        target: root
        property: "backgroundOpacity"
        duration: root.styleSettings.duration
    }

    Loader {
        anchors.fill: parent
        readonly property var surface: root
        sourceComponent: UiKit.visual("widgetIndicator")
    }
}
