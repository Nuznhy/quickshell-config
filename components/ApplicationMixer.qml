pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../config"
import "../services"

ColumnLayout {
    id: root
    spacing: 8

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

    Text {
        text: "APPLICATIONS"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.letterSpacing: 1
    }

    Text {
        Layout.fillWidth: true
        visible: Audio.streams.count === 0
        text: "No applications playing audio"
        color: Theme.subtle
        font.family: Theme.fontFamily
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(rows.implicitHeight, 230)
        visible: Audio.streams.count > 0
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            id: rows
            width: parent.width
            spacing: 8

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
                    implicitHeight: details.implicitHeight + 20
                    radius: 8
                    color: Theme.surface

                    ColumnLayout {
                        id: details
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: streamRow.appName
                                elide: Text.ElideRight
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Button {
                                id: muteButton
                                text: streamRow.muted ? "Unmute" : "Mute"
                                implicitHeight: 28
                                implicitWidth: 64
                                hoverEnabled: true
                                onClicked: Audio.setStreamMuted(streamRow.streamId, !streamRow.muted)
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                contentItem: Text {
                                    text: muteButton.text
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 6
                                    color: muteButton.hovered ? Theme.highlightMed : Theme.overlay
                                    border.color: streamRow.muted || muteButton.activeFocus ? Theme.iris : Theme.highlightMed
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: streamRow.mediaName !== "" && streamRow.mediaName !== streamRow.appName
                            text: streamRow.mediaName
                            elide: Text.ElideRight
                            color: Theme.subtle
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        RowLayout {
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
                                Text {
                                    anchors.centerIn: parent
                                    visible: applicationIcon.status !== Image.Ready
                                    text: "󰕾"
                                    color: Theme.subtle
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
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
                            Text {
                                Layout.preferredWidth: 40
                                text: streamRow.writable ? Math.round(slider.value) + "%" : "N/A"
                                color: Theme.subtle
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }
    }
}
