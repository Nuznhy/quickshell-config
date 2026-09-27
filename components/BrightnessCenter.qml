pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../services"

FocusScope {
    id: root
    property bool active: false
    property int maximumHeight: 600
    implicitHeight: Math.min(maximumHeight, content.implicitHeight + 24)
    signal dismissed
    onActiveChanged: {
        Brightness.openPanels += active ? 1 : -1;
        if (active) forceActiveFocus();
    }
    Component.onDestruction: { if (active) Brightness.openPanels--; }
    Keys.onEscapePressed: dismissed()
    component Label: Text {
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
    }
    ScrollView {
        anchors.fill: parent
        anchors.margins: 12
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: content
            width: parent.width
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Label { text: "Brightness"; font.pixelSize: 16; Layout.fillWidth: true }
                NotificationButton {
                    text: Brightness.loading ? "Detecting…" : "Refresh"
                    enabled: !Brightness.loading && !Brightness.changing
                    onClicked: Brightness.refresh()
                }
            }
            Repeater {
                model: Brightness.displays
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: details.implicitHeight + 20
                    radius: 10
                    color: Theme.surface
                    ColumnLayout {
                        id: details
                        x: 10; y: 10
                        width: parent.width - 20
                        spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: card.modelData.name; Layout.fillWidth: true }
                            Label { text: card.modelData.supported ? Math.round(slider.value) + "%" : "Unavailable"; color: Theme.subtle }
                        }
                        Label { text: card.modelData.connection; color: Theme.subtle; font.pixelSize: 10; Layout.fillWidth: true }
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
                            color: Theme.muted
                        }
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                visible: !Brightness.displays.length
                text: Brightness.loading ? "Finding display controls…" : "No hardware brightness controls found."
                color: Theme.subtle
            }
            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: Brightness.errorMessage || Brightness.statusError
                color: Theme.love
            }
        }
    }
}
