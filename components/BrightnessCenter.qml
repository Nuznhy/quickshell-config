pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

FocusScope {
    id: root
    property bool active: false
    property int maximumHeight: 600
    implicitHeight: Math.min(maximumHeight, content.implicitHeight)
    signal dismissed
    onActiveChanged: {
        Brightness.openPanels += active ? 1 : -1;
        if (active) forceActiveFocus();
    }
    Component.onDestruction: { if (active) Brightness.openPanels--; }
    Keys.onEscapePressed: dismissed()
    component Label: UI.Text {
        color: Design.text
        font.family: Design.fontFamily
        role: "body"
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    UI.ScrollView {
        anchors.fill: parent
        anchors.margins: 0
        contentWidth: availableWidth
        clip: true
        UI.ColumnLayout {
            id: content
            width: parent.width
            spacing: Design.space12
            UI.RowLayout {
                Layout.fillWidth: true
                Label { text: "Brightness"; role: "section"; Layout.fillWidth: true }
                NotificationButton {
                    text: Brightness.loading ? "Detecting…" : "Refresh"
                    enabled: !Brightness.loading && !Brightness.changing
                    onClicked: Brightness.refresh()
                }
            }
            Repeater {
                model: Brightness.displays
                delegate: UI.Card {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: details.implicitHeight + Design.panelPadding * 2

                    UI.ColumnLayout {
                        id: details
                        x: Design.panelPadding; y: Design.panelPadding
                        width: parent.width - Design.panelPadding * 2
                        spacing: Design.space4
                        UI.RowLayout {
                            Layout.fillWidth: true
                            Label { text: card.modelData.name; Layout.fillWidth: true }
                            Label { text: card.modelData.supported ? Math.round(slider.value) + "%" : "Unavailable"; color: Design.textSecondary }
                        }
                        Label { text: card.modelData.connection; color: Design.textSecondary; role: "caption"; Layout.fillWidth: true }
                        AudioSlider {
                            id: slider
                            Layout.fillWidth: true
                            visible: card.modelData.supported
                            enabled: visible
                            maximum: 100
                            level: card.modelData.value
                            Accessible.name: card.modelData.name + " brightness"
                            onVolumeRequested: value => Brightness.setBrightness(card.modelData.deviceId, value)
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: !card.modelData.supported
                            text: card.modelData.error || "Brightness control unavailable."
                            color: Design.textMuted
                        }
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                visible: !Brightness.displays.length
                text: Brightness.loading ? "Finding display controls…" : "No hardware brightness controls found."
                color: Design.textSecondary
            }
            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: Brightness.errorMessage || Brightness.statusError
                color: Design.danger
            }
        }
    }
}
