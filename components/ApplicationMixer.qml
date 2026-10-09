pragma ComponentBehavior: Bound
import QtQuick
import "ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../config"
import "../services"

UI.ColumnLayout {
    id: root
    spacing: Design.space8

    function applicationIcon(iconName, desktopId, binaryName, appName) {
        if (iconName) {
            const icon = Quickshell.iconPath(iconName, true);
            if (icon) return icon;
        }
        for (const name of [desktopId, binaryName, appName]) {
            if (!name) continue;
            const entry = DesktopEntries.heuristicLookup(name);
            const icon = Quickshell.iconPath(entry?.icon || name.toLowerCase(), true);
            if (icon) return icon;
        }
        return "";
    }

    UI.Text {
        text: "APPLICATIONS"
        color: Design.textSecondary
        font.family: Design.fontFamily
        role: "label"
        font.letterSpacing: 1
    }

    UI.Text {
        Layout.fillWidth: true
        visible: Audio.streams.count === 0
        text: "No applications playing audio"
        color: Design.textSecondary
        font.family: Design.fontFamily
        role: "body"
        wrapMode: Text.WordWrap
    }

    UI.ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(rows.implicitHeight, 230)
        visible: Audio.streams.count > 0
        contentWidth: availableWidth
        clip: true

        UI.ColumnLayout {
            id: rows
            width: parent.width
            spacing: Design.space8

            Repeater {
                model: Audio.streams
                Rectangle {
                    id: streamRow
                    required property int streamId
                    required property string appName
                    required property string iconName
                    required property string desktopId
                    required property string binaryName
                    required property string mediaName
                    required property int volume
                    required property bool muted
                    required property bool writable
                    Layout.fillWidth: true
                    implicitHeight: details.implicitHeight + Design.panelPadding * 2
                    radius: Design.radiusControl
                    color: Design.surface

                    UI.ColumnLayout {
                        id: details
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Design.panelPadding
                        spacing: Design.space2

                        UI.RowLayout {
                            Layout.fillWidth: true
                            UI.Text {
                                Layout.fillWidth: true
                                text: streamRow.appName
                                elide: Text.ElideRight
                                color: Design.text
                                font.family: Design.fontFamily
                                role: "body"
                                font.bold: true
                            }
                            UI.Button {
                                highlighted: streamRow.muted
                                id: muteButton
                                text: streamRow.muted ? "Unmute" : "Mute"
                                implicitHeight: Design.compactHeight
                                implicitWidth: 64
                                onClicked: Audio.setStreamMuted(streamRow.streamId, !streamRow.muted)

                            }
                        }

                        UI.Text {
                            Layout.fillWidth: true
                            visible: streamRow.mediaName !== "" && streamRow.mediaName !== streamRow.appName
                            text: streamRow.mediaName
                            elide: Text.ElideRight
                            color: Design.textSecondary
                            font.family: Design.fontFamily
                            role: "caption"
                        }

                        UI.RowLayout {
                            Layout.fillWidth: true
                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignVCenter

                                IconImage {
                                    id: applicationIcon
                                    anchors.fill: parent
                                    source: root.applicationIcon(streamRow.iconName, streamRow.desktopId, streamRow.binaryName, streamRow.appName)
                                    visible: status === Image.Ready
                                }
                                UI.Text {
                                    anchors.centerIn: parent
                                    visible: applicationIcon.status !== Image.Ready
                                    text: "󰕾"
                                    color: Design.textSecondary
                                    font.family: Design.fontFamily
                                    font.pixelSize: Design.iconLarge
                                }
                            }
                            AudioSlider {
                                id: slider
                                Layout.fillWidth: true
                                level: streamRow.volume
                                muted: streamRow.muted
                                enabled: streamRow.writable
                                Accessible.name: streamRow.appName + " volume"
                                onVolumeRequested: value => Audio.setStreamVolume(streamRow.streamId, value)
                            }
                            UI.Text {
                                Layout.preferredWidth: 40
                                text: streamRow.writable ? Math.round(slider.value) + "%" : "N/A"
                                color: Design.textSecondary
                                font.family: Design.fontFamily
                                role: "label"
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }
    }
}
