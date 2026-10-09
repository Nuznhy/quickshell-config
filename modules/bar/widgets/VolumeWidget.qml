pragma ComponentBehavior: Bound
import QtQuick
import "../../../components/ui" as UI
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../config"
import "../../../services"
import "../../../components"
import "../../../components/PopupPlacement.js" as PopupPlacement

Item {
    id: volumeWidget
    implicitWidth: volumeText.implicitWidth
    implicitHeight: Theme.verticalBar ? Math.max(Settings.barHeight, volumeText.implicitHeight + 8) : Settings.barHeight
    property bool popupOpen: false
    onPopupOpenChanged: {
        outputDropdown.expanded = false;
        microphoneDropdown.expanded = false;
    }

    Connections {
        target: volumeWidget.QsWindow.window
        function onCloseAllPopups() { volumeWidget.popupOpen = false; }
    }

    HyprlandFocusGrab {
        windows: [popup]
        active: volumeWidget.popupOpen && popup.visible
        onCleared: volumeWidget.popupOpen = false
    }

    BarHoverIndicator {
        anchors.fill: parent
        hovered: mouseArea.containsMouse
        active: volumeWidget.popupOpen
    }

    UI.Text {
        role: "bar"
        id: volumeText
        anchors.centerIn: parent
        text: (Audio.volumeMuted ? "󰖁" : "󰕾") + (Theme.verticalBar ? "\n" : " ") + Audio.volumeLevel
        horizontalAlignment: Text.AlignHCenter
        color: Audio.volumeMuted ? Design.textMuted : Design.text
        font.pixelSize: Theme.fontSize
        font.family: Theme.barFontFamily
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => Audio.adjustVolume(wheel.angleDelta.y > 0 ? "+5%" : "-5%")
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                volumeWidget.popupOpen = false;
                Audio.openControl();
                return;
            }
            if (mouse.button === Qt.RightButton) {
                Audio.toggleMute();
                return;
            }
            const shouldOpen = !volumeWidget.popupOpen;
            volumeWidget.QsWindow.window?.closeAllPopups();
            volumeWidget.popupOpen = shouldOpen;
            if (shouldOpen) Audio.refresh();
        }
    }

    PopupWindow {
        id: popup
        anchor.window: volumeWidget.QsWindow.window
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
        anchor.onAnchoring: {
            const window = volumeWidget.QsWindow.window;
            if (window && window.contentItem) {
                const point = volumeWidget.mapToItem(window.contentItem, 0, 0);
                const placement = PopupPlacement.position(Theme.barPosition, point.x, point.y,
                    volumeWidget.width, volumeWidget.height, window.width, window.height,
                    popup.width, popup.height, "center", 0, false);
                popup.anchor.rect = Qt.rect(placement.x, placement.y, 1, 1);
            }
        }
        implicitWidth: 350
        implicitHeight: content.implicitHeight + Settings.popupPadding * 2
        visible: popupReveal.presented
        onVisibleChanged: {
            if (!visible) {
                volumeWidget.popupOpen = false;
                popupReveal.finishClosing();
            }
        }
        color: "transparent"

        PopupReveal {
            id: popupReveal
            anchors.fill: parent
            opened: volumeWidget.popupOpen

            UI.MenuSurface {
                anchors.fill: parent

                focus: true
                Keys.onEscapePressed: volumeWidget.popupOpen = false

                UI.ColumnLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Settings.popupPadding
                    spacing: Design.space8

                    AudioDeviceDropdown {
                        id: outputDropdown
                        Layout.fillWidth: true
                        title: "OUTPUT"
                        devices: Audio.outputs
                        selectedName: Audio.defaultOutput
                        busy: Audio.switching
                        onSelected: name => Audio.selectOutput(name)
                        onExpandedChanged: { if (expanded) microphoneDropdown.expanded = false; }
                    }

                    AudioLevelControl {
                        Layout.fillWidth: true
                        level: Audio.volumeLevel
                        muted: Audio.volumeMuted
                        enabled: Audio.available
                        busy: Audio.switching
                        onVolumeRequested: value => Audio.setOutputVolume(value)
                        onMuteRequested: Audio.toggleMute()
                    }

                    AudioDeviceDropdown {
                        id: microphoneDropdown
                        Layout.fillWidth: true
                        title: "MICROPHONE"
                        devices: Audio.microphones
                        selectedName: Audio.defaultMicrophone
                        busy: Audio.switchingMicrophone
                        onSelected: name => Audio.selectMicrophone(name)
                        onExpandedChanged: { if (expanded) outputDropdown.expanded = false; }
                    }

                    AudioLevelControl {
                        Layout.fillWidth: true
                        microphone: true
                        level: Audio.microphoneVolume
                        muted: Audio.microphoneMuted
                        enabled: Audio.microphoneAvailable
                        busy: Audio.switchingMicrophone
                        onVolumeRequested: value => Audio.setMicrophoneVolume(value)
                        onMuteRequested: Audio.toggleMicrophoneMute()
                    }

                    ApplicationMixer {
                        Layout.fillWidth: true
                    }

                    UI.Text {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: Audio.errorMessage
                        color: Audio.errorMessage ? Design.danger : Design.textSecondary
                        font.family: Design.fontFamily
                        role: "caption"
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

    }

}
