import QtQuick
import QtQuick.Layouts
import "ui" as UI
import "../config"

UI.ColumnLayout {
    id: root
    spacing: Design.space12
    enabled: Theme.ready
    readonly property var modes: ["off", "instant", "animated"]

    UI.FieldLabel { text: "Edge lines" }
    UI.HelperText {
        Layout.fillWidth: true
        text: "Top and bottom on horizontal bars; left and right on vertical bars. Off also hides active-state lines."
        wrapMode: Text.WordWrap
    }
    UI.SegmentedControl {
        objectName: "widget-style-lines"
        Layout.fillWidth: true
        model: ["Off", "Instant", "Animated"]
        currentIndex: root.modes.indexOf(Theme.widgetStyle.lines)
        onSelected: index => Theme.setWidgetStyle("lines", root.modes[index])
    }
    UI.FieldLabel { text: "Hover background" }
    UI.SegmentedControl {
        objectName: "widget-style-background"
        Layout.fillWidth: true
        model: ["Off", "Instant", "Animated"]
        currentIndex: root.modes.indexOf(Theme.widgetStyle.background)
        onSelected: index => Theme.setWidgetStyle("background", root.modes[index])
    }
    UI.GridLayout {
        Layout.fillWidth: true
        columns: width >= 480 ? 2 : 1
        columnSpacing: Design.space24
        rowSpacing: Design.space12
        AppearanceSlider {
            objectName: "widget-style-duration"
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            label: "Animation duration"
            minimum: 100; maximum: 600; stepSize: 20; suffix: " ms"
            enabled: Theme.widgetStyle.lines === "animated" || Theme.widgetStyle.background === "animated"
            value: Theme.widgetStyle.duration
            onValueEdited: value => Theme.setWidgetStyle("duration", value)
            onEditingFinished: Theme.save()
        }
        AppearanceSlider {
            objectName: "widget-style-strength"
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            label: "Background strength"
            minimum: 0; maximum: 30; suffix: "%"
            enabled: Theme.widgetStyle.background !== "off"
            value: Theme.widgetStyle.strength
            onValueEdited: value => Theme.setWidgetStyle("strength", value)
            onEditingFinished: Theme.save()
        }
    }
    UI.Card {
        Layout.fillWidth: true
        implicitHeight: Theme.verticalBar ? 140 : 82
        Item {
            id: sample
            objectName: "widget-style-preview"
            width: Theme.verticalBar ? 64 : 120
            height: Theme.verticalBar ? 110 : 42
            anchors.centerIn: parent
            property bool selected: false
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Widget preview"
            Accessible.checkable: true
            Accessible.checked: selected
            Accessible.onPressAction: selected = !selected
            Keys.onSpacePressed: selected = !selected
            Keys.onReturnPressed: selected = !selected
            BarHoverIndicator {
                anchors.fill: parent
                hovered: sampleMouse.containsMouse
                focused: sample.activeFocus
                active: sample.selected
            }
            UI.Text {
                anchors.centerIn: parent
                text: sample.selected ? "Active" : "Preview"
                role: "body"
            }
            MouseArea {
                id: sampleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sample.selected = !sample.selected
            }
        }
    }
    UI.HelperText {
        Layout.fillWidth: true
        text: "Hover the preview to try the effects. Click to toggle its active state."
        wrapMode: Text.WordWrap
    }
    UI.Button {
        objectName: "widget-style-reset"
        text: "Reset widget styling"
        onClicked: Theme.resetWidgetStyle()
    }
}
