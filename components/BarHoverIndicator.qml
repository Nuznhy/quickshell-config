import QtQuick
import "../config"
import "../config/WidgetStyle.js" as WidgetStyle

Item {
    id: root
    required property bool hovered
    property bool active: false
    property bool focused: false
    property var styleSettings: Theme.widgetStyle || WidgetStyle.defaults()
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
        } else lineOpacity = targetLines;
    }
    function updateBackground(animate) {
        backgroundAnimation.stop();
        if (animate && styleSettings.background === "animated") {
            backgroundAnimation.to = targetBackground;
            backgroundAnimation.start();
        } else backgroundOpacity = targetBackground;
    }
    onTargetLinesChanged: updateLines(true)
    onTargetBackgroundChanged: updateBackground(true)
    // Mode changes also settle animations already in flight.
    onStyleSettingsChanged: { updateLines(false); updateBackground(false); }
    Component.onCompleted: { updateLines(false); updateBackground(false); }

    NumberAnimation { id: lineAnimation; target: root; property: "lineOpacity"; duration: root.styleSettings.duration }
    NumberAnimation { id: backgroundAnimation; target: root; property: "backgroundOpacity"; duration: root.styleSettings.duration }

    Rectangle {
        objectName: "widget-hover-background"
        anchors.fill: parent
        radius: Math.min(Design.radiusControl, width / 2, height / 2)
        color: Design.accent
        opacity: root.backgroundOpacity
    }
    Item {
        anchors.fill: parent
        opacity: root.lineOpacity
        Rectangle {
            objectName: "widget-leading-line"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: root.sideInset
            width: Theme.verticalBar ? 2 : parent.width
            height: Theme.verticalBar ? parent.height : 2
            color: root.hovered || root.focused ? Design.accent : Design.danger
        }
        Rectangle {
            objectName: "widget-trailing-line"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: root.sideInset
            width: Theme.verticalBar ? 2 : parent.width
            height: Theme.verticalBar ? parent.height : 2
            color: root.hovered || root.focused ? Design.accent : Design.danger
        }
    }
    Rectangle {
        objectName: "widget-focus-outline"
        anchors.fill: parent
        anchors.margins: Design.focusWidth / 2
        radius: Design.radiusControl
        color: "transparent"
        border.width: Design.focusWidth
        border.color: Design.accent
        visible: root.focused
    }
}
